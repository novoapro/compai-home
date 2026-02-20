import SwiftUI

struct WorkflowEditorView: View {
    enum Mode {
        case create
        case edit(Workflow)

        var isCreate: Bool {
            if case .create = self { return true }
            return false
        }
    }

    let mode: Mode
    let devices: [DeviceModel]
    let onSave: (WorkflowDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: WorkflowDraft
    @State private var showingDiscardAlert = false
    @State private var showingValidationAlert = false
    @State private var validationErrors: [String] = []

    init(mode: Mode, devices: [DeviceModel], onSave: @escaping (WorkflowDraft) -> Void) {
        self.mode = mode
        self.devices = devices
        self.onSave = onSave
        switch mode {
        case .create:
            _draft = State(initialValue: .empty())
        case .edit(let workflow):
            _draft = State(initialValue: WorkflowDraft(from: workflow))
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                TriggerEditorSection(triggers: $draft.triggers, devices: devices)
                ConditionEditorSection(conditions: $draft.conditions, devices: devices)
                BlockEditorSection(blocks: $draft.blocks, devices: devices)
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(Theme.mainBackground)
            .navigationTitle(mode.isCreate ? "New Workflow" : "Edit Workflow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingDiscardAlert = true
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("Your unsaved changes will be lost.")
            }
            .alert("Cannot Save", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationErrors.joined(separator: "\n"))
            }
        }
    }

    private var detailsSection: some View {
        Section {
            TextField("Workflow Name", text: $draft.name)
            TextField("Description (optional)", text: $draft.description)
            Toggle("Enabled", isOn: $draft.isEnabled)
                .tint(Theme.Tint.main)
            Toggle("Continue on Error", isOn: $draft.continueOnError)
                .tint(Theme.Tint.main)
        } header: {
            Text("Details")
        }
        .listRowBackground(Theme.contentBackground)
    }

    private func save() {
        let validation = draft.validate()
        if validation.isValid {
            onSave(draft)
            dismiss()
        } else {
            validationErrors = validation.errors
            showingValidationAlert = true
        }
    }
}
