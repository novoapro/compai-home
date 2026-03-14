import SwiftUI

struct OrphanedDevicesView: View {
    let registryService: DeviceRegistryService
    let homeKitManager: HomeKitManager
    let automationStorageService: AutomationStorageService
    var viewModel: SettingsViewModel?

    @State private var orphanedDevices: [DeviceRegistryEntry] = []
    @State private var orphanedScenes: [SceneRegistryEntry] = []
    @State private var unresolvedServiceRefs: [DeviceRegistryService.UnresolvedServiceRef] = []
    @State private var remapServiceRef: DeviceRegistryService.UnresolvedServiceRef?
    @State private var replaceDeviceEntry: DeviceRegistryEntry?
    @State private var replaceSceneEntry: SceneRegistryEntry?
    @State private var removeDeviceEntry: DeviceRegistryEntry?
    @State private var removeSceneEntry: SceneRegistryEntry?
    @State private var affectedAutomationNames: [String] = []
    @State private var isValidating = false
    @State private var lastValidationMessage: String?
    @State private var unresolvableIssues: [AutomationMigrationService.ValidationIssue] = []
    @State private var editingAutomation: Automation?

    var body: some View {
        Form {
            if let vm = viewModel {
                DeviceRegistrySettingsSection(viewModel: vm)
            }

            if orphanedDevices.isEmpty && orphanedScenes.isEmpty && unresolvedServiceRefs.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.green)
                            Text("All Entities Resolved")
                                .font(.headline)
                                .foregroundStyle(Theme.Text.primary)
                            Text("Every device, service, and scene reference is valid.")
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

            if !unresolvedServiceRefs.isEmpty {
                Section {
                    ForEach(unresolvedServiceRefs) { ref in
                        VStack(alignment: .leading, spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ref.deviceName)
                                    .font(.body)
                                    .foregroundStyle(Theme.Text.primary)
                                HStack(spacing: 4) {
                                    Text("Automation: \(ref.automationName)")
                                    Text("in \(ref.location)")
                                }
                                .font(.caption)
                                .foregroundStyle(Theme.Text.secondary)
                                Text("Orphaned Service ID: \(ref.serviceId)")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.Text.tertiary)
                            }

                            Button {
                                remapServiceRef = ref
                            } label: {
                                Label("Remap to Service", systemImage: "arrow.triangle.swap")
                                    .font(.subheadline)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Label("Orphaned Service References (\(unresolvedServiceRefs.count))", systemImage: "exclamationmark.triangle")
                } footer: {
                    Text("These automations reference service IDs that don't exist in their device's registry entry. Remap them to an existing service or use \"Validate & Repair\" below.")
                }
            }

            Section {
                Button {
                    Task { await runValidation() }
                } label: {
                    HStack {
                        Label("Validate & Repair Automations", systemImage: "wrench.and.screwdriver")
                        if isValidating {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isValidating)
                if let message = lastValidationMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(Theme.Text.secondary)
                }
            } footer: {
                Text("Checks all automation references against the device registry and auto-repairs mismatched service IDs and characteristic type formats.")
            }

            if !unresolvableIssues.isEmpty {
                Section {
                    ForEach(unresolvableIssues) { issue in
                        Button {
                            Task {
                                if let automation = await automationStorageService.getAutomation(id: issue.automationId) {
                                    editingAutomation = automation
                                }
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(issue.automationName)
                                        .font(.body)
                                        .foregroundStyle(Theme.Text.primary)
                                    Text(issue.location)
                                        .font(.caption)
                                        .foregroundStyle(Theme.Text.secondary)
                                    Text(issue.detail)
                                        .font(.caption2)
                                        .foregroundStyle(Theme.Text.tertiary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Text.tertiary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Label("Unresolvable References (\(unresolvableIssues.count))", systemImage: "xmark.circle")
                } footer: {
                    Text("These references could not be auto-repaired. Tap a row to open the automation and fix it manually.")
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Theme.mainBackground)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 20)
        }
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
                set: { if !$0 { removeDeviceEntry = nil; affectedAutomationNames = [] } }
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
            if affectedAutomationNames.isEmpty {
                Text("Remove \"\(entry.name)\" from the registry? No automations reference this device.")
            } else {
                Text("Remove \"\(entry.name)\"? The following automations reference this device and will need to be updated:\n\n\(affectedAutomationNames.joined(separator: "\n"))")
            }
        }
        .alert(
            "Remove Scene",
            isPresented: Binding(
                get: { removeSceneEntry != nil },
                set: { if !$0 { removeSceneEntry = nil; affectedAutomationNames = [] } }
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
            if affectedAutomationNames.isEmpty {
                Text("Remove \"\(entry.name)\" from the registry? No automations reference this scene.")
            } else {
                Text("Remove \"\(entry.name)\"? The following automations reference this scene and will need to be updated:\n\n\(affectedAutomationNames.joined(separator: "\n"))")
            }
        }
        .sheet(item: $remapServiceRef) { ref in
            ReplacementServicePickerSheet(
                ref: ref,
                onSelect: { targetServiceId in
                    Task {
                        await registryService.remapService(
                            deviceStableId: ref.deviceStableId,
                            orphanedServiceId: ref.serviceId,
                            targetServiceId: targetServiceId
                        )
                        await loadOrphans()
                    }
                }
            )
        }
        .sheet(item: $editingAutomation) { automation in
            let stableDevices = registryService.stableDevices(homeKitManager.getAllDevices())
            let stableScenes = registryService.stableScenes(homeKitManager.getAllScenes())
            AutomationEditorView(
                mode: .edit(automation),
                devices: stableDevices,
                scenes: stableScenes,
                onSave: { draft in
                    Task {
                        guard let existing = await automationStorageService.getAutomation(id: automation.id) else { return }
                        let updated = draft.toAutomation(
                            devices: stableDevices,
                            existingMetadata: existing.metadata,
                            createdAt: existing.createdAt
                        )
                        await automationStorageService.updateAutomation(id: automation.id) { $0 = updated }
                        await loadOrphans()
                        unresolvableIssues = []
                    }
                }
            )
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
                    Task {
                        let automations = await automationStorageService.getAllAutomations()
                        let affected = registryService.findAutomationsReferencing(deviceStableId: entry.stableId, in: automations)
                        affectedAutomationNames = affected.map { "\($0.automationName) (\($0.locations.joined(separator: ", ")))" }
                        removeDeviceEntry = entry
                    }
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
                    Task {
                        let automations = await automationStorageService.getAllAutomations()
                        let affected = registryService.findAutomationsReferencing(sceneStableId: entry.stableId, in: automations)
                        affectedAutomationNames = affected.map { "\($0.automationName) (\($0.locations.joined(separator: ", ")))" }
                        removeSceneEntry = entry
                    }
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

        let automations = await automationStorageService.getAllAutomations()
        unresolvedServiceRefs = await registryService.unresolvedServiceReferences(in: automations)
    }

    private func runValidation() async {
        isValidating = true
        defer { isValidating = false }

        let automations = await automationStorageService.getAllAutomations()
        let validation = await AutomationMigrationService.validateAndRepairReferences(
            automations, registry: registryService
        )

        if !validation.autoFixed.isEmpty {
            await automationStorageService.replaceAll(automations: validation.updatedAutomations)
        }

        let fixedCount = validation.autoFixed.count
        let unresolvedCount = validation.unresolvable.count
        unresolvableIssues = validation.unresolvable
        if fixedCount == 0 && unresolvedCount == 0 {
            lastValidationMessage = "All automation references are valid."
        } else {
            var parts: [String] = []
            if fixedCount > 0 { parts.append("Auto-fixed \(fixedCount) issue(s).") }
            if unresolvedCount > 0 { parts.append("\(unresolvedCount) issue(s) need manual reconfiguration — see list below.") }
            lastValidationMessage = parts.joined(separator: " ")
        }

        await loadOrphans()
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

extension DeviceRegistryEntry: Identifiable {
    var id: String { stableId }
}

extension SceneRegistryEntry: Identifiable {
    var id: String { stableId }
}

// MARK: - Device Registry Settings Section

private struct DeviceRegistrySettingsSection: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section {
            Toggle("Hide Room Name in Device Names", isOn: $viewModel.hideRoomNameInTheApp)

            Toggle("Use Service Type as Service Name", isOn: $viewModel.useServiceTypeAsName)
        } header: {
            Label("Display", systemImage: "paintbrush")
        } footer: {
            Text("\"Hide Room Name\" strips the room prefix from device names (e.g. \"Bedroom Light\" becomes \"Light\"). \"Use Service Type as Name\" replaces each service's default name with its generic type (e.g. \"Lightbulb\", \"Switch\"). Per-service custom names take precedence over both settings.")
        }

        Section {
            Toggle("Enable State Polling", isOn: $viewModel.pollingEnabled)

            Picker("Polling Interval", selection: $viewModel.pollingInterval) {
                Text("10 seconds").tag(10)
                Text("15 seconds").tag(15)
                Text("30 seconds").tag(30)
                Text("60 seconds").tag(60)
                Text("120 seconds").tag(120)
                Text("300 seconds").tag(300)
            }
            .disabled(!viewModel.pollingEnabled)
            .opacity(viewModel.pollingEnabled ? 1 : 0.5)
        } header: {
            Label("Device State Polling", systemImage: "arrow.triangle.2.circlepath")
        } footer: {
            Text("Periodically reads device states from HomeKit to detect missed callbacks. Logs corrections when actual state differs from cached state.")
        }
    }
}

#Preview {
    NavigationStack {
        OrphanedDevicesView(
            registryService: DeviceRegistryService(),
            homeKitManager: PreviewData.previewHomeKitManager,
            automationStorageService: PreviewData.previewAutomationStorageService
        )
    }
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

// MARK: - Replacement Service Picker Sheet

private struct ReplacementServicePickerSheet: View {
    let ref: DeviceRegistryService.UnresolvedServiceRef
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Remap Orphaned Service")
                                .font(.subheadline.bold())
                        }
                        Text("Device: \(ref.deviceName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Orphaned ID: \(ref.serviceId)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text("Referenced in: \(ref.automationName) — \(ref.location)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Section("Available Services") {
                    if ref.availableServices.isEmpty {
                        Text("No services available on this device.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(ref.availableServices, id: \.stableServiceId) { service in
                            Button {
                                onSelect(service.stableServiceId)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(service.customName ?? service.serviceType)
                                            .font(.body)
                                            .foregroundColor(Theme.Text.primary)
                                        HStack(spacing: 8) {
                                            Text(service.serviceType)
                                                .font(.caption)
                                            Text("\(service.characteristics.count) characteristic\(service.characteristics.count == 1 ? "" : "s")")
                                                .font(.caption)
                                        }
                                        .foregroundStyle(Theme.Text.secondary)
                                        Text(service.stableServiceId)
                                            .font(.caption2)
                                            .foregroundStyle(Theme.Text.tertiary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Theme.Text.tertiary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
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
