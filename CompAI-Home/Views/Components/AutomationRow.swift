import SwiftUI

struct AutomationRow: View {
    let automation: Automation
    let recentLogs: [AutomationExecutionLog]
    let onToggle: () -> Void
    var onClone: (() -> Void)?
    var hasOrphanedReferences: Bool = false

    @State private var isEnabled: Bool = false
    @State private var isHovered = false

    private var statusColor: Color {
        guard automation.isEnabled else { return Theme.Status.inactive }
        if automation.metadata.consecutiveFailures > 0 { return Theme.Status.error }
        if automation.metadata.totalExecutions > 0 { return Theme.Status.active }
        return Theme.Tint.main
    }

    private var lastStatus: ExecutionStatus? {
        recentLogs.first?.status
    }

    /// Icon and color based on primary trigger type
    private var triggerIcon: String {
        guard let firstTrigger = automation.triggers.first else { return "bolt.fill" }
        switch firstTrigger {
        case .deviceStateChange: return "bolt.fill"
        case .schedule: return "clock.fill"
        case .webhook: return "arrow.down.circle.fill"
        case .automation: return "arrow.triangle.turn.up.right.diamond"
        case .sunEvent: return "sunrise.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Circular trigger-type icon (36x36, matching Home app style)
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: triggerIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(statusColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(automation.name)
                        .font(.headline)
                        .foregroundColor(Theme.Text.primary)

                    if !automation.isEnabled {
                        Text("Disabled")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .foregroundColor(Theme.Text.secondary)
                            .cornerRadius(4)
                    }

                    if hasOrphanedReferences {
                        HStack(spacing: 3) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                            Text("Refs")
                                .font(.footnote)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                    }
                }

                HStack(spacing: 8) {
                    // Trigger type pill
                    if let firstTrigger = automation.triggers.first {
                        Text(triggerTypeLabel(firstTrigger))
                            .font(.footnote)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(statusColor.opacity(0.1))
                            .foregroundColor(statusColor)
                            .cornerRadius(4)
                    }

                    // Trigger count
                    Label("\(automation.triggers.count)", systemImage: "bolt.fill")
                        .font(.footnote)
                        .foregroundColor(Theme.Text.secondary)

                    // Block count
                    Label("\(automation.blocks.count)", systemImage: "list.number")
                        .font(.footnote)
                        .foregroundColor(Theme.Text.secondary)

                    // Execution count
                    if automation.metadata.totalExecutions > 0 {
                        Label("\(automation.metadata.totalExecutions)", systemImage: "play.circle")
                            .font(.footnote)
                            .foregroundColor(Theme.Text.secondary)
                    }
                }

                if let description = automation.description, !description.isEmpty {
                    Text(description)
                        .font(.footnote)
                        .foregroundColor(Theme.Text.secondary)
                        .lineLimit(1)
                }

                if let lastTriggered = automation.metadata.lastTriggeredAt {
                    Text("Last triggered \(lastTriggered, style: .relative) ago")
                        .font(.footnote)
                        .foregroundColor(Theme.Text.tertiary)
                }
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(Theme.Tint.main)
                .onChange(of: isEnabled) { newValue in
                    if newValue != automation.isEnabled {
                        onToggle()
                    }
                }
        }
        .padding(.vertical, 8)
        .onAppear { isEnabled = automation.isEnabled }
        .onChange(of: automation.isEnabled) { newValue in
            isEnabled = newValue
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            if let onClone {
                Button {
                    onClone()
                } label: {
                    Label("Duplicate Automation", systemImage: "doc.on.doc")
                }
            }

            Button {
                onToggle()
            } label: {
                Label(automation.isEnabled ? "Disable" : "Enable",
                      systemImage: automation.isEnabled ? "pause.circle" : "play.circle")
            }
        }
    }

    private func triggerTypeLabel(_ trigger: AutomationTrigger) -> String {
        switch trigger {
        case .deviceStateChange: return "Device"
        case .schedule: return "Schedule"
        case .webhook: return "Webhook"
        case .automation: return "Automation"
        case .sunEvent: return "Sun Event"
        }
    }
}

#Preview {
    List {
        AutomationRow(
            automation: PreviewData.sampleAutomations[0],
            recentLogs: Array(PreviewData.sampleAutomationLogs.prefix(1)),
            onToggle: { }
        )
        .listRowBackground(Theme.contentBackground)

        AutomationRow(
            automation: PreviewData.sampleAutomations[1],
            recentLogs: [],
            onToggle: { }
        )
        .listRowBackground(Theme.contentBackground)
    }
    .listStyle(.plain)
}
