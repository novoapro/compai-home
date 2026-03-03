import XCTest
@testable import HomeKitMCP

final class DeviceRegistryServiceTests: XCTestCase {

    private var registry: DeviceRegistryService!
    private var tempURL: URL!

    override func setUp() {
        super.setUp()
        tempURL = TestFixtures.tempRegistryURL()
        registry = DeviceRegistryService(fileURL: tempURL)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempURL)
        registry = nil
        super.tearDown()
    }

    // MARK: - Device Sync

    func testSyncDevices_newDevice_assignsStableId() async {
        let device = TestFixtures.makeDevice(id: "hk-1", name: "Lamp")
        await registry.syncDevices([device])

        let entries = await registry.allDeviceEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertTrue(entries[0].isResolved)
        XCTAssertEqual(entries[0].homeKitId, "hk-1")
        XCTAssertEqual(entries[0].name, "Lamp")
    }

    func testSyncDevices_existingDevice_preservesStableId() async {
        let device = TestFixtures.makeDevice(id: "hk-1", name: "Lamp")
        await registry.syncDevices([device])

        let firstEntries = await registry.allDeviceEntries()
        let firstStableId = firstEntries[0].stableId

        // Sync again with the same device
        await registry.syncDevices([device])

        let secondEntries = await registry.allDeviceEntries()
        XCTAssertEqual(secondEntries.count, 1)
        XCTAssertEqual(secondEntries[0].stableId, firstStableId)
    }

    func testSyncDevices_deviceRemoved_markedAsUnresolved() async {
        let device = TestFixtures.makeDevice(id: "hk-1", name: "Lamp")
        await registry.syncDevices([device])

        // Sync again without the device
        await registry.syncDevices([])

        let entries = await registry.allDeviceEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertFalse(entries[0].isResolved)
        XCTAssertNil(entries[0].homeKitId)
    }

    func testSyncDevices_rematchByHardwareKey() async {
        let device = TestFixtures.makeDevice(
            id: "hk-1", name: "Lamp",
            manufacturer: "Acme", model: "X1", serialNumber: "SN123"
        )
        await registry.syncDevices([device])

        let firstStableId = await registry.allDeviceEntries()[0].stableId

        // Device disappears then reappears with a new HomeKit UUID
        await registry.syncDevices([])
        let sameDeviceNewUUID = TestFixtures.makeDevice(
            id: "hk-NEW", name: "Lamp",
            manufacturer: "Acme", model: "X1", serialNumber: "SN123"
        )
        await registry.syncDevices([sameDeviceNewUUID])

        let entries = await registry.allDeviceEntries()
        let resolved = entries.filter { $0.isResolved }
        XCTAssertEqual(resolved.count, 1)
        XCTAssertEqual(resolved[0].stableId, firstStableId)
        XCTAssertEqual(resolved[0].homeKitId, "hk-NEW")
    }

    func testSyncDevices_multipleDevices() async {
        let devices = [
            TestFixtures.makeDevice(id: "hk-1", name: "Lamp"),
            TestFixtures.makeDevice(id: "hk-2", name: "Fan"),
        ]
        await registry.syncDevices(devices)

        let entries = await registry.allDeviceEntries()
        XCTAssertEqual(entries.count, 2)
        XCTAssertTrue(entries.allSatisfy { $0.isResolved })
    }

    // MARK: - Scene Sync

    func testSyncScenes_newScene_assignsStableId() async {
        let scene = TestFixtures.makeScene(id: "hk-scene-1", name: "Good Night")
        await registry.syncScenes([scene])

        let entries = await registry.allSceneEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertTrue(entries[0].isResolved)
        XCTAssertEqual(entries[0].homeKitId, "hk-scene-1")
    }

    func testSyncScenes_sceneRemoved_markedAsUnresolved() async {
        let scene = TestFixtures.makeScene(id: "hk-scene-1", name: "Good Night")
        await registry.syncScenes([scene])

        await registry.syncScenes([])

        let entries = await registry.allSceneEntries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertFalse(entries[0].isResolved)
    }

    // MARK: - Characteristic Settings

    func testSetCharacteristicEnabled_disableAlsoClearsObserved() async {
        let charId = "char-1"
        let char = TestFixtures.makeCharacteristic(id: charId, type: "power-state")
        let service = TestFixtures.makeService(characteristics: [char])
        let device = TestFixtures.makeDevice(id: "hk-1", services: [service])
        await registry.syncDevices([device])

        // Find the stable characteristic ID
        let entries = await registry.allDeviceEntries()
        let stableCharId = entries[0].services[0].characteristics[0].stableCharacteristicId

        // Enable observed first
        await registry.setCharacteristicObserved(stableCharId: stableCharId, observed: true)
        var settings = await registry.getCharacteristicSettings(stableCharId: stableCharId)
        XCTAssertTrue(settings?.observed ?? false)

        // Disable should also clear observed
        await registry.setCharacteristicEnabled(stableCharId: stableCharId, enabled: false)
        settings = await registry.getCharacteristicSettings(stableCharId: stableCharId)
        XCTAssertFalse(settings?.enabled ?? true)
        XCTAssertFalse(settings?.observed ?? true)
    }

    func testSetCharacteristicObserved_cannotObserveDisabled() async {
        let char = TestFixtures.makeCharacteristic(id: "char-1", type: "power-state")
        let service = TestFixtures.makeService(characteristics: [char])
        let device = TestFixtures.makeDevice(id: "hk-1", services: [service])
        await registry.syncDevices([device])

        let entries = await registry.allDeviceEntries()
        let stableCharId = entries[0].services[0].characteristics[0].stableCharacteristicId

        // Disable the characteristic
        await registry.setCharacteristicEnabled(stableCharId: stableCharId, enabled: false)

        // Try to observe — should be blocked
        await registry.setCharacteristicObserved(stableCharId: stableCharId, observed: true)

        let settings = await registry.getCharacteristicSettings(stableCharId: stableCharId)
        XCTAssertFalse(settings?.observed ?? true)
    }

    // MARK: - Nonisolated Lookups

    func testNonisolatedLookups_afterSync() async {
        let char = TestFixtures.makeCharacteristic(id: "hk-char-1", type: "power-state")
        let service = TestFixtures.makeService(id: "hk-svc-1", characteristics: [char])
        let device = TestFixtures.makeDevice(id: "hk-dev-1", services: [service])
        await registry.syncDevices([device])

        // Nonisolated lookups should work from any context
        let stableDeviceId = registry.readStableDeviceId("hk-dev-1")
        XCTAssertNotNil(stableDeviceId)

        let hkDeviceId = registry.readHomeKitDeviceId(stableDeviceId!)
        XCTAssertEqual(hkDeviceId, "hk-dev-1")

        let stableCharId = registry.readStableCharacteristicId("hk-char-1")
        XCTAssertNotNil(stableCharId)
    }

    // MARK: - Persistence

    func testPersistence_surviveReload() async throws {
        let device = TestFixtures.makeDevice(id: "hk-1", name: "Persisted Lamp")
        await registry.syncDevices([device])

        let entries = await registry.allDeviceEntries()
        let stableId = entries[0].stableId

        // Force an immediate save by calling snapshot + manual write
        let snapshot = await registry.snapshot()
        let data = try JSONEncoder.iso8601Pretty.encode(snapshot)
        try data.write(to: tempURL, options: .atomic)

        // Create a new registry from the same file
        let registry2 = DeviceRegistryService(fileURL: tempURL)
        let reloadedEntries = await registry2.allDeviceEntries()
        XCTAssertEqual(reloadedEntries.count, 1)
        XCTAssertEqual(reloadedEntries[0].stableId, stableId)
        XCTAssertEqual(reloadedEntries[0].name, "Persisted Lamp")
    }

    // MARK: - Set All Enabled/Observed

    func testSetAllEnabled_disablesAllCharacteristics() async {
        let chars = [
            TestFixtures.makeCharacteristic(id: "c1", type: "power-state"),
            TestFixtures.makeCharacteristic(id: "c2", type: "brightness"),
        ]
        let service = TestFixtures.makeService(characteristics: chars)
        let device = TestFixtures.makeDevice(id: "hk-1", services: [service])
        await registry.syncDevices([device])

        let entries = await registry.allDeviceEntries()
        let deviceStableId = entries[0].stableId

        await registry.setAllEnabled(deviceStableId: deviceStableId, enabled: false)

        let allSettings = await registry.getAllCharacteristicSettings()
        for (_, settings) in allSettings {
            XCTAssertFalse(settings.enabled)
            XCTAssertFalse(settings.observed)
        }
    }
}
