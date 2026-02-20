import SwiftUI

struct BlockEditorSection: View {
    @Binding var blocks: [BlockDraft]
    let devices: [DeviceModel]
    var allowNesting: Bool = true

    @State private var showingBlockTypePicker = false
    @State private var editingNestedContext: NestedEditContext?

    var body: some View {
        Section {
            ForEach(Array(blocks.indices), id: \.self) { index in
                BlockEditorRow(
                    block: $blocks[index],
                    devices: devices,
                    allowNesting: allowNesting,
                    onEditNestedBlocks: allowNesting ? { label, nestedBlocks in
                        editingNestedContext = NestedEditContext(
                            parentBlockIndex: index,
                            label: label,
                            blocks: nestedBlocks
                        )
                    } : nil
                )
            }
            .onDelete { blocks.remove(atOffsets: $0) }
            .onMove { blocks.move(fromOffsets: $0, toOffset: $1) }

            Button {
                showingBlockTypePicker = true
            } label: {
                Label("Add Block", systemImage: "plus.circle")
            }
            .confirmationDialog("Add Block", isPresented: $showingBlockTypePicker) {
                Group {
                    Button("Control Device") { blocks.append(.newControlDevice()) }
                    Button("Webhook") { blocks.append(.newWebhook()) }
                    Button("Log Message") { blocks.append(.newLog()) }
                    Button("Delay") { blocks.append(.newDelay()) }
                    Button("Wait for State") { blocks.append(.newWaitForState()) }
                }
                if allowNesting {
                    Group {
                        Button("If/Else") { blocks.append(.newConditional()) }
                        Button("Repeat") { blocks.append(.newRepeat()) }
                        Button("Repeat While") { blocks.append(.newRepeatWhile()) }
                        Button("Group") { blocks.append(.newGroup()) }
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
        } header: {
            HStack {
                Text("Blocks (\(blocks.count))")
                Spacer()
                EditButton()
                    .font(.caption)
            }
        }
        .listRowBackground(Theme.contentBackground)
        .sheet(item: $editingNestedContext) { context in
            NestedBlockEditorSheet(
                title: nestedSheetTitle(context: context),
                blocks: nestedBlocksBinding(context: context),
                devices: devices
            )
        }
    }

    private func nestedSheetTitle(context: NestedEditContext) -> String {
        let blockName = blocks[safe: context.parentBlockIndex]?.blockType.displayName ?? "Block"
        return "\(blockName) — \(context.label.capitalized) Blocks"
    }

    private func nestedBlocksBinding(context: NestedEditContext) -> Binding<[BlockDraft]> {
        Binding(
            get: {
                guard let block = blocks[safe: context.parentBlockIndex] else { return [] }
                return getNestedBlocks(from: block, label: context.label)
            },
            set: { newBlocks in
                guard context.parentBlockIndex < blocks.count else { return }
                setNestedBlocks(on: &blocks[context.parentBlockIndex], label: context.label, blocks: newBlocks)
            }
        )
    }

    private func getNestedBlocks(from block: BlockDraft, label: String) -> [BlockDraft] {
        switch block.blockType {
        case .conditional(let d):
            return label == "then" ? d.thenBlocks : d.elseBlocks
        case .repeatBlock(let d):
            return d.blocks
        case .repeatWhile(let d):
            return d.blocks
        case .group(let d):
            return d.blocks
        default:
            return []
        }
    }

    private func setNestedBlocks(on block: inout BlockDraft, label: String, blocks: [BlockDraft]) {
        switch block.blockType {
        case .conditional(var d):
            if label == "then" { d.thenBlocks = blocks } else { d.elseBlocks = blocks }
            block.blockType = .conditional(d)
        case .repeatBlock(var d):
            d.blocks = blocks
            block.blockType = .repeatBlock(d)
        case .repeatWhile(var d):
            d.blocks = blocks
            block.blockType = .repeatWhile(d)
        case .group(var d):
            d.blocks = blocks
            block.blockType = .group(d)
        default:
            break
        }
    }
}

// MARK: - Nested Edit Context

struct NestedEditContext: Identifiable {
    let id = UUID()
    let parentBlockIndex: Int
    let label: String
    let blocks: [BlockDraft]
}

// MARK: - Nested Block Editor Sheet

struct NestedBlockEditorSheet: View {
    let title: String
    @Binding var blocks: [BlockDraft]
    let devices: [DeviceModel]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                BlockEditorSection(blocks: $blocks, devices: devices, allowNesting: false)
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(Theme.mainBackground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
