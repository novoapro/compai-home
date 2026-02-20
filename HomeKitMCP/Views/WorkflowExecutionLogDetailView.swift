import Combine
import SwiftUI

/// Live-updating detail view that observes the LogViewModel for real-time block execution updates.
struct WorkflowExecutionLogDetailView: View {
    private let logId: UUID
    private let staticLog: WorkflowExecutionLog?
    @ObservedObject private var viewModel: _LogViewModelProxy

    /// Live-updating initializer — used from LogViewerView.
    init(logId: UUID, viewModel: LogViewModel) {
        self.logId = logId
        self.staticLog = nil
        self._viewModel = ObservedObject(wrappedValue: _LogViewModelProxy(viewModel: viewModel))
    }

    /// Static snapshot initializer — used from WorkflowDetailView.
    init(log: WorkflowExecutionLog) {
        self.logId = log.id
        self.staticLog = log
        self._viewModel = ObservedObject(wrappedValue: _LogViewModelProxy(viewModel: nil))
    }

    private var log: WorkflowExecutionLog? {
        viewModel.viewModel?.workflowExecutionLog(id: logId) ?? staticLog
    }

    var body: some View {
        if let log {
            logContent(log)
        } else {
            Text("Log not found")
                .foregroundColor(Theme.Text.secondary)
        }
    }

    @ViewBuilder
    private func logContent(_ log: WorkflowExecutionLog) -> some View {
        List {
            // Header
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: statusIcon(log.status))
                            .foregroundColor(statusColor(log.status))
                        Text(log.workflowName)
                            .font(.headline)
                        Spacer()
                        if let duration = executionDuration(log) {
                            Text(duration)
                                .font(.caption)
                                .foregroundColor(Theme.Text.secondary)
                        } else if log.status == .running {
                            LiveElapsedText(since: log.triggeredAt)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }

                    Text(log.triggeredAt, format: .dateTime)
                        .font(.subheadline)
                        .foregroundColor(Theme.Text.secondary)

                    if let error = log.errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(Theme.Status.error)
                    }
                }
            }
            .listRowBackground(Theme.contentBackground)

            // Trigger
            if let trigger = log.triggerEvent {
                Section("Trigger") {
                    triggerDetailView(trigger)
                }
                .listRowBackground(Theme.contentBackground)
            }

            // Conditions
            if let conditions = log.conditionResults, !conditions.isEmpty {
                Section("Conditions") {
                    ForEach(Array(conditions.enumerated()), id: \.offset) { _, condition in
                        HStack(spacing: 8) {
                            Image(systemName: condition.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(condition.passed ? Theme.Status.active : Theme.Status.error)
                            Text(condition.conditionDescription)
                                .font(.subheadline)
                        }
                    }
                }
                .listRowBackground(Theme.contentBackground)
            }

            // Steps
            if !log.blockResults.isEmpty {
                Section("Steps") {
                    ForEach(Array(log.blockResults.enumerated()), id: \.offset) { _, block in
                        blockResultView(block, depth: 0)
                    }
                }
                .listRowBackground(Theme.contentBackground)
            } else if log.status == .running {
                Section("Steps") {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Waiting for blocks to execute...")
                            .font(.subheadline)
                            .foregroundColor(Theme.Text.secondary)
                    }
                }
                .listRowBackground(Theme.contentBackground)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.mainBackground)
        .navigationTitle("Execution Log")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Recursive Block View

    private func blockResultView(_ result: BlockResult, depth: Int) -> AnyView {
        let title = result.blockName ?? result.blockType.replacingOccurrences(of: "_", with: " ").capitalized
        let dur: String? = {
            guard let completed = result.completedAt else { return nil }
            let interval = completed.timeIntervalSince(result.startedAt)
            return interval < 1 ? String(format: "%.0fms", interval * 1000) : String(format: "%.1fs", interval)
        }()
        let isContainer = result.nestedResults != nil && !(result.nestedResults?.isEmpty ?? true)
        let indentWidth = CGFloat(depth) * 20

        return AnyView(Group {
            HStack(alignment: .top, spacing: 0) {
                // Indentation with connector lines for each depth level
                if depth > 0 {
                    HStack(spacing: 0) {
                        ForEach(0 ..< depth, id: \.self) { level in
                            Rectangle()
                                .fill(depthColor(level).opacity(0.3))
                                .frame(width: 2)
                                .padding(.leading, level == 0 ? 6 : 14)
                        }
                    }
                    .frame(width: indentWidth)
                }

                // Step content
                HStack(alignment: .top, spacing: 8) {
                    if result.status == .running {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: stepIcon(result.status))
                            .font(.subheadline)
                            .foregroundColor(statusColor(result.status))
                            .frame(width: 16)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        // Title row
                        HStack {
                            if isContainer {
                                Image(systemName: containerIcon(result.blockType))
                                    .font(.caption2)
                                    .foregroundColor(Theme.Text.tertiary)
                            }
                            Text(title)
                                .font(.subheadline)
                                .fontWeight(isContainer ? .semibold : .medium)
                            Spacer()
                            if let dur {
                                Text(dur)
                                    .font(.caption2)
                                    .foregroundColor(Theme.Text.tertiary)
                            } else if result.status == .running {
                                LiveElapsedText(since: result.startedAt)
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }

                        // Detail
                        if let detail = result.detail {
                            Text(detail)
                                .font(.caption)
                                .foregroundColor(result.status == .running ? .blue : Theme.Text.secondary)
                        }

                        // Error
                        if let error = result.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(Theme.Status.error)
                        }
                    }
                }
                .padding(.leading, depth > 0 ? 8 : 0)
            }

            // Render nested children recursively
            if let nested = result.nestedResults {
                ForEach(Array(nested.enumerated()), id: \.offset) { _, child in
                    blockResultView(child, depth: depth + 1)
                }
            }
        })
    }

    private func containerIcon(_ blockType: String) -> String {
        switch blockType {
        case "conditional": return "arrow.triangle.branch"
        case "repeat", "repeatWhile": return "repeat"
        case "group": return "rectangle.3.group"
        case "delay": return "clock"
        case "waitForState": return "hourglass"
        default: return "square.stack"
        }
    }

    private func depthColor(_ level: Int) -> Color {
        let colors: [Color] = [Theme.Tint.main, .purple, .orange, .teal, .pink]
        return colors[level % colors.count]
    }

    // MARK: - Helpers

    private func triggerDetailView(_ trigger: TriggerEvent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Trigger description
            if let desc = trigger.triggerDescription {
                Text(desc)
                    .font(.subheadline)
                    .foregroundColor(Theme.Text.primary)
            }

            // Device info
            if let deviceName = trigger.deviceName {
                HStack(spacing: 6) {
                    Image(systemName: "house")
                        .font(.caption)
                        .foregroundColor(Theme.Tint.main)
                    Text(deviceName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // Characteristic + value change
            if let charType = trigger.characteristicType {
                let charName = CharacteristicTypes.displayName(for: charType)

                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)
                        .foregroundColor(Theme.Text.tertiary)
                    Text(charName)
                        .font(.subheadline)
                        .foregroundColor(Theme.Text.secondary)
                }

                // Value transition
                if trigger.oldValue != nil || trigger.newValue != nil {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(Theme.Text.tertiary)

                        if let oldVal = trigger.oldValue {
                            Text(CharacteristicTypes.formatValue(oldVal.value, characteristicType: charType))
                                .font(.subheadline)
                                .foregroundColor(Theme.Text.secondary)

                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundColor(Theme.Text.tertiary)
                        }

                        if let newVal = trigger.newValue {
                            Text(CharacteristicTypes.formatValue(newVal.value, characteristicType: charType))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.Text.primary)
                        }
                    }
                }
            }
        }
    }

    private func statusIcon(_ status: ExecutionStatus) -> String {
        switch status {
        case .success: return "checkmark.circle.fill"
        case .failure: return "xmark.circle.fill"
        case .running: return "circle.dotted"
        case .skipped: return "forward.circle.fill"
        case .conditionNotMet: return "exclamationmark.circle.fill"
        case .cancelled: return "slash.circle.fill"
        }
    }

    private func stepIcon(_ status: ExecutionStatus) -> String {
        switch status {
        case .success: return "checkmark.circle.fill"
        case .failure: return "xmark.circle.fill"
        case .running: return "circle.dotted"
        case .skipped: return "forward.circle.fill"
        case .conditionNotMet: return "exclamationmark.circle.fill"
        case .cancelled: return "slash.circle.fill"
        }
    }

    private func executionDuration(_ log: WorkflowExecutionLog) -> String? {
        guard let completed = log.completedAt else { return nil }
        let interval = completed.timeIntervalSince(log.triggeredAt)
        if interval < 1 {
            return String(format: "%.0fms", interval * 1000)
        } else if interval < 60 {
            return String(format: "%.1fs", interval)
        } else {
            return String(format: "%.0fm %.0fs", interval / 60, interval.truncatingRemainder(dividingBy: 60))
        }
    }

    private func statusColor(_ status: ExecutionStatus) -> Color {
        switch status {
        case .success: return Theme.Status.active
        case .failure: return Theme.Status.error
        case .running: return .blue
        case .skipped: return Theme.Status.inactive
        case .conditionNotMet: return Theme.Status.warning
        case .cancelled: return Theme.Status.inactive
        }
    }
}

// MARK: - Internal Proxy to allow optional LogViewModel observation

/// Thin ObservableObject wrapper that forwards objectWillChange from LogViewModel when available.
class _LogViewModelProxy: ObservableObject {
    let viewModel: LogViewModel?
    private var cancellable: AnyCancellable?

    init(viewModel: LogViewModel?) {
        self.viewModel = viewModel
        if let vm = viewModel {
            // Forward the LogViewModel's objectWillChange to our own
            cancellable = vm.objectWillChange.sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        }
    }
}

// MARK: - Live Elapsed Time Helper

/// A small view that shows a live-updating elapsed time string.
private struct LiveElapsedText: View {
    let since: Date
    @State private var elapsed: String = ""
    @State private var timer: Timer?

    var body: some View {
        Text(elapsed)
            .onAppear {
                updateElapsed()
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    updateElapsed()
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
    }

    private func updateElapsed() {
        let interval = Date().timeIntervalSince(since)
        if interval < 1 {
            elapsed = String(format: "%.0fms", interval * 1000)
        } else if interval < 60 {
            elapsed = String(format: "%.1fs", interval)
        } else {
            let minutes = Int(interval / 60)
            let seconds = Int(interval.truncatingRemainder(dividingBy: 60))
            elapsed = String(format: "%dm %ds", minutes, seconds)
        }
    }
}
