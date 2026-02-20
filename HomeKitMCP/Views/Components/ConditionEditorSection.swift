import SwiftUI

struct ConditionEditorSection: View {
    @Binding var conditions: [ConditionDraft]
    let devices: [DeviceModel]

    var body: some View {
        Section {
            ForEach(Array(conditions.indices), id: \.self) { index in
                conditionRow(index: index)
            }
            .onDelete { conditions.remove(atOffsets: $0) }

            Button {
                conditions.append(.empty())
            } label: {
                Label("Add Condition", systemImage: "plus.circle")
            }
        } header: {
            Text("Guard Conditions (\(conditions.count))")
        } footer: {
            Text("All conditions must be true for the workflow to proceed. Leave empty to always proceed.")
        }
        .listRowBackground(Theme.contentBackground)
    }

    private func conditionRow(index: Int) -> some View {
        DisclosureGroup {
            DeviceCharacteristicPicker(
                devices: devices,
                selectedDeviceId: $conditions[index].deviceId,
                selectedServiceId: $conditions[index].serviceId,
                selectedCharacteristicType: $conditions[index].characteristicType
            )

            Picker("Comparison", selection: $conditions[index].comparisonType) {
                ForEach(ComparisonType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }

            ValueEditor(
                value: $conditions[index].comparisonValue,
                characteristicType: conditions[index].characteristicType,
                devices: devices,
                deviceId: conditions[index].deviceId
            )

            Button(role: .destructive) {
                conditions.remove(at: index)
            } label: {
                Label("Remove Condition", systemImage: "trash")
                    .font(.subheadline)
            }
        } label: {
            conditionLabel(conditions[index])
        }
    }

    private func conditionLabel(_ condition: ConditionDraft) -> some View {
        HStack {
            Image(systemName: "shield.fill")
                .font(.caption)
                .foregroundColor(.indigo)
            if condition.deviceId.isEmpty {
                Text("New Condition")
                    .foregroundColor(Theme.Text.secondary)
            } else {
                let deviceName = devices.first(where: { $0.id == condition.deviceId })?.name ?? "Unknown"
                let charName = condition.characteristicType.isEmpty ? "..." : CharacteristicTypes.displayName(for: condition.characteristicType)
                Text("\(deviceName) › \(charName)")
                    .lineLimit(1)
            }
        }
    }
}
