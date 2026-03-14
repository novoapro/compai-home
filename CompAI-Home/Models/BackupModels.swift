import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Backup Bundle

struct BackupBundle: Codable {
    let formatVersion: Int
    let appVersion: String
    let createdAt: Date
    let deviceName: String
    let backupId: UUID

    let settings: BackupSettings
    let secrets: BackupSecrets
    let automations: [Automation]
    let registry: RegistrySnapshot

    static let currentFormatVersion = 3
}

// MARK: - Settings Snapshot

struct BackupSettings: Codable {
    let mcpServerPort: Int
    let webhookEnabled: Bool
    let mcpServerEnabled: Bool
    let hideRoomNameInTheApp: Bool
    let loggingEnabled: Bool?
    let mcpLoggingEnabled: Bool?
    let restLoggingEnabled: Bool?
    let webhookLoggingEnabled: Bool?
    let automationLoggingEnabled: Bool?
    let mcpDetailedLogsEnabled: Bool?
    let restDetailedLogsEnabled: Bool?
    let webhookDetailedLogsEnabled: Bool?
    let detailedLogsEnabled: Bool?  // legacy, for backward-compatible restore
    let aiEnabled: Bool
    let aiProvider: String
    let aiModelId: String
    let mcpServerBindAddress: String
    let corsEnabled: Bool?
    let corsAllowedOrigins: [String]?
    let sunEventLatitude: Double
    let sunEventLongitude: Double
    let sunEventZipCode: String?
    let sunEventCityName: String?
    let pollingEnabled: Bool
    let pollingInterval: Int
    let automationsEnabled: Bool
    let autoBackupEnabled: Bool
    let autoBackupIntervalHours: Int?
    let deviceStateLoggingEnabled: Bool?
    let logOnlyWebhookDevices: Bool?
    let logCacheSize: Int?
}

// MARK: - Secrets (plain JSON)

struct BackupSecrets: Codable {
    let aiApiKey: String?
    let mcpApiToken: String?          // Legacy single token (for backward compat)
    let apiTokens: [APIToken]?        // Multi-token support
    let webhookSecret: String?
    let webhookURL: String?
}

// MARK: - File Document (for local export/import)

extension UTType {
    static let compaiBackup = UTType(exportedAs: "com.mnplab.compai-home.backup")
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.compaiBackup, .json] }
    static var writableContentTypes: [UTType] { [.compaiBackup] }

    let bundle: BackupBundle

    init(bundle: BackupBundle) {
        self.bundle = bundle
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw BackupError.invalidFormat("File has no contents")
        }
        self.bundle = try JSONDecoder.iso8601.decode(BackupBundle.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder.iso8601Pretty.encode(bundle)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Cloud Backup Metadata

struct CloudBackupMetadata: Identifiable {
    let id: String          // CKRecord.ID.recordName
    let backupId: UUID
    let createdAt: Date
    let deviceName: String
    let appVersion: String
    let formatVersion: Int
}
