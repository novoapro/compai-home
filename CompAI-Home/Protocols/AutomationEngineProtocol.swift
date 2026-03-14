import Foundation

/// Protocol abstracting AutomationEngine for dependency injection and testability.
protocol AutomationEngineProtocol: AnyObject, Sendable {
    func registerEvaluator(_ evaluator: TriggerEvaluator) async
    func processStateChange(_ change: StateChange) async
    func triggerAutomation(id: UUID) async -> AutomationExecutionLog?
    func triggerAutomation(id: UUID, triggerEvent: TriggerEvent) async -> AutomationExecutionLog?
    func triggerAutomation(id: UUID, triggerEvent: TriggerEvent, policy: ConcurrentExecutionPolicy?) async -> AutomationExecutionLog?
    func scheduleTrigger(id: UUID) async -> TriggerResult
    func scheduleTrigger(id: UUID, triggerEvent: TriggerEvent) async -> TriggerResult
    func scheduleTrigger(id: UUID, triggerEvent: TriggerEvent, policy: ConcurrentExecutionPolicy?) async -> TriggerResult
    func scheduleTrigger(id: UUID, triggerEvent: TriggerEvent, policy: ConcurrentExecutionPolicy?, triggerConditions: [AutomationCondition]?) async -> TriggerResult
    func cancelExecution(executionId: UUID) async
    func cancelRunningExecutions(forAutomation automationId: UUID) async
}
