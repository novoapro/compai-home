import SwiftUI

struct ConditionEditorSection: View {
    @Binding var conditions: [ConditionDraft]
    let devices: [DeviceModel]

    var body: some View {
        Section {
            ForEach($conditions) { $condition in
                ConditionRow(condition: $condition, devices: devices, onDelete: {
                    conditions.removeAll(where: { $0.id == condition.id })
                })
            }
            .onDelete { conditions.remove(atOffsets: $0) }

            Menu {
                Button {
                    conditions.append(.empty())
                } label: {
                    Label("Device State", systemImage: "shield.fill")
                }
                Button {
                    conditions.append(.emptySunEvent())
                } label: {
                    Label("Sunrise/Sunset", systemImage: "sunrise.fill")
                }
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
}

private struct ConditionRow: View {
    @Binding var condition: ConditionDraft
    let devices: [DeviceModel]
    let onDelete: () -> Void
    @State private var isEditingName: Bool = false

    var body: some View {
        DisclosureGroup {
            conditionContent

            HStack {
                Spacer()
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 44, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Remove Condition")
            }
        } label: {
            conditionLabel
        }
    }

    @ViewBuilder
    private var conditionContent: some View {
        switch condition.conditionDraftType {
        case .deviceState:
            DeviceCharacteristicPicker(
                devices: devices,
                selectedDeviceId: $condition.deviceId,
                selectedServiceId: $condition.serviceId,
                selectedCharacteristicType: $condition.characteristicType
            )

            ComparisonValueRow(
                comparisonType: $condition.comparisonType,
                value: $condition.comparisonValue,
                characteristicType: condition.characteristicType,
                devices: devices,
                deviceId: condition.deviceId
            )
        case .sunEvent:
            sunEventConditionContent
        }
    }

    private var sunEventConditionContent: some View {
        VStack(spacing: 12) {
            Picker("Event", selection: $condition.sunEventType) {
                ForEach(SunEventType.allCases) { eventType in
                    Text(eventType.displayName).tag(eventType)
                }
            }
            .pickerStyle(.segmented)

            Picker("Timing", selection: $condition.sunEventComparison) {
                ForEach(SunEventComparison.allCases) { comp in
                    Text(comp.displayName).tag(comp)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var conditionLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: condition.conditionDraftType.icon)
                .font(.caption)
                .foregroundColor(condition.conditionDraftType == .sunEvent ? .orange : .indigo)
            VStack(alignment: .leading, spacing: 2) {
                Text(condition.conditionDraftType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if isEditingName {
                    TextField("Name", text: $condition.name)
                        .font(.caption)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { isEditingName = false }
                } else {
                    Text(condition.name.isEmpty ? condition.autoName(devices: devices) : condition.name)
                        .font(.caption)
                        .foregroundColor(Theme.Text.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                isEditingName.toggle()
            } label: {
                Image(systemName: isEditingName ? "checkmark.circle.fill" : "pencil")
                    .font(.caption)
                    .foregroundColor(Theme.Text.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
