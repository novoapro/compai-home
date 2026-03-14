import Foundation
import Combine

actor AutomationStorageService: AutomationStorageServiceProtocol {
    private var automations: [UUID: Automation] = [:]
    private let fileURL: URL
    private var saveTask: Task<Void, Never>?

    nonisolated let automationsSubject = PassthroughSubject<[Automation], Never>()

    init() {
        let appDir = FileManager.appSupportDirectory
        self.fileURL = appDir.appendingPathComponent("automations.json")

        // Try loading from automations.json first, fall back to legacy workflows.json
        let legacyURL = appDir.appendingPathComponent("workflows.json")
        let loadURL: URL
        if FileManager.default.fileExists(atPath: fileURL.path) {
            loadURL = fileURL
        } else if FileManager.default.fileExists(atPath: legacyURL.path) {
            loadURL = legacyURL
        } else {
            loadURL = fileURL
        }

        if let data = try? Data(contentsOf: loadURL),
           let saved = try? JSONDecoder.iso8601.decode([Automation].self, from: data) {
            for automation in saved {
                self.automations[automation.id] = automation
            }
            // If loaded from legacy file, save to new location and remove legacy
            if loadURL == legacyURL {
                try? data.write(to: fileURL, options: .atomic)
                try? FileManager.default.removeItem(at: legacyURL)
            }
        }
    }

    // MARK: - CRUD

    func getAllAutomations() -> [Automation] {
        Array(automations.values).sorted { $0.createdAt > $1.createdAt }
    }

    func getAutomation(id: UUID) -> Automation? {
        automations[id]
    }

    func getEnabledAutomations() -> [Automation] {
        automations.values.filter(\.isEnabled).sorted { $0.createdAt > $1.createdAt }
    }

    @discardableResult
    func createAutomation(_ automation: Automation) -> Automation {
        automations[automation.id] = automation
        publishAndSave()
        return automation
    }

    @discardableResult
    func updateAutomation(id: UUID, update: (inout Automation) -> Void) -> Automation? {
        guard var automation = automations[id] else { return nil }
        update(&automation)
        automation.updatedAt = Date()
        automations[id] = automation
        publishAndSave()
        return automation
    }

    @discardableResult
    func deleteAutomation(id: UUID) -> Bool {
        guard automations.removeValue(forKey: id) != nil else { return false }
        publishAndSave()
        return true
    }

    // MARK: - Metadata Helpers

    func updateMetadata(id: UUID, lastTriggered: Date, incrementExecutions: Bool, resetFailures: Bool) {
        guard var automation = automations[id] else { return }
        automation.metadata.lastTriggeredAt = lastTriggered
        if incrementExecutions {
            automation.metadata.totalExecutions += 1
        }
        if resetFailures {
            automation.metadata.consecutiveFailures = 0
        }
        automations[id] = automation
        publishAndSave()
    }

    func incrementFailures(id: UUID) {
        guard var automation = automations[id] else { return }
        automation.metadata.consecutiveFailures += 1
        automations[id] = automation
        publishAndSave()
    }

    func resetStatistics(id: UUID) {
        guard var automation = automations[id] else { return }
        automation.metadata.totalExecutions = 0
        automation.metadata.consecutiveFailures = 0
        automation.metadata.lastTriggeredAt = nil
        automations[id] = automation
        publishAndSave()
    }

    func replaceAll(automations newAutomations: [Automation]) {
        automations.removeAll()
        for automation in newAutomations {
            automations[automation.id] = automation
        }
        publishAndSave()
    }

    func deleteAllAutomations() {
        replaceAll(automations: [])
    }

    // MARK: - Persistence

    private func publishAndSave() {
        automationsSubject.send(getAllAutomations())
        debouncedSave()
    }

    private func debouncedSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            await self?.saveNow()
        }
    }

    private func saveNow() {
        do {
            let allAutomations = getAllAutomations()
            let data = try JSONEncoder.iso8601Pretty.encode(allAutomations)
            try data.write(to: fileURL, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
        } catch {
            AppLogger.general.error("Failed to save automations: \(error)")
        }
    }
}
