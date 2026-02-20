import Foundation

/// Core workflow engine that evaluates triggers, checks conditions, and executes blocks.
actor WorkflowEngine {
    private let workflowStorageService: WorkflowStorageService
    private let homeKitManager: HomeKitManager
    private let loggingService: LoggingService
    private let executionLogService: WorkflowExecutionLogService
    private let storage: StorageService
    private let conditionEvaluator: ConditionEvaluator
    private var evaluators: [TriggerEvaluator] = []

    private var runningTasks: [UUID: Task<Void, Never>] = [:]
    private let maxConcurrentExecutions = 10
    private let blockTimeout: TimeInterval = 30

    /// Waiters for `waitForState` blocks — keyed by device+characteristic.
    private var stateWaiters: [String: [StateWaiter]] = [:]

    init(
        storageService: WorkflowStorageService,
        homeKitManager: HomeKitManager,
        loggingService: LoggingService,
        executionLogService: WorkflowExecutionLogService,
        storage: StorageService
    ) {
        workflowStorageService = storageService
        self.homeKitManager = homeKitManager
        self.loggingService = loggingService
        self.executionLogService = executionLogService
        self.storage = storage
        conditionEvaluator = ConditionEvaluator(homeKitManager: homeKitManager)
    }

    func registerEvaluator(_ evaluator: TriggerEvaluator) {
        evaluators.append(evaluator)
    }

    private nonisolated func updateBlockResult(_ updated: BlockResult, in results: inout [BlockResult]) -> Bool {
        for i in 0 ..< results.count {
            if results[i].id == updated.id {
                results[i] = updated
                return true
            }
            if var nested = results[i].nestedResults {
                if updateBlockResult(updated, in: &nested) {
                    results[i].nestedResults = nested
                    return true
                }
            }
        }
        return false
    }

    // MARK: - State Change Processing

    /// Main entry — called by HomeKitManager on ALL state changes.
    func processStateChange(_ change: StateChange) async {
        // Notify any waitForState waiters first
        notifyStateWaiters(change)

        let workflows = await workflowStorageService.getEnabledWorkflows()
        let context = TriggerContext.stateChange(change)

        for workflow in workflows {
            guard runningTasks.count < maxConcurrentExecutions else { break }

            // Check if ANY trigger matches
            let triggered = await checkTriggers(workflow.triggers, context: context)
            guard triggered else { continue }

            // Already running?
            if let existingTask = runningTasks[workflow.id] {
                switch workflow.retriggerPolicy {
                case .ignoreNew:
                    continue
                case .cancelAndRestart:
                    existingTask.cancel()
                    runningTasks.removeValue(forKey: workflow.id)
                }
            }

            // Dispatch execution
            let workflowId = workflow.id
            let task = Task { [weak self] in
                await self?.executeWorkflow(workflow, change: change)
                await self?.removeRunning(workflowId)
            }
            runningTasks[workflowId] = task
        }
    }

    /// Manual trigger for testing.
    func triggerWorkflow(id: UUID) async -> WorkflowExecutionLog? {
        guard let workflow = await workflowStorageService.getWorkflow(id: id) else { return nil }

        // Handle retrigger policy for manual trigger too
        if let existingTask = runningTasks[id] {
            switch workflow.retriggerPolicy {
            case .ignoreNew:
                return nil
            case .cancelAndRestart:
                existingTask.cancel()
                runningTasks.removeValue(forKey: id)
            }
        }

        let task = Task { [weak self] () -> WorkflowExecutionLog in
            let result = await self?.executeWorkflow(workflow, change: nil) ?? WorkflowExecutionLog(workflowId: id, workflowName: workflow.name, triggerEvent: nil)
            await self?.removeRunning(id)
            return result
        }
        runningTasks[id] = Task { _ = await task.value }
        return await task.value
    }

    /// Trigger a workflow from a schedule or webhook with a custom trigger event.
    func triggerWorkflow(id: UUID, triggerEvent: TriggerEvent) async -> WorkflowExecutionLog? {
        guard let workflow = await workflowStorageService.getWorkflow(id: id) else { return nil }
        guard workflow.isEnabled else { return nil }

        if let existingTask = runningTasks[id] {
            switch workflow.retriggerPolicy {
            case .ignoreNew:
                return nil
            case .cancelAndRestart:
                existingTask.cancel()
                runningTasks.removeValue(forKey: id)
            }
        }

        let task = Task { [weak self] () -> WorkflowExecutionLog in
            let result = await self?.executeWorkflow(workflow, change: nil, triggerEvent: triggerEvent) ?? WorkflowExecutionLog(workflowId: id, workflowName: workflow.name, triggerEvent: triggerEvent)
            await self?.removeRunning(id)
            return result
        }
        runningTasks[id] = Task { _ = await task.value }
        return await task.value
    }

    private func removeRunning(_ id: UUID) {
        runningTasks.removeValue(forKey: id)
    }

    // MARK: - Trigger Evaluation

    private func checkTriggers(_ triggers: [WorkflowTrigger], context: TriggerContext) async -> Bool {
        for trigger in triggers {
            for evaluator in evaluators {
                if evaluator.canEvaluate(trigger) {
                    if await evaluator.evaluate(trigger, context: context) {
                        return true
                    }
                }
            }
        }
        return false
    }

    // MARK: - Workflow Execution

    @discardableResult
    private func executeWorkflow(_ workflow: Workflow, change: StateChange?, triggerEvent: TriggerEvent? = nil) async -> WorkflowExecutionLog {
        let event = triggerEvent ?? change.map { c -> TriggerEvent in
            let charName = CharacteristicTypes.displayName(for: c.characteristicType)
            let desc = "\(c.deviceName) \(charName) changed"
            return TriggerEvent(
                deviceId: c.deviceId,
                deviceName: c.deviceName,
                serviceId: c.serviceId,
                characteristicType: c.characteristicType,
                oldValue: c.oldValue.map { AnyCodable($0) },
                newValue: c.newValue.map { AnyCodable($0) },
                triggerDescription: desc
            )
        }
        var execLog = WorkflowExecutionLog(
            workflowId: workflow.id,
            workflowName: workflow.name,
            triggerEvent: event
        )

        // Log immediately as running so it appears in the UI
        await executionLogService.log(execLog)

        // Evaluate guard conditions
        if let conditions = workflow.conditions, !conditions.isEmpty {
            let (allPassed, condResults) = await conditionEvaluator.evaluateAll(conditions)
            execLog.conditionResults = condResults
            await executionLogService.update(execLog)

            if !allPassed {
                execLog.status = .conditionNotMet
                execLog.completedAt = Date()
                await finalizeExecution(execLog, workflow: workflow, succeeded: false)
                return execLog
            }
        }

        // Create a reference box so the @Sendable closure can mutate the log
        class LogBox {
            var execLog: WorkflowExecutionLog
            init(_ log: WorkflowExecutionLog) {
                execLog = log
            }
        }
        let logBox = LogBox(execLog)

        // Execute blocks in order, updating log after each step
        let context = ExecutionContext(workflow: workflow)
        var failed = false

        let onUpdate: @Sendable (BlockResult) async -> Void = { [weak self] updated in
            guard let self = self else { return }
            // Try to update an existing block in the results tree
            if !self.updateBlockResult(updated, in: &logBox.execLog.blockResults) {
                // Block not yet in the array — append it so the UI can show it immediately
                logBox.execLog.blockResults.append(updated)
            }
            await self.executionLogService.update(logBox.execLog)
        }

        for (index, block) in workflow.blocks.enumerated() {
            if Task.isCancelled {
                logBox.execLog.status = .cancelled
                logBox.execLog.completedAt = Date()
                await finalizeExecution(logBox.execLog, workflow: workflow, succeeded: false)
                return logBox.execLog
            }

            let result = await executeBlock(block, index: index, context: context, onUpdate: onUpdate)

            // Note: executeBlock already calls onUpdate for progress and completion,
            // but we append it here if it wasn't already in the top-level list.
            if !logBox.execLog.blockResults.contains(where: { $0.id == result.id }) {
                logBox.execLog.blockResults.append(result)
                await executionLogService.update(logBox.execLog)
            }

            if result.status == .failure {
                failed = true
                if !workflow.continueOnError {
                    break
                }
            }
        }

        logBox.execLog.status = failed ? .failure : .success
        logBox.execLog.completedAt = Date()
        logBox.execLog.errorMessage = failed ? logBox.execLog.blockResults.first(where: { $0.status == .failure })?.errorMessage : nil

        await finalizeExecution(logBox.execLog, workflow: workflow, succeeded: !failed)
        return logBox.execLog
    }

    private func finalizeExecution(_ execLog: WorkflowExecutionLog, workflow: Workflow, succeeded: Bool) async {
        // Update the existing running log entry with the final result
        await executionLogService.update(execLog)

        // Update workflow metadata
        await workflowStorageService.updateMetadata(
            id: workflow.id,
            lastTriggered: execLog.triggeredAt,
            incrementExecutions: true,
            resetFailures: succeeded
        )

        if !succeeded, execLog.status != .conditionNotMet, execLog.status != .cancelled {
            await workflowStorageService.incrementFailures(id: workflow.id)
        }

        // Build rich log entry for main logging service
        let category: LogCategory = (succeeded || execLog.status == .cancelled) ? .workflowExecution : .workflowError
        let durationMs: Int = {
            guard let completed = execLog.completedAt else { return 0 }
            return Int(completed.timeIntervalSince(execLog.triggeredAt) * 1000)
        }()

        // requestBody: trigger description
        let requestBody: String = {
            if let trigger = execLog.triggerEvent, let desc = trigger.triggerDescription {
                return desc
            } else if let trigger = execLog.triggerEvent, let deviceName = trigger.deviceName {
                let charName = trigger.characteristicType.map { CharacteristicTypes.displayName(for: $0) } ?? ""
                let oldStr = trigger.oldValue.map { stringFromAny($0.value) } ?? "?"
                let newStr = trigger.newValue.map { stringFromAny($0.value) } ?? "?"
                return "\(deviceName) \(charName): \(oldStr) → \(newStr)"
            } else {
                return "Manual trigger"
            }
        }()

        // responseBody: sequential summary of what happened
        let responseBody: String = {
            var lines: [String] = []
            func summarizeResults(_ results: [BlockResult], depth: Int = 0) {
                let indent = String(repeating: "  ", count: depth)
                for r in results {
                    let icon = r.status == .success ? "✓" : (r.status == .failure ? "✗" : "–")
                    let name = r.blockName ?? r.blockType
                    if let detail = r.detail, !detail.isEmpty {
                        lines.append("\(indent)\(icon) \(name): \(detail)")
                    } else {
                        lines.append("\(indent)\(icon) \(name)")
                    }
                    if let nested = r.nestedResults, !nested.isEmpty {
                        summarizeResults(nested, depth: depth + 1)
                    }
                }
            }
            summarizeResults(execLog.blockResults)
            if lines.isEmpty {
                lines.append("\(execLog.status.rawValue) in \(durationMs)ms")
            }
            return lines.joined(separator: "\n")
        }()

        // Detailed logs (gated by setting)
        var detailedRequest: String?
        var detailedResponse: String?
        if storage.readDetailedLogsEnabled() {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            // Detailed request: trigger event + condition results
            var detailedReqDict: [String: AnyCodable] = [:]
            if let trigger = execLog.triggerEvent {
                var triggerDict: [String: AnyCodable] = [
                    "oldValue": trigger.oldValue ?? AnyCodable("nil"),
                    "newValue": trigger.newValue ?? AnyCodable("nil"),
                ]
                if let deviceId = trigger.deviceId { triggerDict["deviceId"] = AnyCodable(deviceId) }
                if let deviceName = trigger.deviceName { triggerDict["deviceName"] = AnyCodable(deviceName) }
                if let characteristicType = trigger.characteristicType { triggerDict["characteristicType"] = AnyCodable(characteristicType) }
                if let triggerDescription = trigger.triggerDescription { triggerDict["triggerDescription"] = AnyCodable(triggerDescription) }
                detailedReqDict["trigger"] = AnyCodable(triggerDict)
            }
            if let condResults = execLog.conditionResults {
                detailedReqDict["conditions"] = AnyCodable(condResults.map { AnyCodable(["description": AnyCodable($0.conditionDescription), "passed": AnyCodable($0.passed)] as [String: AnyCodable]) })
            }
            if let data = try? encoder.encode(detailedReqDict), let json = String(data: data, encoding: .utf8) {
                detailedRequest = json
            }

            // Detailed response: full block results tree
            if let data = try? encoder.encode(execLog.blockResults), let json = String(data: data, encoding: .utf8) {
                detailedResponse = json
            }
        }

        let logEntry = StateChangeLog(
            id: UUID(),
            timestamp: Date(),
            deviceId: workflow.id.uuidString,
            deviceName: workflow.name,
            serviceName: execLog.triggerEvent?.deviceName,
            characteristicType: "workflow",
            oldValue: nil,
            newValue: AnyCodable(execLog.status.rawValue),
            category: category,
            errorDetails: execLog.errorMessage,
            requestBody: requestBody,
            responseBody: responseBody,
            detailedRequestBody: detailedRequest,
            detailedResponseBody: detailedResponse
        )
        await loggingService.logEntry(logEntry)
    }

    // MARK: - Block Execution (Recursive)

    private func executeBlock(_ block: WorkflowBlock, index: Int, context: ExecutionContext, onUpdate: @escaping (BlockResult) async -> Void) async -> BlockResult {
        switch block {
        case let .action(action):
            return await executeAction(action, index: index, context: context, onUpdate: onUpdate)
        case let .flowControl(flowControl):
            return await executeFlowControl(flowControl, index: index, context: context, onUpdate: onUpdate)
        }
    }

    // MARK: - Action Execution

    private func executeAction(_ action: WorkflowAction, index: Int, context _: ExecutionContext, onUpdate: @escaping (BlockResult) async -> Void) async -> BlockResult {
        let actionName: String? = {
            switch action {
            case let .controlDevice(a): return a.name
            case let .webhook(a): return a.name
            case let .log(a): return a.name
            }
        }()
        var result = BlockResult(blockIndex: index, blockKind: "action", blockType: action.displayType, blockName: actionName)

        // Notify that we are starting
        await onUpdate(result)

        do {
            try await withTimeout(seconds: blockTimeout) {
                switch action {
                case let .controlDevice(a):
                    try await self.executeControlDevice(a)
                    let deviceName = self.resolveDeviceName(a.deviceId)
                    let charName = CharacteristicTypes.displayName(for: a.characteristicType)
                    result.detail = "Set \(charName) to \(a.value.value) on \(deviceName)"
                case let .webhook(a):
                    try await self.executeWebhook(a)
                    result.detail = "\(a.method) \(a.url)"
                case let .log(a):
                    AppLogger.workflow.info("Workflow log: \(a.message)")
                    result.detail = a.message
                }
            }
            result.status = .success
            result.completedAt = Date()
        } catch {
            result.status = .failure
            result.errorMessage = error.localizedDescription
            result.completedAt = Date()
        }

        await onUpdate(result)
        return result
    }

    private func executeControlDevice(_ action: ControlDeviceAction) async throws {
        let resolvedType = CharacteristicTypes.characteristicType(forName: action.characteristicType) ?? action.characteristicType
        try await homeKitManager.updateDevice(
            id: action.deviceId,
            characteristicType: resolvedType,
            value: action.value.value,
            serviceId: action.serviceId
        )
    }

    private func executeWebhook(_ action: WebhookActionConfig) async throws {
        guard let url = URL(string: action.url) else {
            throw WorkflowEngineError.invalidURL(action.url)
        }

        var request = URLRequest(url: url)
        request.httpMethod = action.method
        request.timeoutInterval = blockTimeout

        if let headers = action.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        if let body = action.body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }

        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200 ... 299).contains(httpResponse.statusCode) {
            throw WorkflowEngineError.webhookFailed(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Flow Control Execution

    private func executeFlowControl(_ flowControl: FlowControlBlock, index: Int, context: ExecutionContext, onUpdate: @escaping (BlockResult) async -> Void) async -> BlockResult {
        let fcName: String? = {
            switch flowControl {
            case let .delay(b): return b.name
            case let .waitForState(b): return b.name
            case let .conditional(b): return b.name
            case let .repeat(b): return b.name
            case let .repeatWhile(b): return b.name
            case let .group(b): return b.name
            }
        }()
        var result = BlockResult(blockIndex: index, blockKind: "flowControl", blockType: flowControl.displayType, blockName: fcName)

        // Notify that we are starting
        await onUpdate(result)

        do {
            switch flowControl {
            case let .delay(block):
                result.detail = "Waiting \(block.seconds)s..."
                await onUpdate(result)

                try await Task.sleep(nanoseconds: UInt64(block.seconds * 1_000_000_000))
                result.detail = "Delayed \(block.seconds)s"
                result.status = .success

            case let .waitForState(block):
                let waitDeviceName = resolveDeviceName(block.deviceId)
                let waitCharName = CharacteristicTypes.displayName(for: block.characteristicType)
                result.detail = "Waiting for \(waitDeviceName) \(waitCharName)..."
                await onUpdate(result)

                let matched = try await waitForState(block) { [weak self] elapsedSeconds in
                    // Update parent with elapsed time while waiting
                    result.detail = "Waiting for \(waitDeviceName) \(waitCharName)... (\(String(format: "%.1f", elapsedSeconds))s)"
                    await onUpdate(result)
                }
                result.detail = matched
                    ? "Waited for \(waitDeviceName) \(waitCharName) — condition met"
                    : "Waited for \(waitDeviceName) \(waitCharName) — timed out after \(block.timeoutSeconds)s"
                result.status = matched ? .success : .failure
                if !matched {
                    result.errorMessage = "Timed out after \(block.timeoutSeconds)s"
                }

            case let .conditional(block):
                let condResult = await conditionEvaluator.evaluate(block.condition)
                result.detail = condResult.passed ? "Condition met — running Then blocks" : "Condition not met — running Else blocks"
                await onUpdate(result)

                let blocksToRun = condResult.passed ? block.thenBlocks : (block.elseBlocks ?? [])
                var nested: [BlockResult] = []
                var nestedFailed = false

                let nestedUpdate: (BlockResult) async -> Void = { [weak self] updated in
                    if let index = nested.firstIndex(where: { $0.id == updated.id }) {
                        nested[index] = updated
                    } else {
                        nested.append(updated)
                    }
                    result.nestedResults = nested
                    await onUpdate(result)
                }

                for (i, b) in blocksToRun.enumerated() {
                    let r = await executeBlock(b, index: i, context: context, onUpdate: nestedUpdate)
                    if !nested.contains(where: { $0.id == r.id }) {
                        nested.append(r)
                    }
                    if r.status == .failure {
                        nestedFailed = true
                        if !context.workflow.continueOnError { break }
                    }
                }
                result.nestedResults = nested
                result.status = nestedFailed ? .failure : .success

            case let .repeat(block):
                var nested: [BlockResult] = []
                var repeatFailed = false

                let nestedUpdate: (BlockResult) async -> Void = { [weak self] updated in
                    if let index = nested.firstIndex(where: { $0.id == updated.id }) {
                        nested[index] = updated
                    } else {
                        nested.append(updated)
                    }
                    result.nestedResults = nested
                    await onUpdate(result)
                }

                for iteration in 0 ..< block.count {
                    result.detail = "Iteration \(iteration + 1)/\(block.count)"
                    await onUpdate(result)

                    for (i, b) in block.blocks.enumerated() {
                        let r = await executeBlock(b, index: i, context: context, onUpdate: nestedUpdate)
                        if !nested.contains(where: { $0.id == r.id }) {
                            nested.append(r)
                        }
                        if r.status == .failure {
                            repeatFailed = true
                            if !context.workflow.continueOnError { break }
                        }
                    }
                    if repeatFailed && !context.workflow.continueOnError { break }
                    if let delay = block.delayBetweenSeconds, iteration < block.count - 1 {
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                }
                result.detail = "Repeated \(block.count) times"
                result.nestedResults = nested
                result.status = repeatFailed ? .failure : .success

            case let .repeatWhile(block):
                var nested: [BlockResult] = []
                var repeatFailed = false
                var iterations = 0

                let nestedUpdate: (BlockResult) async -> Void = { [weak self] updated in
                    if let index = nested.firstIndex(where: { $0.id == updated.id }) {
                        nested[index] = updated
                    } else {
                        nested.append(updated)
                    }
                    result.nestedResults = nested
                    await onUpdate(result)
                }

                while iterations < block.maxIterations {
                    let condResult = await conditionEvaluator.evaluate(block.condition)
                    guard condResult.passed else { break }

                    result.detail = "Iteration \(iterations + 1)"
                    await onUpdate(result)

                    for (i, b) in block.blocks.enumerated() {
                        let r = await executeBlock(b, index: i, context: context, onUpdate: nestedUpdate)
                        if !nested.contains(where: { $0.id == r.id }) {
                            nested.append(r)
                        }
                        if r.status == .failure {
                            repeatFailed = true
                            if !context.workflow.continueOnError { break }
                        }
                    }
                    if repeatFailed && !context.workflow.continueOnError { break }

                    iterations += 1
                    if let delay = block.delayBetweenSeconds {
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                }
                result.detail = "Repeated \(iterations) times (max: \(block.maxIterations))"
                result.nestedResults = nested
                result.status = repeatFailed ? .failure : .success

            case let .group(block):
                var nested: [BlockResult] = []
                var groupFailed = false

                let nestedUpdate: (BlockResult) async -> Void = { [weak self] updated in
                    if let index = nested.firstIndex(where: { $0.id == updated.id }) {
                        nested[index] = updated
                    } else {
                        nested.append(updated)
                    }
                    result.nestedResults = nested
                    await onUpdate(result)
                }

                for (i, b) in block.blocks.enumerated() {
                    let r = await executeBlock(b, index: i, context: context, onUpdate: nestedUpdate)
                    if !nested.contains(where: { $0.id == r.id }) {
                        nested.append(r)
                    }
                    if r.status == .failure {
                        groupFailed = true
                        if !context.workflow.continueOnError { break }
                    }
                }
                result.detail = block.label ?? "Group"
                result.nestedResults = nested
                result.status = groupFailed ? .failure : .success
            }
        } catch {
            result.status = .failure
            result.errorMessage = error.localizedDescription
        }

        result.completedAt = Date()
        await onUpdate(result)
        return result
    }

    // MARK: - Helpers

    private func resolveDeviceName(_ deviceId: String) -> String {
        let devices = homeKitManager.cachedDevices
        if let device = devices.first(where: { $0.id == deviceId }) {
            if let room = device.roomName, !room.isEmpty {
                return "\(room) \(device.name)"
            }
            return device.name
        }
        return deviceId
    }

    // MARK: - WaitForState

    private func waitForState(_ block: WaitForStateBlock, onProgress: ((Double) async -> Void)? = nil) async throws -> Bool {
        let resolvedType = CharacteristicTypes.characteristicType(forName: block.characteristicType) ?? block.characteristicType
        let key = "\(block.deviceId):\(resolvedType)"

        // Check if condition is already met
        let device = await MainActor.run { homeKitManager.getDeviceState(id: block.deviceId) }
        if let device {
            let currentValue = findCharacteristicValue(in: device, characteristicType: resolvedType, serviceId: block.serviceId)
            if ConditionEvaluator.compare(currentValue, using: block.condition) {
                return true
            }
        }

        // Start time for progress tracking
        let startTime = Date()

        // Register a waiter and track the progress task so we can cancel it on completion
        var progressTask: Task<Void, Never>?

        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            let waiter = StateWaiter(
                deviceId: block.deviceId,
                characteristicType: resolvedType,
                serviceId: block.serviceId,
                condition: block.condition,
                continuation: continuation
            )

            if stateWaiters[key] == nil {
                stateWaiters[key] = []
            }
            stateWaiters[key]?.append(waiter)

            // Progress reporting task
            progressTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    if !Task.isCancelled {
                        let elapsedSeconds = Date().timeIntervalSince(startTime)
                        await onProgress?(elapsedSeconds)
                    }
                }
            }

            // Timeout
            Task {
                try await Task.sleep(nanoseconds: UInt64(block.timeoutSeconds * 1_000_000_000))
                await self.timeoutWaiter(waiter, key: key)
            }
        }

        // Stop progress reporting now that the wait is done
        progressTask?.cancel()

        return result
    }

    private func notifyStateWaiters(_ change: StateChange) {
        let key = "\(change.deviceId):\(change.characteristicType)"
        guard var waiters = stateWaiters[key], !waiters.isEmpty else { return }

        var remainingWaiters: [StateWaiter] = []
        for waiter in waiters {
            if ConditionEvaluator.compare(change.newValue, using: waiter.condition) {
                waiter.continuation.resume(returning: true)
            } else {
                remainingWaiters.append(waiter)
            }
        }
        stateWaiters[key] = remainingWaiters.isEmpty ? nil : remainingWaiters
    }

    private func timeoutWaiter(_ waiter: StateWaiter, key: String) {
        guard var waiters = stateWaiters[key] else { return }
        if let index = waiters.firstIndex(where: { $0.id == waiter.id }) {
            waiters.remove(at: index)
            stateWaiters[key] = waiters.isEmpty ? nil : waiters
            waiter.continuation.resume(returning: false)
        }
    }

    private func findCharacteristicValue(in device: DeviceModel, characteristicType: String, serviceId: String?) -> Any? {
        let services: [ServiceModel]
        if let serviceId {
            services = device.services.filter { $0.id == serviceId }
        } else {
            services = device.services
        }
        for service in services {
            for characteristic in service.characteristics where characteristic.type == characteristicType {
                return characteristic.value?.value
            }
        }
        return nil
    }

    // MARK: - Timeout Helper

    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw WorkflowEngineError.timeout
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Supporting Types

private struct ExecutionContext {
    let workflow: Workflow
}

private struct StateWaiter {
    let id = UUID()
    let deviceId: String
    let characteristicType: String
    let serviceId: String?
    let condition: ComparisonOperator
    let continuation: CheckedContinuation<Bool, Error>
}

enum WorkflowEngineError: LocalizedError {
    case timeout
    case invalidURL(String)
    case webhookFailed(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .timeout: return "Operation timed out"
        case let .invalidURL(url): return "Invalid URL: \(url)"
        case let .webhookFailed(code): return "Webhook failed with status \(code)"
        }
    }
}
