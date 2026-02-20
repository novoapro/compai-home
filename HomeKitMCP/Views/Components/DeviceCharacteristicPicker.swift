import SwiftUI

struct DeviceCharacteristicPicker: View {
    let devices: [DeviceModel]
    @Binding var selectedDeviceId: String
    @Binding var selectedServiceId: String?
    @Binding var selectedCharacteristicType: String

    var body: some View {
        Picker("Device", selection: $selectedDeviceId) {
            Text("Select device...").tag("")
            ForEach(devices) { device in
                Text(deviceLabel(device)).tag(device.id)
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

    private func deviceLabel(_ device: DeviceModel) -> String {
        if let room = device.roomName {
            return "\(room) › \(device.name)"
        }
        return device.name
    }

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
