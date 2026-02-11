import SwiftUI

struct LogRow: View {
    let log: StateChangeLog

    private var isError: Bool {
        log.category == .webhookError || log.category == .serverError
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if isError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                Text(log.deviceName)
                    .font(.headline)
                    .foregroundColor(isError ? .red : .primary)
                Spacer()
                Text(log.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                Text(log.category == .serverError ? "Server Error" : isError ? "Webhook Error" : CharacteristicTypes.displayName(for: log.characteristicType))
                    .font(.subheadline)
                    .foregroundColor(isError ? .red : .secondary)

                Spacer()

                if !isError {
                    if let oldValue = log.oldValue {
                        Text(CharacteristicTypes.formatValue(oldValue.value, characteristicType: log.characteristicType))
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if let newValue = log.newValue {
                        Text(CharacteristicTypes.formatValue(newValue.value, characteristicType: log.characteristicType))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    } else {
                        Text("--")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if let errorDetails = log.errorDetails {
                Text(errorDetails)
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        LogRow(log: PreviewData.sampleLogs[0])
        LogRow(log: PreviewData.sampleLogs[1])
    }
}
