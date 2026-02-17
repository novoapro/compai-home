import Foundation
import Combine

/// User-facing label for log category filters.
enum LogCategoryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case stateChange = "Device Update"
    case webhookCall = "Webhook Call"
    case webhookError = "Webhook Error"
    case mcpCall = "MCP Call"
    case serverError = "Server Error"

    var id: String { rawValue }

    /// Maps to the underlying `LogCategory` values.
    var logCategories: [LogCategory]? {
        switch self {
        case .all: return nil
        case .stateChange: return [.stateChange]
        case .webhookCall: return [.webhookCall]
        case .webhookError: return [.webhookError]
        case .mcpCall: return [.mcpCall]
        case .serverError: return [.serverError]
        }
    }

    var icon: String {
        switch self {
        case .all: return "line.3.horizontal.decrease.circle"
        case .stateChange: return "arrow.triangle.2.circlepath"
        case .webhookCall: return "paperplane.circle.fill"
        case .webhookError: return "exclamationmark.triangle.fill"
        case .mcpCall: return "arrow.left.arrow.right.circle.fill"
        case .serverError: return "xmark.octagon.fill"
        }
    }
}

class LogViewModel: ObservableObject {
    // Publish grouped logs directly to the view to avoid main thread computation
    @Published var groupedLogs: [(date: String, label: String, logs: [StateChangeLog])] = []
    @Published var searchText = ""
    @Published var filteredLogCount = 0

    // Filters
    @Published var selectedCategory: LogCategoryFilter = .all
    @Published var selectedDevice: String? = nil
    @Published var selectedService: String? = nil

    // We keep the raw logs here but don't publish them to avoid unnecessary view updates
    private var rawLogs: [StateChangeLog] = []

    var hasLogs: Bool { !rawLogs.isEmpty }
    var totalLogCount: Int { rawLogs.count }

    var hasActiveFilters: Bool {
        selectedCategory != .all || selectedDevice != nil || selectedService != nil
    }

    /// Unique device names found in the current logs, filtered by selected category.
    var availableDevices: [String] {
        let filtered = rawLogs.filter { log in
            if let categories = selectedCategory.logCategories {
                return categories.contains(log.category)
            }
            return true
        }
        return Array(Set(filtered.map(\.deviceName))).sorted()
    }

    /// Unique service names found in the current logs, filtered by selected category and device.
    var availableServices: [String] {
        let filtered = rawLogs.filter { log in
            // Filter by category
            if let categories = selectedCategory.logCategories {
                guard categories.contains(log.category) else { return false }
            }
            // Filter by device
            if let device = selectedDevice {
                guard log.deviceName == device else { return false }
            }
            return true
        }
        return Array(Set(filtered.compactMap(\.serviceName))).sorted()
    }

    private let loggingService: LoggingService
    private var cancellables = Set<AnyCancellable>()

    init(loggingService: LoggingService) {
        self.loggingService = loggingService

        // Listen to service updates
        loggingService.logsSubject
            .receive(on: DispatchQueue.main) // Receive on main to update local state safely
            .sink { [weak self] logs in
                self?.rawLogs = logs
                self?.updateView()
            }
            .store(in: &cancellables)

        // Listen to search text changes
        $searchText
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateView()
            }
            .store(in: &cancellables)

        // Listen to filter changes
        // Listen to filter changes
        $selectedCategory
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Reset child filters when category changes to prevent invalid states
                self?.selectedDevice = nil
                self?.selectedService = nil
                self?.updateView()
            }
            .store(in: &cancellables)
        
        $selectedDevice
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Reset service filter when device changes
                self?.selectedService = nil
                self?.updateView()
            }
            .store(in: &cancellables)

        $selectedService
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateView() }
            .store(in: &cancellables)

        // Initial fetch
        Task {
            let existing = await loggingService.getLogs()
            await MainActor.run {
                self.rawLogs = existing
                self.updateView()
            }
        }
    }

    private func updateView() {
        let logs = self.rawLogs
        let query = self.searchText
        let category = self.selectedCategory
        let device = self.selectedDevice
        let service = self.selectedService

        Task.detached(priority: .userInitiated) {
            let filtered = Self.filterLogs(logs, with: query, category: category, device: device, service: service)
            let grouped = Self.groupLogs(filtered)
            let count = filtered.count

            await MainActor.run {
                self.groupedLogs = grouped
                self.filteredLogCount = count
            }
        }
    }

    private static func filterLogs(
        _ logs: [StateChangeLog],
        with query: String,
        category: LogCategoryFilter,
        device: String?,
        service: String?
    ) -> [StateChangeLog] {
        var result = logs

        // Category filter
        if let categories = category.logCategories {
            result = result.filter { categories.contains($0.category) }
        }

        // Device filter
        if let device {
            result = result.filter { $0.deviceName == device }
        }

        // Service filter
        if let service {
            result = result.filter { $0.serviceName == service }
        }

        // Text search
        guard !query.isEmpty else { return result }
        let lowerQuery = query.localizedLowercase
        return result.filter { log in
            log.deviceName.localizedCaseInsensitiveContains(lowerQuery) ||
            CharacteristicTypes.displayName(for: log.characteristicType)
                .localizedCaseInsensitiveContains(lowerQuery) ||
            log.category.rawValue.localizedCaseInsensitiveContains(lowerQuery) ||
            (log.serviceName?.localizedCaseInsensitiveContains(lowerQuery) ?? false) ||
            (log.errorDetails?.localizedCaseInsensitiveContains(lowerQuery) ?? false)
        }
    }

    private static func groupLogs(_ logs: [StateChangeLog]) -> [(date: String, label: String, logs: [StateChangeLog])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let groupedDictionary = Dictionary(grouping: logs) { log in
            calendar.startOfDay(for: log.timestamp)
        }

        return groupedDictionary
            .sorted { $0.key > $1.key }
            .map { (date, logs) in
                let label: String
                if calendar.isDateInToday(date) {
                    label = "Today"
                } else if calendar.isDateInYesterday(date) {
                    label = "Yesterday"
                } else {
                    label = formatter.string(from: date)
                }
                return (date: date.ISO8601Format(), label: label, logs: logs)
            }
    }

    func clearFilters() {
        selectedCategory = .all
        selectedDevice = nil
        selectedService = nil
    }

    func clearLogs() {
        Task {
            await loggingService.clearLogs()
        }
    }
}
