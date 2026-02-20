import SwiftUI

struct LogRow: View {
    let log: StateChangeLog
    let detailedLogsEnabled: Bool

    @State private var isExpanded = false

    /// Height of the two-line collapsed content (headline + subheadline)
    private let collapsedHeight: CGFloat = 40

    private var isError: Bool {
        log.category == .webhookError || log.category == .serverError
    }

    private var isMCP: Bool {
        log.category == .mcpCall
    }

    private var isREST: Bool {
        log.category == .restCall
    }

    private var isWebhookCall: Bool {
        log.category == .webhookCall
    }

    private var hasDetailedData: Bool {
        log.detailedRequestBody != nil || log.detailedResponseBody != nil
    }

    /// Tint color for the log category.
    private var categoryColor: Color {
        if isError { return Theme.Status.error }
        if isMCP { return .teal }
        if isREST { return .indigo }
        if isWebhookCall { return Theme.Tint.secondary }
        return Theme.Text.primary
    }

    var body: some View {
        HStack(alignment: isExpanded ? .firstTextBaseline : .center, spacing: 8) {
            // Column 1: Icon indicator
            categoryIcon
                .frame(width: 16)

            // Column 2: Header row + subheader and content rows
            VStack(alignment: .leading, spacing: 4) {
                // Header row: device name + service badge
                HStack(alignment: .center, spacing: 8) {
                    Text(log.deviceName)
                        .font(.headline)
                        .foregroundColor(categoryColor)

                    if let serviceName = log.serviceName, !isMCP && !isREST {
                        Text(serviceName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.Tint.main.opacity(0.1))
                            .foregroundColor(Theme.Tint.main)
                            .cornerRadius(4)
                    }

                    Spacer()
                }

                // Subheader and content rows
                contentSection

                // Expandable detail section
                if detailedLogsEnabled && hasDetailedData && isExpanded {
                    detailSection
                }
            }

            // Column 3: Time of execution
            Text(log.timestamp, style: .time)
                .font(.caption)
                .foregroundColor(Theme.Text.secondary)
                .frame(minWidth: 50)

            // Column 4: Chevron
            if detailedLogsEnabled && hasDetailedData {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(.systemGray2))
                    .frame(width: 16)
            } else {
                Color.clear
                    .frame(width: 16, height: 1)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if detailedLogsEnabled && hasDetailedData {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
        }
    }

    @ViewBuilder
    private var categoryIcon: some View {
        switch log.category {
        case .webhookError, .serverError:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
                .foregroundColor(Theme.Status.error)
        case .mcpCall:
            Image(systemName: "arrow.left.arrow.right.circle.fill")
                .font(.caption)
                .foregroundColor(.teal)
        case .restCall:
            Image(systemName: "link.circle.fill")
                .font(.caption)
                .foregroundColor(.indigo)
        case .webhookCall:
            Image(systemName: "paperplane.circle.fill")
                .font(.caption)
                .foregroundColor(Theme.Tint.secondary)
        case .stateChange:
            Image(systemName: "bolt.circle.fill")
                .font(.caption)
                .foregroundColor(Theme.Tint.main)
        case .workflowExecution:
            Image(systemName: "bolt.circle.fill")
                .font(.caption)
                .foregroundColor(Theme.Status.active)
        case .workflowError:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
                .foregroundColor(Theme.Status.error)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentSection: some View {
        switch log.category {
        case .mcpCall:
            mcpContent
        case .restCall:
            restContent
        case .webhookCall:
            webhookContent
        case .webhookError, .serverError:
            errorContent
        case .stateChange:
            stateChangeContent
        case .workflowExecution:
            workflowContent
        case .workflowError:
            workflowContent
        }
    }

    private var mcpContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let requestBody = log.requestBody {
                Text("→ \(requestBody)")
                    .font(.caption)
                    .foregroundColor(Theme.Text.secondary)
                    .lineLimit(2)
            }
            if let responseBody = log.responseBody {
                Text("← \(responseBody)")
                    .font(.caption)
                    .foregroundColor(Theme.Text.secondary)
                    .lineLimit(2)
            }
        }
    }

    private var restContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(log.characteristicType)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.indigo)

            if let responseBody = log.responseBody {
                Text("← \(responseBody)")
                    .font(.caption)
                    .foregroundColor(Theme.Text.secondary)
                    .lineLimit(2)
            }
        }
    }

    private var webhookContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let requestBody = log.requestBody {
                Text(requestBody)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.Tint.secondary)
            }
            if let responseBody = log.responseBody {
                Text("← \(responseBody)")
                    .font(.caption)
                    .foregroundColor(Theme.Text.secondary)
            }
        }
    }

    private var errorContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(log.category == .serverError ? "Server Error" : "Webhook Error")
                    .font(.subheadline)
                    .foregroundColor(Theme.Status.error)
                Spacer()
            }
            if let errorDetails = log.errorDetails {
                Text(errorDetails)
                    .font(.caption)
                    .foregroundColor(Theme.Status.error)
                    .lineLimit(3)
            }
        }
    }

    private var isWorkflowError: Bool {
        log.category == .workflowError
    }

    private var workflowContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let requestBody = log.requestBody {
                Text(requestBody)
                    .font(.caption)
                    .foregroundColor(isWorkflowError ? Theme.Status.error : Theme.Text.secondary)
            }
            if let responseBody = log.responseBody {
                Text(responseBody)
                    .font(.system(.caption2, design: .monospaced))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var stateChangeContent: some View {
        HStack(spacing: 4) {
            Text(CharacteristicTypes.displayName(for: log.characteristicType))
                .font(.subheadline)
                .foregroundColor(Theme.Text.secondary)
            if let oldValue = log.oldValue {
                Text(CharacteristicTypes.formatValue(oldValue.value, characteristicType: log.characteristicType))
                    .font(.subheadline)
                    .foregroundColor(Theme.Text.secondary)

                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundColor(Theme.Text.secondary)
            }

            if let newValue = log.newValue {
                Text(CharacteristicTypes.formatValue(newValue.value, characteristicType: log.characteristicType))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.Text.primary)
            } else {
                Text("--")
                    .font(.subheadline)
                    .foregroundColor(Theme.Text.secondary)
            }
        }
    }

    // MARK: - Detail Expansion

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 6) {
                if let detailedReq = log.detailedRequestBody {
                    Text("Request:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Text.secondary)
                    Text(Self.formatJSON(detailedReq))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(Theme.Text.secondary)
                        .textSelection(.enabled)
                }
                if let detailedResp = log.detailedResponseBody {
                    Text("Response:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Text.secondary)
                    Text(Self.formatJSON(detailedResp))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(Theme.Text.secondary)
                        .textSelection(.enabled)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(6)
        }
    }

    /// Attempts to pretty-print a JSON string; returns as-is if not valid JSON.
    private static func formatJSON(_ string: String) -> String {
        guard let data = string.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8)
        else {
            return string
        }
        return prettyString
    }
}

#Preview {
    List {
        Section(header: Text("Device State Change")) {
            LogRow(log: PreviewData.sampleLogs[0], detailedLogsEnabled: false)
                .listRowBackground(Theme.contentBackground)
            NavigationLink {
                Text("Workflow Detail View")
            } label: {
                WorkflowExecutionLogRow(log: PreviewData.sampleWorkflowLogs[0])
            }
            .buttonStyle(.plain)
            .listRowBackground(Theme.contentBackground)
            LogRow(log: PreviewData.sampleLogs[1], detailedLogsEnabled: true)
                .listRowBackground(Theme.contentBackground)
            LogRow(log: PreviewData.sampleLogs[2], detailedLogsEnabled: true)
                .listRowBackground(Theme.contentBackground)
            LogRow(log: PreviewData.sampleLogs[3], detailedLogsEnabled: false)
                .listRowBackground(Theme.contentBackground)
            LogRow(log: PreviewData.sampleLogs[4], detailedLogsEnabled: false)
                .listRowBackground(Theme.contentBackground)
            LogRow(log: PreviewData.sampleLogs[5], detailedLogsEnabled: false)
                .listRowBackground(Theme.contentBackground)

            NavigationLink {
                Text("Workflow Detail View")
            } label: {
                WorkflowExecutionLogRow(log: PreviewData.sampleWorkflowLogs[1])
            }
            .listRowBackground(Theme.contentBackground)

            NavigationLink {
                Text("Workflow Detail View")
            } label: {
                WorkflowExecutionLogRow(log: PreviewData.sampleWorkflowLogs[2])
            }
            .listRowBackground(Theme.contentBackground)
        }
    }
    .listStyle(.plain)
}
