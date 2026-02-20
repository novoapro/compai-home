import SwiftUI

struct DeviceCharacteristicPicker: View {
    let devices: [DeviceModel]
    @Binding var selectedDeviceId: String
    @Binding var selectedServiceId: String?
    @Binding var selectedCharacteristicType: String

    var body: some View {
        Picker("Device", selection: $selectedDeviceId) {
            Text("Select device...").tag("")
            ForEach(devicesByRoom, id: \.roomName) { group in
                Section(group.roomName) {
                    ForEach(group.devices) { device in
                        Label {
                            if device.isReachable {
                                Text(device.name)
                            } else {
                                Text("\(device.name) (Offline)")
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: categoryIcon(for: device.categoryType))
                        }
                        .tag(device.id)
                    }
                }
            }
        }
        .onChange(of: selectedDeviceId) { _ in
            // Reset characteristic when device changes
            selectedCharacteristicType = ""
            selectedServiceId = nil
        }

        if let device = devices.first(where: { $0.id == selectedDeviceId }) {
            let characteristics = flattenedCharacteristics(for: device)
            Picker("Characteristic", selection: $selectedCharacteristicType) {
                Text("Select characteristic...").tag("")
                ForEach(characteristics, id: \.characteristic.type) { item in
                    Text("\(item.serviceName) › \(CharacteristicTypes.displayName(for: item.characteristic.type))")
                        .tag(item.characteristic.type)
                }
            }
            .onChange(of: selectedCharacteristicType) { newType in
                if let match = characteristics.first(where: { $0.characteristic.type == newType }) {
                    selectedServiceId = match.serviceId
                }
            }
        }
    }

    // MARK: - Device Grouping

    private struct DeviceGroup {
        let roomName: String
        let devices: [DeviceModel]
    }

    private var devicesByRoom: [DeviceGroup] {
        let grouped = Dictionary(grouping: devices) { $0.roomName ?? "No Room" }
        return grouped
            .sorted { $0.key < $1.key }
            .map { DeviceGroup(roomName: $0.key, devices: $0.value.sorted { $0.name < $1.name }) }
    }

    // MARK: - Category Icons

    private func categoryIcon(for categoryType: String) -> String {
        switch categoryType.lowercased() {
        case "lightbulb":
            return "lightbulb.fill"
        case "switch", "outlet":
            return "switch.2"
        case "thermostat":
            return "thermometer"
        case "sensor":
            return "sensor.fill"
        case "fan":
            return "fan.fill"
        case "lock", "lock-mechanism":
            return "lock.fill"
        case "garage-door-opener":
            return "door.garage.closed"
        case "door":
            return "door.left.hand.closed"
        case "window":
            return "window.vertical.closed"
        case "window-covering":
            return "blinds.vertical.closed"
        case "security-system":
            return "shield.fill"
        case "camera", "ip-camera", "video-doorbell":
            return "camera.fill"
        case "air-purifier":
            return "aqi.medium"
        case "humidifier-dehumidifier":
            return "humidity.fill"
        case "sprinkler":
            return "sprinkler.and.droplets.fill"
        case "programmable-switch":
            return "button.programmable"
        default:
            return "house.fill"
        }
    }

    // MARK: - Characteristic Helpers

    private struct CharacteristicItem {
        let serviceId: String
        let serviceName: String
        let characteristic: CharacteristicModel
    }

    private func flattenedCharacteristics(for device: DeviceModel) -> [CharacteristicItem] {
        device.services.flatMap { service in
            service.characteristics.map { characteristic in
                CharacteristicItem(
                    serviceId: service.id,
                    serviceName: service.displayName,
                    characteristic: characteristic
                )
            }
        }
    }
}
