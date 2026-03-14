import Foundation

@MainActor
class BackupService: ObservableObject, BackupServiceProtocol {
    @Published var isBackingUp = false
    @Published var isRestoring = false
    @Published var lastError: String?

    private let storage: StorageService
    private let keychainService: KeychainService
    private let automationStorageService: AutomationStorageService
    private let homeKitManager: HomeKitManager
    private let loggingService: LoggingService
    private let deviceRegistryService: DeviceRegistryService

    init(
        storage: StorageService,
        keychainService: KeychainService,
        automationStorageService: AutomationStorageService,
        homeKitManager: HomeKitManager,
        loggingService: LoggingService,
        deviceRegistryService: DeviceRegistryService
    ) {
        self.storage = storage
        self.keychainService = keychainService
        self.automationStorageService = automationStorageService
        self.homeKitManager = homeKitManager
        self.loggingService = loggingService
        self.deviceRegistryService = deviceRegistryService
    }

    // MARK: - Create Backup

    func createBackup() async throws -> BackupBundle {
        isBackingUp = true
        lastError = nil
        defer { isBackingUp = false }

        let settings = BackupSettings(
            mcpServerPort: storage.mcpServerPort,
            webhookEnabled: storage.webhookEnabled,
            mcpServerEnabled: storage.mcpServerEnabled,
            hideRoomNameInTheApp: storage.hideRoomNameInTheApp,
            loggingEnabled: storage.loggingEnabled,
            mcpLoggingEnabled: storage.mcpLoggingEnabled,
            restLoggingEnabled: storage.restLoggingEnabled,
            webhookLoggingEnabled: storage.webhookLoggingEnabled,
            automationLoggingEnabled: storage.automationLoggingEnabled,
            mcpDetailedLogsEnabled: storage.mcpDetailedLogsEnabled,
            restDetailedLogsEnabled: storage.restDetailedLogsEnabled,
            webhookDetailedLogsEnabled: storage.webhookDetailedLogsEnabled,
            detailedLogsEnabled: nil,
            aiEnabled: storage.aiEnabled,
            aiProvider: storage.aiProvider.rawValue,
            aiModelId: storage.aiModelId,
            mcpServerBindAddress: storage.mcpServerBindAddress,
            corsEnabled: storage.corsEnabled,
            corsAllowedOrigins: storage.corsAllowedOrigins,
            sunEventLatitude: storage.sunEventLatitude,
            sunEventLongitude: storage.sunEventLongitude,
            sunEventZipCode: storage.sunEventZipCode,
            sunEventCityName: storage.sunEventCityName,
            pollingEnabled: storage.pollingEnabled,
            pollingInterval: storage.pollingInterval,
            automationsEnabled: storage.automationsEnabled,
            autoBackupEnabled: storage.autoBackupEnabled,
            autoBackupIntervalHours: storage.autoBackupIntervalHours,
            deviceStateLoggingEnabled: storage.deviceStateLoggingEnabled,
            logOnlyWebhookDevices: storage.logOnlyWebhookDevices,
            logCacheSize: storage.logCacheSize
        )

        let secrets = BackupSecrets(
            aiApiKey: keychainService.read(key: KeychainService.Keys.aiApiKey),
            mcpApiToken: nil,
            apiTokens: keychainService.getAPITokens(),
            webhookSecret: keychainService.read(key: KeychainService.Keys.webhookSecret),
            webhookURL: keychainService.read(key: KeychainService.Keys.webhookURL)
        )

        // Normalize automation IDs to stable registry IDs before export
        var automations = await automationStorageService.getAllAutomations()
        let (normalizedExportAutomations, exportNormalizedCount) = AutomationMigrationService.migrateToStableIds(
            automations, registry: deviceRegistryService
        )
        if exportNormalizedCount > 0 {
            automations = normalizedExportAutomations
            await automationStorageService.replaceAll(automations: normalizedExportAutomations)
            AppLogger.registry.info("Backup export: normalized \(exportNormalizedCount) automation ID reference(s) to stable IDs")
        }

        // Capture the full registry snapshot (includes enabled/observed settings)
        let registrySnapshot = await deviceRegistryService.snapshot()

        return BackupBundle(
            formatVersion: BackupBundle.currentFormatVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            createdAt: Date(),
            deviceName: ProcessInfo.processInfo.hostName,
            backupId: UUID(),
            settings: settings,
            secrets: secrets,
            automations: automations,
            registry: registrySnapshot
        )
    }

    // MARK: - Restore Backup

    func restoreBackup(_ bundle: BackupBundle) async throws {
        isRestoring = true
        lastError = nil
        defer { isRestoring = false }

        guard bundle.formatVersion <= BackupBundle.currentFormatVersion else {
            let error = "Backup format version \(bundle.formatVersion) is newer than supported version \(BackupBundle.currentFormatVersion). Please update the app."
            lastError = error
            throw BackupError.unsupportedVersion(bundle.formatVersion)
        }

        // Restore settings
        let s = bundle.settings
        storage.mcpServerPort = s.mcpServerPort
        storage.webhookEnabled = s.webhookEnabled
        storage.mcpServerEnabled = s.mcpServerEnabled
        storage.hideRoomNameInTheApp = s.hideRoomNameInTheApp
        // Restore per-category logging settings (with legacy fallback)
        let legacyDetailed = s.detailedLogsEnabled ?? false
        storage.loggingEnabled = s.loggingEnabled ?? true
        storage.mcpLoggingEnabled = s.mcpLoggingEnabled ?? true
        storage.restLoggingEnabled = s.restLoggingEnabled ?? true
        storage.webhookLoggingEnabled = s.webhookLoggingEnabled ?? true
        storage.automationLoggingEnabled = s.automationLoggingEnabled ?? true
        storage.mcpDetailedLogsEnabled = s.mcpDetailedLogsEnabled ?? legacyDetailed
        storage.restDetailedLogsEnabled = s.restDetailedLogsEnabled ?? legacyDetailed
        storage.webhookDetailedLogsEnabled = s.webhookDetailedLogsEnabled ?? legacyDetailed
        storage.aiEnabled = s.aiEnabled
        storage.aiProvider = AIProvider(rawValue: s.aiProvider) ?? .claude
        storage.aiModelId = s.aiModelId
        storage.mcpServerBindAddress = NetworkInterfaceEnumerator.resolvedBindAddress(s.mcpServerBindAddress)
        storage.corsEnabled = s.corsEnabled ?? true
        storage.corsAllowedOrigins = s.corsAllowedOrigins ?? []
        storage.sunEventLatitude = s.sunEventLatitude
        storage.sunEventLongitude = s.sunEventLongitude
        storage.sunEventZipCode = s.sunEventZipCode ?? ""
        storage.sunEventCityName = s.sunEventCityName ?? ""
        storage.pollingEnabled = s.pollingEnabled
        storage.pollingInterval = s.pollingInterval
        storage.automationsEnabled = s.automationsEnabled
        storage.autoBackupEnabled = s.autoBackupEnabled
        storage.autoBackupIntervalHours = s.autoBackupIntervalHours ?? 24
        storage.deviceStateLoggingEnabled = s.deviceStateLoggingEnabled ?? true
        storage.logOnlyWebhookDevices = s.logOnlyWebhookDevices ?? false
        storage.logCacheSize = s.logCacheSize ?? 500

        // Restore secrets
        let sec = bundle.secrets
        if let key = sec.aiApiKey, !key.isEmpty {
            keychainService.save(key: KeychainService.Keys.aiApiKey, value: key)
        }
        // Restore API tokens (prefer multi-token, fall back to legacy single token)
        if let tokens = sec.apiTokens, !tokens.isEmpty {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(tokens),
               let json = String(data: data, encoding: .utf8) {
                keychainService.save(key: KeychainService.Keys.mcpApiTokens, value: json)
            }
            keychainService.delete(key: KeychainService.Keys.mcpApiToken)
        } else if let token = sec.mcpApiToken, !token.isEmpty {
            // Legacy backup — migrate single token
            let migrated = APIToken(name: "Default", token: token)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode([migrated]),
               let json = String(data: data, encoding: .utf8) {
                keychainService.save(key: KeychainService.Keys.mcpApiTokens, value: json)
            }
            keychainService.delete(key: KeychainService.Keys.mcpApiToken)
        }
        if let secret = sec.webhookSecret, !secret.isEmpty {
            keychainService.save(key: KeychainService.Keys.webhookSecret, value: secret)
        }
        if let url = sec.webhookURL, !url.isEmpty {
            keychainService.save(key: KeychainService.Keys.webhookURL, value: url)
            storage.webhookURL = url
        } else {
            keychainService.delete(key: KeychainService.Keys.webhookURL)
            storage.webhookURL = nil
        }

        // Restore automations
        await automationStorageService.replaceAll(automations: bundle.automations)

        // Import the backup's registry and consolidate with local HomeKit devices.
        let consolidation = await deviceRegistryService.importAndConsolidate(
            bundle.registry,
            currentDevices: homeKitManager.cachedDevices,
            currentScenes: homeKitManager.cachedScenes
        )

        // Normalize any remaining HomeKit UUIDs in automations to stable IDs.
        // After consolidation, the registry has the correct mappings.
        let restoredAutomations = await automationStorageService.getAllAutomations()
        let (normalizedRestoreAutomations, restoreNormalizedCount) = AutomationMigrationService.migrateToStableIds(
            restoredAutomations, registry: deviceRegistryService
        )
        if restoreNormalizedCount > 0 {
            await automationStorageService.replaceAll(automations: normalizedRestoreAutomations)
            AppLogger.registry.info("Backup restore: normalized \(restoreNormalizedCount) automation ID reference(s) to stable IDs")
        }

        // Deep validation: check all serviceId + characteristicType references against the registry.
        let latestAutomations = await automationStorageService.getAllAutomations()
        let validation = await AutomationMigrationService.validateAndRepairReferences(
            latestAutomations, registry: deviceRegistryService
        )
        if !validation.autoFixed.isEmpty {
            await automationStorageService.replaceAll(automations: validation.updatedAutomations)
            AppLogger.registry.info("Backup restore validation: auto-fixed \(validation.autoFixed.count) issue(s)")
        }
        if !validation.unresolvable.isEmpty {
            AppLogger.registry.warning("Backup restore validation: \(validation.unresolvable.count) unresolvable issue(s)")
            for issue in validation.unresolvable {
                let logEntry = StateChangeLog.serverError(
                    errorDetails: "[\(issue.automationName)] Restore: \(issue.location): \(issue.detail)"
                )
                await loggingService.logEntry(logEntry)
            }
        }

        // Log consolidation summary
        let summary = buildConsolidationSummary(
            automationCount: bundle.automations.count,
            consolidation: consolidation,
            validationAutoFixed: validation.autoFixed.count,
            validationUnresolvable: validation.unresolvable.count
        )
        let summaryEntry = StateChangeLog.backupRestore(
            subtype: "restore-summary",
            summary: summary
        )
        await loggingService.logEntry(summaryEntry)
    }

    // MARK: - Helpers

    private func buildConsolidationSummary(automationCount: Int, consolidation: ConsolidationResult, validationAutoFixed: Int = 0, validationUnresolvable: Int = 0) -> String {
        var parts: [String] = ["Restored \(automationCount) automation(s) with registry."]
        parts.append("Devices: \(consolidation.matchedDevices) matched, \(consolidation.unmatchedDevices) unresolved, \(consolidation.newDevices) new local.")
        parts.append("Scenes: \(consolidation.matchedScenes) matched, \(consolidation.unmatchedScenes) unresolved, \(consolidation.newScenes) new local.")
        if validationAutoFixed > 0 {
            parts.append("Validation: auto-fixed \(validationAutoFixed) automation reference(s).")
        }
        if validationUnresolvable > 0 {
            parts.append("Validation: \(validationUnresolvable) unresolvable reference(s) — check Settings > Device Registry.")
        }
        if consolidation.unmatchedDevices > 0 || consolidation.unmatchedScenes > 0 {
            parts.append("Unresolved entries can be remapped in Settings > Device Registry.")
        }
        return parts.joined(separator: " ")
    }

}

// MARK: - Errors

enum BackupError: LocalizedError {
    case unsupportedVersion(Int)
    case invalidFormat(String)
    case cloudNotAvailable
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let v):
            return "Backup format version \(v) is not supported. Please update the app."
        case .invalidFormat(let detail):
            return "Invalid backup file: \(detail)"
        case .cloudNotAvailable:
            return "iCloud is not available. Please sign in to iCloud in System Settings."
        case .notSignedIn:
            return "Please sign in with Apple to use iCloud backup."
        }
    }
}
