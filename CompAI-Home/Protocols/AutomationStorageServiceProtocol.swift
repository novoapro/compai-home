import Foundation
import Combine

/// Protocol abstracting AutomationStorageService for dependency injection and testability.
protocol AutomationStorageServiceProtocol: AnyObject, Sendable {
    // MARK: - Publishers
    var automationsSubject: PassthroughSubject<[Automation], Never> { get }

    // MARK: - Read
    func getAllAutomations() async -> [Automation]
    func getAutomation(id: UUID) async -> Automation?
    func getEnabledAutomations() async -> [Automation]

    // MARK: - Write
    @discardableResult
    func createAutomation(_ automation: Automation) async -> Automation
    @discardableResult
    func updateAutomation(id: UUID, update: (inout Automation) -> Void) async -> Automation?
    @discardableResult
    func deleteAutomation(id: UUID) async -> Bool

    // MARK: - Metadata
    func updateMetadata(id: UUID, lastTriggered: Date, incrementExecutions: Bool, resetFailures: Bool) async
    func incrementFailures(id: UUID) async
    func resetStatistics(id: UUID) async

    // MARK: - Restore
    func replaceAll(automations: [Automation]) async
}
