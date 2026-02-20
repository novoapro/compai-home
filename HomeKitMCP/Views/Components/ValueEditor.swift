import SwiftUI

struct ValueEditor: View {
    @Binding var value: String
    let characteristicType: String
    let devices: [DeviceModel]
    let deviceId: String

    private var characteristic: CharacteristicModel? {
        devices.first(where: { $0.id == deviceId })?
            .services.flatMap(\.characteristics)
            .first(where: { $0.type == characteristicType })
    }

    private var format: String? { characteristic?.format }

    var body: some View {
        switch format {
        case "bool":
            Toggle("Value", isOn: boolBinding)
                .tint(Theme.Tint.main)
        case "uint8", "int", "uint16", "uint32", "uint64", "float":
            if let minVal = characteristic?.minValue, let maxVal = characteristic?.maxValue, minVal < maxVal {
                sliderEditor(min: minVal, max: maxVal, step: characteristic?.stepValue ?? 1)
            } else {
                numericTextField(isDecimal: format == "float")
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

    private func sliderEditor(min: Double, max: Double, step: Double) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text("Value")
                Spacer()
                Text(sliderDisplayValue(min: min, max: max))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Theme.Text.secondary)
            }
            Slider(
                value: sliderBinding(min: min, max: max),
                in: min...max,
                step: step
            )
            .tint(Theme.Tint.main)
        }
    }

    private func numericTextField(isDecimal: Bool) -> some View {
        HStack {
            Text("Value")
            Spacer()
            TextField(isDecimal ? "0.0" : "0", text: $value)
                .keyboardType(isDecimal ? .decimalPad : .numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func sliderDisplayValue(min: Double, max: Double) -> String {
        let numVal = Double(value) ?? min
        if max == 100 && min == 0 {
            return "\(Int(numVal))%"
        }
        if numVal == numVal.rounded() {
            return "\(Int(numVal))"
        }
        return String(format: "%.1f", numVal)
    }

    private func sliderBinding(min: Double, max: Double) -> Binding<Double> {
        Binding(
            get: { Double(value) ?? min },
            set: { newVal in
                if newVal == newVal.rounded() {
                    value = "\(Int(newVal))"
                } else {
                    value = String(format: "%.1f", newVal)
                }
            }
        )
    }

    private var boolBinding: Binding<Bool> {
        Binding(
            get: { value.lowercased() == "true" || value == "1" },
            set: { value = $0 ? "true" : "false" }
        )
    }
}
