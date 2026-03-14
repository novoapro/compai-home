import Foundation

extension FileManager {
    /// Returns the app's `~/Library/Application Support/CompAI-Home/` directory,
    /// creating it with 0o700 permissions if it doesn't exist.
    /// On first launch, migrates data from the legacy `HomeKitMCP` directory if present.
    static var appSupportDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appDir = appSupport.appendingPathComponent("CompAI-Home")
        let legacyDir = appSupport.appendingPathComponent("HomeKitMCP")

        // Migrate from legacy directory if it exists and new one doesn't
        if FileManager.default.fileExists(atPath: legacyDir.path) &&
           !FileManager.default.fileExists(atPath: appDir.path) {
            try? FileManager.default.moveItem(at: legacyDir, to: appDir)
        }

        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: appDir.path)
        return appDir
    }
}
