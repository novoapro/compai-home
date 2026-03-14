import Foundation
 import CompAI_Home

/// Helpers for building test models without boilerplate.
enum TestFixtures {

    static func makeCharacteristic(
        id: String = UUID().uuidString,
        type: String = "power-state",
        value: AnyCodable? = AnyCodable(true),
        format: String = "bool",
        units: String? = nil,
        permissions: [String] = ["read", "write"],
        minValue: Double? = nil,
        maxValue: Double? = nil,
        stepValue: Double? = nil,
        validValues: [Int]? = nil
    ) -> CharacteristicModel {
        CharacteristicModel(
            id: id,
            type: type,
            value: value,
            format: format,
            units: units,
            permissions: permissions,
            minValue: minValue,
            maxValue: maxValue,
            stepValue: stepValue,
            validValues: validValues
        )
    }

    static func makeService(
        id: String = UUID().uuidString,
        name: String = "Light",
        type: String = "lightbulb",
        characteristics: [CharacteristicModel]? = nil
    ) -> ServiceModel {
        ServiceModel(
            id: id,
            name: name,
            type: type,
            characteristics: characteristics ?? [makeCharacteristic()]
        )
    }

    static func makeDevice(
        id: String = UUID().uuidString,
        name: String = "Test Light",
        roomName: String? = "Living Room",
        categoryType: String = "lightbulb",
        services: [ServiceModel]? = nil,
        isReachable: Bool = true,
        manufacturer: String? = "TestCo",
        model: String? = "Model1",
        serialNumber: String? = "SN001",
        firmwareRevision: String? = nil
    ) -> DeviceModel {
        DeviceModel(
            id: id,
            name: name,
            roomName: roomName,
            categoryType: categoryType,
            services: services ?? [makeService()],
            isReachable: isReachable,
            manufacturer: manufacturer,
            model: model,
            serialNumber: serialNumber,
            firmwareRevision: firmwareRevision
        )
    }

    static func makeScene(
        id: String = UUID().uuidString,
        name: String = "Good Night",
        type: String = "custom",
        isExecuting: Bool = false,
        actions: [SceneActionModel] = []
    ) -> SceneModel {
        SceneModel(
            id: id,
            name: name,
            type: type,
            isExecuting: isExecuting,
            actions: actions
        )
    }

    /// Creates a temporary file URL for test persistence (auto-cleaned by OS).
    static func tempRegistryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("test-registry-\(UUID().uuidString).json")
    }
}
