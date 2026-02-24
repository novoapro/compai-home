import SwiftUI

struct OrphanedDevicesView: View {
    let registryService: DeviceRegistryService
    let homeKitManager: HomeKitManager

    @State private var orphanedDevices: [DeviceRegistryEntry] = []
    @State private var orphanedScenes: [SceneRegistryEntry] = []
    @State private var replaceDeviceEntry: DeviceRegistryEntry?
    @State private var replaceSceneEntry: SceneRegistryEntry?
    @State private var removeDeviceEntry: DeviceRegistryEntry?
    @State private var removeSceneEntry: SceneRegistryEntry?

    var body: some View {
        Form {
            if orphanedDevices.isEmpty && orphanedScenes.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.green)
                            Text("All Devices Resolved")
                                .font(.headline)
                                .foregroundStyle(Theme.Text.primary)
                            Text("Every registry entry is mapped to a HomeKit device.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.Text.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 20)
                        Spacer()
                    }
                }
            }

            if !orphanedDevices.isEmpty {
                Section {
                    ForEach(orphanedDevices, id: \.stableId) { entry in
                        orphanedDeviceRow(entry)
                    }
                } header: {
                    Label("Orphaned Devices (\(orphanedDevices.count))", systemImage: "exclamationmark.triangle")
                } footer: {
                    Text("These devices were previously registered but can no longer be found in HomeKit. Replace them with a current device or remove them from the registry.")
                }
            }

            if !orphanedScenes.isEmpty {
                Section {
                    ForEach(orphanedScenes, id: \.stableId) { entry in
                        orphanedSceneRow(entry)
                    }
                } header: {
                    Label("Orphaned Scenes (\(orphanedScenes.count))", systemImage: "exclamationmark.triangle")
                } footer: {
                    Text("These scenes were previously registered but can no longer be found in HomeKit.")
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Theme.mainBackground)
        .navigationTitle("Device Registry")
        .task { await loadOrphans() }
        .sheet(item: $replaceDeviceEntry) { entry in
            ReplacementDevicePickerSheet(
                orphanedEntry: entry,
                devices: homeKitManager.getAllDevices()
            ) { selectedDevice in
                Task {
                    await registryService.remapDevice(stableId: entry.stableId, to: selectedDevice)
                    await loadOrphans()
                }
            }
        }
        .sheet(item: $replaceSceneEntry) { entry in
            ReplacementScenePickerSheet(
                orphanedEntry: entry,
                scenes: homeKitManager.getAllScenes()
            ) { selectedScene in
                Task {
                    await registryService.remapScene(stableId: entry.stableId, to: selectedScene)
                    await loadOrphans()
                }
            }
        }
        .alert(
            "Remove Device",
            isPresented: Binding(
                get: { removeDeviceEntry != nil },
                set: { if !$0 { removeDeviceEntry = nil } }
            ),
            presenting: removeDeviceEntry
        ) { entry in
            Button("Remove", role: .destructive) {
                Task {
                    await registryService.removeDevice(stableId: entry.stableId)
                    await loadOrphans()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { entry in
            Text("Remove \"\(entry.name)\" from the registry? Any workflows referencing this device will no longer resolve.")
        }
        .alert(
            "Remove Scene",
            isPresented: Binding(
                get: { removeSceneEntry != nil },
                set: { if !$0 { removeSceneEntry = nil } }
            ),
            presenting: removeSceneEntry
        ) { entry in
            Button("Remove", role: .destructive) {
                Task {
                    await registryService.removeScene(stableId: entry.stableId)
                    await loadOrphans()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { entry in
            Text("Remove \"\(entry.name)\" from the registry? Any workflows referencing this scene will no longer resolve.")
        }
    }

    // MARK: - Rows

    private func orphanedDeviceRow(_ entry: DeviceRegistryEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: categoryIcon(for: entry.categoryType))
                    .foregroundStyle(.orange)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(.body)
                        .foregroundStyle(Theme.Text.primary)

                    HStack(spacing: 8) {
                        if let room = entry.roomName {
                            Label(room, systemImage: "location")
                        }
                        Label("\(entry.services.count) service\(entry.services.count == 1 ? "" : "s")", systemImage: "square.stack.3d.up")
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.Text.secondary)
                }

                Spacer()
            }

            if let hwKey = entry.hardwareKey {
                Text(hwKey)
                    .font(.caption2)
                    .foregroundStyle(Theme.Text.tertiary)
                    .lineLimit(1)
            }

            HStack(spacing: 12) {
                Button {
                    replaceDeviceEntry = entry
                } label: {
                    Label("Replace", systemImage: "arrow.triangle.swap")
                        .font(.subheadline)
                }
                .buttonStyle(.borderless)

                Button(role: .destructive) {
                    removeDeviceEntry = entry
                } label: {
                    Label("Remove", systemImage: "trash")
                        .font(.subheadline)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }

    private func orphanedSceneRow(_ entry: SceneRegistryEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "play.rectangle.fill")
                    .foregroundStyle(.orange)
                    .frame(width: 20)

                Text(entry.name)
                    .font(.body)
                    .foregroundStyle(Theme.Text.primary)

                Spacer()
            }

            HStack(spacing: 12) {
                Button {
                    replaceSceneEntry = entry
                } label: {
                    Label("Replace", systemImage: "arrow.triangle.swap")
                        .font(.subheadline)
                }
                .buttonStyle(.borderless)

                Button(role: .destructive) {
                    removeSceneEntry = entry
                } label: {
                    Label("Remove", systemImage: "trash")
                        .font(.subheadline)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func loadOrphans() async {
        orphanedDevices = await registryService.unresolvedDevices()
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        orphanedScenes = await registryService.unresolvedScenes()
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func categoryIcon(for categoryType: String) -> String {
        switch categoryType.lowercased() {
        case "lightbulb": return "lightbulb.fill"
        case "switch", "outlet": return "switch.2"
        case "thermostat": return "thermometer"
        case "sensor": return "sensor.fill"
        case "fan": return "fan.fill"
        case "lock", "lock-mechanism": return "lock.fill"
        case "garage-door-opener": return "door.garage.closed"
        case "door": return "door.left.hand.closed"
        case "window": return "window.vertical.closed"
        case "window-covering": return "blinds.vertical.closed"
        case "security-system": return "shield.fill"
        case "camera", "ip-camera", "video-doorbell": return "camera.fill"
        case "air-purifier": return "aqi.medium"
        case "humidifier-dehumidifier": return "humidity.fill"
        case "sprinkler": return "sprinkler.and.droplets.fill"
        case "programmable-switch": return "button.programmable"
        default: return "house.fill"
        }
    }
}

// MARK: - Identifiable Conformances

extension DeviceRegistryEntry: @retroactive Identifiable {
    var id: String { stableId }
}

extension SceneRegistryEntry: @retroactive Identifiable {
    var id: String { stableId }
}

// MARK: - Replacement Device Picker Sheet

private struct ReplacementDevicePickerSheet: View {
    let orphanedEntry: DeviceRegistryEntry
    let devices: [DeviceModel]
    let onSelect: (DeviceModel) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private struct DeviceGroup: Identifiable {
        let roomName: String
        var id: String { roomName }
        let devices: [DeviceModel]
    }

    private var filteredDevicesByRoom: [DeviceGroup] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let filtered: [DeviceModel]
        if query.isEmpty {
            filtered = devices
        } else {
            filtered = devices.filter {
                $0.name.lowercased().contains(query) ||
                ($0.roomName ?? "").lowercased().contains(query)
            }
        }
        let grouped = Dictionary(grouping: filtered) { $0.roomName ?? "No Room" }
        return grouped
            .sorted { $0.key < $1.key }
            .map { DeviceGroup(roomName: $0.key, devices: $0.value.sorted { $0.name < $1.name }) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Replacing: \(orphanedEntry.name)")
                                .font(.subheadline.bold())
                            if let room = orphanedEntry.roomName {
                                Text(room)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                ForEach(filteredDevicesByRoom) { group in
                    Section(group.roomName) {
                        ForEach(group.devices) { device in
                            Button {
                                onSelect(device)
                                dismiss()
                            } label: {
                                HStack {
                                    Label {
                                        Text(device.name)
                                            .foregroundColor(Theme.Text.primary)
                                    } icon: {
                                        Image(systemName: categoryIcon(for: device.categoryType))
                                    }
                                    Spacer()
                                    if !device.isReachable {
                                        Text("Offline")
                                            .font(.footnote)
                                            .foregroundColor(Theme.Text.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search devices")
            .navigationTitle("Select Replacement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func categoryIcon(for categoryType: String) -> String {
        switch categoryType.lowercased() {
        case "lightbulb": return "lightbulb.fill"
        case "switch", "outlet": return "switch.2"
        case "thermostat": return "thermometer"
        case "sensor": return "sensor.fill"
        case "fan": return "fan.fill"
        case "lock", "lock-mechanism": return "lock.fill"
        case "garage-door-opener": return "door.garage.closed"
        case "door": return "door.left.hand.closed"
        case "window": return "window.vertical.closed"
        case "window-covering": return "blinds.vertical.closed"
        case "security-system": return "shield.fill"
        case "camera", "ip-camera", "video-doorbell": return "camera.fill"
        case "air-purifier": return "aqi.medium"
        case "humidifier-dehumidifier": return "humidity.fill"
        case "sprinkler": return "sprinkler.and.droplets.fill"
        case "programmable-switch": return "button.programmable"
        default: return "house.fill"
        }
    }
}

// MARK: - Replacement Scene Picker Sheet

private struct ReplacementScenePickerSheet: View {
    let orphanedEntry: SceneRegistryEntry
    let scenes: [SceneModel]
    let onSelect: (SceneModel) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredScenes: [SceneModel] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if query.isEmpty {
            return scenes.sorted { $0.name < $1.name }
        }
        return scenes.filter { $0.name.lowercased().contains(query) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Replacing: \(orphanedEntry.name)")
                            .font(.subheadline.bold())
                    }
                }

                Section("Available Scenes") {
                    ForEach(filteredScenes) { scene in
                        Button {
                            onSelect(scene)
                            dismiss()
                        } label: {
                            Label {
                                Text(scene.name)
                                    .foregroundColor(Theme.Text.primary)
                            } icon: {
                                Image(systemName: "play.rectangle.fill")
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search scenes")
            .navigationTitle("Select Replacement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
