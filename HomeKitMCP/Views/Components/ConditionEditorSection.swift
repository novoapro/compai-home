import SwiftUI

struct ConditionEditorSection: View {
    @Binding var conditions: [ConditionDraft]
    let devices: [DeviceModel]

    var body: some View {
        Section {
            ForEach($conditions) { $condition in
                conditionRow(condition: $condition)
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

    private func conditionRow(condition: Binding<ConditionDraft>) -> some View {
        DisclosureGroup {
            TextField("Custom Name (optional)", text: condition.name)

            DeviceCharacteristicPicker(
                devices: devices,
                selectedDeviceId: condition.deviceId,
                selectedServiceId: condition.serviceId,
                selectedCharacteristicType: condition.characteristicType
            )

            Picker("Comparison", selection: condition.comparisonType) {
                ForEach(ComparisonType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }

            ValueEditor(
                value: condition.comparisonValue,
                characteristicType: condition.wrappedValue.characteristicType,
                devices: devices,
                deviceId: condition.wrappedValue.deviceId
            )

            Button(role: .destructive) {
                conditions.removeAll(where: { $0.id == condition.wrappedValue.id })
            } label: {
                Label("Remove Condition", systemImage: "trash")
                    .font(.subheadline)
            }
        } label: {
            conditionLabel(condition.wrappedValue)
        }
    }

    private func conditionLabel(_ condition: ConditionDraft) -> some View {
        HStack {
            Image(systemName: "shield.fill")
                .font(.caption)
                .foregroundColor(.indigo)
            Text(condition.name.isEmpty ? condition.autoName(devices: devices) : condition.name)
                .lineLimit(1)
        }
    }
}
