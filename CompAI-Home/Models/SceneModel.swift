import Foundation

struct SceneModel: Identifiable, Codable {
    let id: String
    let name: String
    let type: String
    let isExecuting: Bool
    let actions: [SceneActionModel]
}

struct SceneActionModel: Identifiable, Codable {
    let id: String
    let deviceId: String
    let deviceName: String
    let serviceName: String
    let characteristicType: String
    let targetValue: AnyCodable
}
