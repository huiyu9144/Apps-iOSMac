import Foundation

class CaptureHistory: ObservableObject {
    @Published var entries: [OCRResult] = []
    private let maxEntries = 20
    private let userDefaultsKey = "QuickOCR.History"

    static let shared = CaptureHistory()

    private init() {
        load()
    }

    func add(_ result: OCRResult) {
        entries.insert(result, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        save()
    }

    func remove(at index: Int) {
        guard index < entries.count else { return }
        entries.remove(at: index)
        save()
    }

    func clearAll() {
        entries.removeAll()
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([OCRResult].self, from: data) else { return }
        entries = decoded
    }
}
