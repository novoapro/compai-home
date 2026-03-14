import Foundation
import os

/// Centralized loggers for the app, replacing scattered `print()` calls.
/// Uses `os.Logger` for structured logging with categories and levels.
enum AppLogger {
    static let homeKit = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.compai-home", category: "HomeKit")
    static let server = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.compai-home", category: "MCPServer")
    static let config = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.compai-home", category: "Config")
    static let menuBar = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.compai-home", category: "MenuBar")
    static let general = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.compai-home", category: "General")
    static let automation = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.compai-home", category: "Automation")
    static let scene = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.compai-home", category: "Scene")
    static let registry = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.compai-home", category: "Registry")
}
