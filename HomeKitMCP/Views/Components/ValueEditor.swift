import SwiftUI

struct ValueEditor: View {
    @Binding var value: String
    let characteristicType: String
    let devices: [DeviceModel]
    let deviceId: String

    private var format: String? {
        devices.first(where: { $0.id == deviceId })?
            .services.flatMap(\.characteristics)
            .first(where: { $0.type == characteristicType })?
            .format
    }

    var body: some View {
        switch format {
        case "bool":
            Toggle("Value", isOn: boolBinding)
                .tint(Theme.Tint.main)
        case "int", "uint8", "uint16", "uint32", "uint64":
            HStack {
                Text("Value")
                Spacer()
                TextField("0", text: $value)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
            }
        case "float":
            HStack {
                Text("Value")
                Spacer()
                TextField("0.0", text: $value)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
            }
        default:
            HStack {
                Text("Value")
                Spacer()
                TextField("Value", text: $value)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var boolBinding: Binding<Bool> {
        Binding(
            get: { value.lowercased() == "true" || value == "1" },
            set: { value = $0 ? "true" : "false" }
        )
    }
}
