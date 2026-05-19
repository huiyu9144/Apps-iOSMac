import AppKit
import Foundation

class HistoryService {
    private let userDefaults = UserDefaults.standard
    private let historyKey = "clipflow_history"
    private let maxHistoryDefault = 200

    var currentLimit: Int {
        let limit = userDefaults.integer(forKey: "historyLimit")
        return limit > 0 ? limit : maxHistoryDefault
    }

    func saveHistory(_ history: [ClipboardItem]) {
        let trimmed = Array(history.prefix(currentLimit))

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(trimmed)
            userDefaults.set(data, forKey: historyKey)
        } catch {
            print("Failed to save history: \(error)")
        }
    }

    func loadHistory() -> [ClipboardItem] {
        guard let data = userDefaults.data(forKey: historyKey) else { return [] }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([ClipboardItem].self, from: data)
        } catch {
            print("Failed to load history: \(error)")
            return []
        }
    }

    func clearHistory() {
        userDefaults.removeObject(forKey: historyKey)
    }
}
