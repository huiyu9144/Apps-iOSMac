import AppKit
import Combine
import Foundation

private class FileStorageService {
    static let shared = FileStorageService()
    private let fileManager = FileManager.default

    private var storageDir: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ClipFlow", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func imagePath(for id: UUID) -> URL {
        storageDir.appendingPathComponent("img_\(id.uuidString).dat")
    }

    private func rtfPath(for id: UUID) -> URL {
        storageDir.appendingPathComponent("rtf_\(id.uuidString).dat")
    }

    func saveImageData(_ data: Data, for id: UUID) {
        try? data.write(to: imagePath(for: id), options: .atomic)
    }

    func loadImageData(for id: UUID) -> Data? {
        try? Data(contentsOf: imagePath(for: id))
    }

    func saveRtfData(_ data: Data, for id: UUID) {
        try? data.write(to: rtfPath(for: id), options: .atomic)
    }

    func loadRtfData(for id: UUID) -> Data? {
        try? Data(contentsOf: rtfPath(for: id))
    }

    func deleteData(for id: UUID) {
        try? fileManager.removeItem(at: imagePath(for: id))
        try? fileManager.removeItem(at: rtfPath(for: id))
    }

    func cleanUnused(keep ids: Set<UUID>) {
        guard let files = try? fileManager.contentsOfDirectory(at: storageDir, includingPropertiesForKeys: nil) else { return }
        for file in files {
            let name = file.lastPathComponent
            if let prefix = name.split(separator: "_").dropFirst().first,
               let uuidStr = prefix.split(separator: ".").first,
               let uuid = UUID(uuidString: String(uuidStr)),
               !ids.contains(uuid) {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}

class ClipboardMonitor: ObservableObject {
    @Published var history: [ClipboardItem] = []
    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private let historyService: HistoryService
    private let fileStorage = FileStorageService.shared
    private var isCopyingFromHistory = false

    init(historyService: HistoryService) {
        self.historyService = historyService
        self.history = loadHistory()
    }

    private func loadHistory() -> [ClipboardItem] {
        let items = historyService.loadHistory()
        return items.map { item in
            var mutableItem = item
            if item.type == .image {
                mutableItem.imageData = fileStorage.loadImageData(for: item.id)
            } else if item.type == .rtf {
                mutableItem.rtfData = fileStorage.loadRtfData(for: item.id)
            }
            return mutableItem
        }
    }

    func startMonitoring() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let pasteboard = NSPasteboard.general
            let currentChangeCount = pasteboard.changeCount
            if currentChangeCount != self.lastChangeCount {
                self.lastChangeCount = currentChangeCount
                if !self.isCopyingFromHistory {
                    self.handleNewContent(pasteboard)
                }
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func handleNewContent(_ pasteboard: NSPasteboard) {
        guard let content = PasteboardParser.parse(pasteboard) else { return }

        let item: ClipboardItem

        switch content {
        case .text(let text):
            guard !text.isEmpty else { return }
            if let lastItem = history.first, lastItem.type == .text, lastItem.textContent == text {
                return
            }
            item = ClipboardItem(
                id: UUID(),
                type: .text,
                textContent: text,
                imageData: nil,
                fileURLs: nil,
                rtfData: nil,
                createdAt: Date(),
                isFavorite: false
            )

        case .rtf(let rtfData, let plainText):
            if let lastItem = history.first, lastItem.type == .rtf, lastItem.rtfData == rtfData {
                return
            }
            let itemId = UUID()
            fileStorage.saveRtfData(rtfData, for: itemId)
            item = ClipboardItem(
                id: itemId,
                type: .rtf,
                textContent: plainText,
                imageData: nil,
                fileURLs: nil,
                rtfData: rtfData,
                createdAt: Date(),
                isFavorite: false
            )

        case .image(let image):
            guard image.tiffRepresentation != nil else { return }
            let imageData = dataFromImage(image)
            let itemId = UUID()
            if let data = imageData {
                fileStorage.saveImageData(data, for: itemId)
            }
            item = ClipboardItem(
                id: itemId,
                type: .image,
                textContent: nil,
                imageData: imageData,
                fileURLs: nil,
                rtfData: nil,
                createdAt: Date(),
                isFavorite: false
            )

        case .files(let urls):
            let urlStrings = urls.map { $0.absoluteString }
            if let lastItem = history.first, lastItem.type == .files, lastItem.fileURLs == urlStrings {
                return
            }
            item = ClipboardItem(
                id: UUID(),
                type: .files,
                textContent: nil,
                imageData: nil,
                fileURLs: urlStrings,
                rtfData: nil,
                createdAt: Date(),
                isFavorite: false
            )
        }

        DispatchQueue.main.async {
            self.addItem(item)
        }
    }

    private func addItem(_ item: ClipboardItem) {
        history.insert(item, at: 0)
        let limit = historyService.currentLimit
        if history.count > limit {
            let removed = Array(history[limit...])
            history = Array(history.prefix(limit))
            for r in removed {
                fileStorage.deleteData(for: r.id)
            }
        }
        saveCleanHistory()
    }

    private func saveCleanHistory() {
        let cleanItems = history.map { item -> ClipboardItem in
            var clean = item
            clean.imageData = nil
            clean.rtfData = nil
            return clean
        }
        historyService.saveHistory(cleanItems)
    }

    private func dataFromImage(_ image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation else { return nil }
        let bitmap = NSBitmapImageRep(data: tiffData)
        return bitmap?.representation(using: .png, properties: [:])
    }

    func removeItem(_ item: ClipboardItem) {
        history.removeAll { $0.id == item.id }
        fileStorage.deleteData(for: item.id)
        saveCleanHistory()
    }

    func clearAll() {
        fileStorage.cleanUnused(keep: [])
        history.removeAll()
        historyService.clearHistory()
    }

    func toggleFavorite(_ item: ClipboardItem) {
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            history[index].isFavorite.toggle()
            saveCleanHistory()
        }
    }

    func copyToClipboard(_ item: ClipboardItem) {
        isCopyingFromHistory = true

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.type {
        case .text, .rtf:
            if let text = item.textContent {
                pasteboard.setString(text, forType: .string)
            }
            if let rtfData = item.rtfData ?? fileStorage.loadRtfData(for: item.id) {
                pasteboard.setData(rtfData, forType: .rtf)
            }
        case .image:
            if let imageData = item.imageData ?? fileStorage.loadImageData(for: item.id) {
                pasteboard.setData(imageData, forType: .png)
            }
        case .files:
            if let fileURLs = item.fileURLs {
                let urls = fileURLs.compactMap { URL(string: $0) }
                pasteboard.writeObjects(urls as [NSURL])
            }
        }

        lastChangeCount = NSPasteboard.general.changeCount

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isCopyingFromHistory = false
        }
    }

    func setHistoryLimit(_ limit: Int) {
        if history.count > limit {
            let removed = Array(history[limit...])
            history = Array(history.prefix(limit))
            for r in removed {
                fileStorage.deleteData(for: r.id)
            }
            saveCleanHistory()
        }
    }
}
