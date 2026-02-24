import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Toggle("Hide Room Name in App", isOn: $viewModel.hideRoomNameInTheApp)
            } header: {
                Label("Display", systemImage: "paintbrush")
            }

            Section {
                Toggle("Device State Change Logs", isOn: $viewModel.deviceStateLoggingEnabled)
                Toggle("Detailed Logs", isOn: $viewModel.detailedLogsEnabled)
            } header: {
                Label("Logging", systemImage: "doc.text")
            } footer: {
                Text("Device state change logs record every HomeKit device update. Detailed logs capture full request and response data for MCP, REST, and webhook entries.")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Theme.mainBackground)
        .navigationTitle("General")
    }
}

#Preview {
    NavigationStack {
        GeneralSettingsView(viewModel: PreviewData.settingsViewModel)
    }
}
