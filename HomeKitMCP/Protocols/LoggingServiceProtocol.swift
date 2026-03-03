import Foundation
import Combine

/// Protocol abstracting LoggingService for dependency injection and testability.
protocol LoggingServiceProtocol: AnyObject, Sendable {
    // MARK: - Publishers
    var logsSubject: PassthroughSubject<[StateChangeLog], Never> { get }

    // MARK: - Write
    func logEntry(_ entry: StateChangeLog) async
    func updateEntry(_ entry: StateChangeLog) async

    // MARK: - Read
    func getLogs() async -> [StateChangeLog]
    func getLogs(forWorkflowId id: UUID) async -> [StateChangeLog]
    func clearLogs() async
    func clearLogs(forWorkflowId id: UUID) async
}
