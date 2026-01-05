import Foundation

struct HistoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let query: String
    let ip: String
    let location: String
    let organization: String?
    let timestamp: Date

    init(query: String, ipInfo: IPInfo) {
        self.id = UUID()
        self.query = query
        self.ip = ipInfo.ip ?? "Unknown"
        self.location = ipInfo.locationString
        self.organization = ipInfo.org
        self.timestamp = Date()
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

@Observable
final class HistoryManager {
    private static let maxHistoryItems = 10
    private static let historyKey = "ip_lookup_history"
    private static let sharedSuiteName = "group.com.amazingmartin.ipinfo"

    private(set) var history: [HistoryItem] = []

    static let shared = HistoryManager()

    private init() {
        loadHistory()
    }

    func addToHistory(query: String, ipInfo: IPInfo) {
        let item = HistoryItem(query: query, ipInfo: ipInfo)

        // Remove duplicate if exists (same IP)
        if let ip = ipInfo.ip {
            history.removeAll { $0.ip == ip }
        }

        // Add to beginning
        history.insert(item, at: 0)

        // Keep only last 10 items
        if history.count > Self.maxHistoryItems {
            history = Array(history.prefix(Self.maxHistoryItems))
        }

        saveHistory()
    }

    func removeFromHistory(_ item: HistoryItem) {
        history.removeAll { $0.id == item.id }
        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    private func loadHistory() {
        // Try shared container first (for widget), then fall back to standard UserDefaults
        let defaults = UserDefaults(suiteName: Self.sharedSuiteName) ?? UserDefaults.standard

        guard let data = defaults.data(forKey: Self.historyKey) else {
            return
        }

        do {
            history = try JSONDecoder().decode([HistoryItem].self, from: data)
        } catch {
            print("Failed to load history: \(error)")
        }
    }

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history)

            // Save to both shared container (for widget) and standard UserDefaults
            UserDefaults.standard.set(data, forKey: Self.historyKey)

            if let sharedDefaults = UserDefaults(suiteName: Self.sharedSuiteName) {
                sharedDefaults.set(data, forKey: Self.historyKey)
            }
        } catch {
            print("Failed to save history: \(error)")
        }
    }

    // Get the most recent lookup for widget
    var mostRecent: HistoryItem? {
        history.first
    }
}
