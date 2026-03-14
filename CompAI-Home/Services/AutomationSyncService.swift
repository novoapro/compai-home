import Foundation
import CloudKit
import Combine

/// Per-automation CloudKit sync service.
///
/// Each automation is stored as a separate `SyncedWorkflow` CKRecord using stable registry IDs.
/// Outbound: debounced 5-second save after local changes.
/// Inbound: periodic poll for remote changes (every 60 seconds while enabled).
/// Conflict resolution: last-writer-wins using `updatedAt`.
@MainActor
class AutomationSyncService: ObservableObject {

    @Published var isSyncing = false
    @Published var lastSyncError: String?
    @Published var lastSyncDate: Date?

    private let container: CKContainer
    private let privateDB: CKDatabase
    private let automationStorageService: AutomationStorageService
    private let storage: StorageService
    private let deviceRegistryService: DeviceRegistryService
    private let homeKitManager: HomeKitManager
    private var cancellables = Set<AnyCancellable>()
    private var outboundTask: Task<Void, Never>?
    private var pollTask: Task<Void, Never>?

    /// Tracks which automation IDs we've seen locally, to detect remote additions.
    private var knownAutomationIds = Set<UUID>()
    /// Prevents re-entrant saves when applying remote changes.
    private var isApplyingRemote = false

    static let recordType = "SyncedWorkflow"
    static let containerIdentifier = "iCloud.com.mnplab.compai-home"

    private let deviceId: String

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    init(automationStorageService: AutomationStorageService, storage: StorageService, deviceRegistryService: DeviceRegistryService, homeKitManager: HomeKitManager) {
        self.automationStorageService = automationStorageService
        self.storage = storage
        self.deviceRegistryService = deviceRegistryService
        self.homeKitManager = homeKitManager
        self.container = CKContainer(identifier: Self.containerIdentifier)
        self.privateDB = container.privateCloudDatabase
        self.deviceId = ProcessInfo.processInfo.hostName

        setupSubscriptions()
    }

    // MARK: - Setup

    private func setupSubscriptions() {
        // Watch for local automation changes → outbound sync
        automationStorageService.automationsSubject
            .receive(on: DispatchQueue.global(qos: .utility))
            .sink { [weak self] automations in
                guard let self else { return }
                Task { @MainActor in
                    guard self.storage.automationSyncEnabled, !self.isApplyingRemote else { return }
                    self.scheduleOutboundSync(automations)
                }
            }
            .store(in: &cancellables)

        // Watch for sync toggle changes
        storage.$automationSyncEnabled
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self else { return }
                if enabled {
                    self.startPolling()
                    // Perform initial sync
                    Task { await self.performFullSync() }
                } else {
                    self.stopPolling()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Outbound Sync

    private func scheduleOutboundSync(_ automations: [Automation]) {
        outboundTask?.cancel()
        outboundTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 second debounce
            guard !Task.isCancelled else { return }
            await pushAutomations(automations)
        }
    }

    private func pushAutomations(_ automations: [Automation]) async {
        guard storage.automationSyncEnabled else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            try await verifyCloudAvailability()

            var recordsToSave: [CKRecord] = []

            for automation in automations {
                let recordName = "syncwf-\(automation.id.uuidString)"
                let recordID = CKRecord.ID(recordName: recordName)
                let record = CKRecord(recordType: Self.recordType, recordID: recordID)

                let data = try Self.encoder.encode(automation)
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(automation.id.uuidString).automation.json")
                try data.write(to: tempURL, options: .atomic)

                record["automationId"] = automation.id.uuidString as CKRecordValue
                record["automationData"] = CKAsset(fileURL: tempURL)
                record["updatedAt"] = automation.updatedAt as CKRecordValue
                record["syncVersion"] = 1 as CKRecordValue
                record["originDeviceId"] = deviceId as CKRecordValue
                record["isDeleted"] = 0 as CKRecordValue

                recordsToSave.append(record)
            }

            // Also mark deleted automations as tombstones
            let localIds = Set(automations.map(\.id))
            let removedIds = knownAutomationIds.subtracting(localIds)
            for removedId in removedIds {
                let recordName = "syncwf-\(removedId.uuidString)"
                let recordID = CKRecord.ID(recordName: recordName)
                let record = CKRecord(recordType: Self.recordType, recordID: recordID)
                record["automationId"] = removedId.uuidString as CKRecordValue
                record["updatedAt"] = Date() as CKRecordValue
                record["originDeviceId"] = deviceId as CKRecordValue
                record["isDeleted"] = 1 as CKRecordValue
                recordsToSave.append(record)
            }

            knownAutomationIds = localIds

            guard !recordsToSave.isEmpty else { return }

            // Batch save with overwrite policy
            let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: nil)
            operation.savePolicy = .changedKeys
            operation.qualityOfService = .utility

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                privateDB.add(operation)
            }

            lastSyncDate = Date()
            lastSyncError = nil

            // Clean up temp files
            for record in recordsToSave {
                if let asset = record["automationData"] as? CKAsset, let url = asset.fileURL {
                    try? FileManager.default.removeItem(at: url)
                }
            }

            AppLogger.automation.info("Automation sync: pushed \(recordsToSave.count) automation(s)")
        } catch {
            lastSyncError = error.localizedDescription
            AppLogger.automation.error("Automation sync push failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Inbound Sync (Pull)

    private func startPolling() {
        stopPolling()
        pollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds
                guard !Task.isCancelled else { break }
                await pullRemoteChanges()
            }
        }
    }

    private func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    func pullRemoteChanges() async {
        guard storage.automationSyncEnabled else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            try await verifyCloudAvailability()

            let query = CKQuery(recordType: Self.recordType, predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]

            let (results, _) = try await privateDB.records(matching: query, resultsLimit: 200)

            var remoteAutomations: [UUID: (Automation, Date, Bool)] = [:] // id → (automation, updatedAt, isDeleted)

            for (_, result) in results {
                guard let record = try? result.get() else { continue }
                let isDeleted = (record["isDeleted"] as? Int ?? 0) == 1
                guard let automationIdStr = record["automationId"] as? String,
                      let automationId = UUID(uuidString: automationIdStr) else { continue }

                let updatedAt = record["updatedAt"] as? Date ?? Date.distantPast

                if isDeleted {
                    remoteAutomations[automationId] = (Automation(id: automationId, name: "", triggers: [], blocks: []), updatedAt, true)
                    continue
                }

                guard let asset = record["automationData"] as? CKAsset,
                      let fileURL = asset.fileURL,
                      let data = try? Data(contentsOf: fileURL),
                      let automation = try? JSONDecoder.iso8601.decode(Automation.self, from: data) else { continue }

                remoteAutomations[automationId] = (automation, updatedAt, false)
            }

            // Apply remote changes
            let localAutomations = await automationStorageService.getAllAutomations()
            let localById = Dictionary(uniqueKeysWithValues: localAutomations.map { ($0.id, $0) })
            var changed = false

            isApplyingRemote = true
            defer { isApplyingRemote = false }

            for (id, (remoteAutomation, remoteUpdatedAt, isDeleted)) in remoteAutomations {
                if isDeleted {
                    if localById[id] != nil {
                        await automationStorageService.deleteAutomation(id: id)
                        changed = true
                        AppLogger.automation.info("Automation sync: deleted '\(id)' from remote tombstone")
                    }
                    continue
                }

                if let localAutomation = localById[id] {
                    let localUpdatedAt = localAutomation.updatedAt
                    // Last-writer-wins: only apply if remote is newer
                    if remoteUpdatedAt > localUpdatedAt {
                        await automationStorageService.updateAutomation(id: id) { automation in
                            automation = remoteAutomation
                        }
                        changed = true
                        AppLogger.automation.info("Automation sync: updated '\(remoteAutomation.name)' from remote")
                    }
                } else {
                    // New automation from remote
                    await automationStorageService.createAutomation(remoteAutomation)
                    changed = true
                    AppLogger.automation.info("Automation sync: added '\(remoteAutomation.name)' from remote")
                }
            }

            // Update known IDs
            let allLocal = await automationStorageService.getAllAutomations()
            knownAutomationIds = Set(allLocal.map(\.id))

            lastSyncDate = Date()
            lastSyncError = nil

            if changed {
                // Remap foreign stable IDs to local stable IDs so triggers fire correctly.
                // Imported automations from other machines use that machine's stable IDs, which
                // differ from local ones. Migration matches by name/room and remaps to local IDs.
                let rawDevices = homeKitManager.getAllDevices()
                let rawScenes = homeKitManager.getAllScenes()
                let stableDevices = deviceRegistryService.stableDevices(rawDevices)
                let stableScenes = deviceRegistryService.stableScenes(rawScenes)

                if !stableDevices.isEmpty || !stableScenes.isEmpty {
                    let migration = AutomationMigrationService.migrateAll(allLocal, using: stableDevices, scenes: stableScenes)
                    let totalRemapped = migration.totalRemappedDevices + migration.totalRemappedScenes
                    if totalRemapped > 0 {
                        await automationStorageService.replaceAll(automations: migration.automations)
                        AppLogger.automation.info("Automation sync: remapped \(migration.totalRemappedDevices) device(s), \(migration.totalRemappedScenes) scene(s)")
                    }
                }

                // Reconcile any remaining foreign stable IDs against local registry
                let automationsForReconciliation = await automationStorageService.getAllAutomations()
                let reconciledCount = await deviceRegistryService.reconcileAutomationReferences(
                    automationsForReconciliation,
                    currentDevices: rawDevices,
                    currentScenes: rawScenes
                )
                if reconciledCount > 0 {
                    AppLogger.automation.info("Automation sync: reconciled \(reconciledCount) foreign registry references")
                }

                AppLogger.automation.info("Automation sync: applied remote changes")
            }
        } catch {
            lastSyncError = error.localizedDescription
            AppLogger.automation.error("Automation sync pull failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Full Sync

    /// Performs a complete sync: pull remote changes first, then push local state.
    func performFullSync() async {
        guard storage.automationSyncEnabled else { return }
        await pullRemoteChanges()
        let automations = await automationStorageService.getAllAutomations()
        await pushAutomations(automations)
    }

    // MARK: - Helpers

    private func verifyCloudAvailability() async throws {
        let status = try await container.accountStatus()
        guard status == .available else {
            throw AutomationSyncError.cloudNotAvailable
        }
    }
}

// MARK: - Errors

enum AutomationSyncError: LocalizedError {
    case cloudNotAvailable

    var errorDescription: String? {
        switch self {
        case .cloudNotAvailable:
            return "iCloud is not available. Sign in to iCloud to enable automation sync."
        }
    }
}
