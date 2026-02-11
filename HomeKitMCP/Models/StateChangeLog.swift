import Foundation

enum LogCategory: String, Codable {
    case stateChange = "state_change"
    case webhookError = "webhook_error"
    case serverError = "server_error"
}

struct StateChangeLog: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let deviceId: String
    let deviceName: String
    let characteristicType: String
    let oldValue: AnyCodable?
    let newValue: AnyCodable?
    var category: LogCategory
    var errorDetails: String?

    init(id: UUID, timestamp: Date, deviceId: String, deviceName: String, characteristicType: String, oldValue: AnyCodable?, newValue: AnyCodable?, category: LogCategory = .stateChange, errorDetails: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.characteristicType = characteristicType
        self.oldValue = oldValue
        self.newValue = newValue
        self.category = category
        self.errorDetails = errorDetails
    }
}

struct StateChange {
    let deviceId: String
    let deviceName: String
    let characteristicType: String
    let oldValue: Any?
    let newValue: Any?
    let timestamp: Date

    init(deviceId: String, deviceName: String, characteristicType: String, oldValue: Any? = nil, newValue: Any? = nil) {
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.characteristicType = characteristicType
        self.oldValue = oldValue
        self.newValue = newValue
        self.timestamp = Date()
    }
}
