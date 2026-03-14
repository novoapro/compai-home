import Foundation

enum AppEnvironment: String {
    case dev
    case prod

    static var current: AppEnvironment {
        #if DEV_ENVIRONMENT
        return .dev
        #else
        return .prod
        #endif
    }

    var isDev: Bool { self == .dev }
    var isProd: Bool { self == .prod }

    /// Well-known dev token auto-injected in Dev builds so developers skip manual token setup.
    static let devDefaultToken = "dev-token-compai-home"
}

extension ProcessInfo {
    /// Returns `true` when the process is being launched as a unit test host.
    var isRunningTests: Bool {
        environment["XCTestConfigurationFilePath"] != nil
    }
}
