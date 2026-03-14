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
    func getLogs(forAutomationId id: UUID) async -> [StateChangeLog]
    func clearLogs() async
    func clearLogs(forAutomationId id: UUID) async
}
