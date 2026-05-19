import AppKit
import SwiftUI

final class HistoryManager: ObservableObject {
    @Published var recentCaptures: [CaptureItem] = []

    private let maxHistoryCount = 20
    private let saveKey = "CleanShotHistory"
    private let fileManager = FileManager.default

    init() {
        loadHistory()
        setupNotification()
    }

    private func setupNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNewCapture),
            name: .captureSaved,
            object: nil
        )
    }

    @objc private func handleNewCapture(_ notification: Notification) {
        guard let capture = notification.userInfo?["capture"] as? CaptureItem else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.recentCaptures.insert(capture, at: 0)

            if self.recentCaptures.count > self.maxHistoryCount {
                self.recentCaptures = Array(self.recentCaptures.prefix(self.maxHistoryCount))
            }

            self.saveHistory()
        }
    }

    func addCapture(_ capture: CaptureItem) {
        recentCaptures.insert(capture, at: 0)
        if recentCaptures.count > maxHistoryCount {
            recentCaptures = Array(recentCaptures.prefix(maxHistoryCount))
        }
        saveHistory()
    }

    func removeCapture(_ id: UUID) {
        recentCaptures.removeAll { $0.id == id }
        saveHistory()
    }

    func clearHistory() {
        recentCaptures.removeAll()
        saveHistory()
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        guard let paths = try? JSONDecoder().decode([String].self, from: data) else { return }

        for path in paths {
            let url = URL(fileURLWithPath: path)
            guard fileManager.fileExists(atPath: path) else { continue }
            guard let image = NSImage(contentsOf: url) else { continue }

            let attrs = try? fileManager.attributesOfItem(atPath: path)
            let date = attrs?[.creationDate] as? Date ?? Date()
            let thumbnail = image.resized(to: NSSize(width: 120, height: 80))

            let capture = CaptureItem(
                id: UUID(),
                fileURL: url,
                thumbnail: thumbnail,
                date: date
            )
            recentCaptures.append(capture)
        }

        recentCaptures.sort { $0.date > $1.date }
    }

    private func saveHistory() {
        let paths = recentCaptures.compactMap { $0.fileURL?.path }
        guard let data = try? JSONEncoder().encode(paths) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension NSImage {
    func resized(to targetSize: NSSize) -> NSImage {
        let image = NSImage(size: targetSize)
        image.lockFocus()
        let rect = NSRect(origin: .zero, size: targetSize)
        draw(in: rect, from: .zero, operation: .copy, fraction: 1.0)
        image.unlockFocus()
        return image
    }
}
