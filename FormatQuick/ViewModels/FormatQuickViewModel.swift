import Foundation
import SwiftUI

enum ImageFormat: String, CaseIterable, Identifiable {
    case jpg = "JPG"
    case heic = "HEIC"
    case gif = "GIF"

    var id: String { rawValue }

    var utType: String {
        switch self {
        case .jpg: return "public.jpeg"
        case .heic: return "public.heic"
        case .gif: return "com.compuserve.gif"
        }
    }

    var fileExtension: String {
        switch self {
        case .jpg: return "jpg"
        case .heic: return "heic"
        case .gif: return "gif"
        }
    }

    var defaultQuality: Double {
        switch self {
        case .jpg: return 0.3
        case .heic: return 0.3
        case .gif: return 1.0
        }
    }
}

enum OutputDirectory: String, CaseIterable, Identifiable {
    case temporary = "temporary"

    var id: String { rawValue }
}

enum ResizeMode: String, CaseIterable {
    case fit = "适应"
    case fill = "填充"
    case stretch = "拉伸"

    var id: String { rawValue }
}

@MainActor
@Observable
class FormatQuickViewModel {
    var imageFiles: [URL] = []
    var selectedFormat: ImageFormat = .jpg
    var quality: Double = 0.3
    var resizeEnabled = false
    var resizeWidth: Int = 1920
    var resizeHeight: Int = 1080
    var resizeMode: ResizeMode = .fit
    var keepExif = true
    var isConverting = false
    var progress: Double = 0
    var currentFileName: String = ""
    var totalFileCount: Int = 0
    var totalFileSize: UInt64 = 0
    var outputDirectory: OutputDirectory = .temporary
    var openFolderAfterConvert = true
    var showAlert = false
    var alertMessage = ""

    private let converter = FormatConverterService()

    var estimatedTime: String {
        guard !imageFiles.isEmpty else { return "0" + locStr("秒") }
        let perImage: Double = 0.6
        let seconds = Int(Double(imageFiles.count) * perImage)
        return "\(seconds)" + locStr("秒")
    }

    var durationLabel: String {
        let countStr = "\(imageFiles.count)"
        return countStr + locStr("张 → 约") + " " + estimatedTime
    }

    var totalSizeLabel: String {
        if totalFileSize == 0 { return "" }
        let size = Double(totalFileSize)
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    init() {
        loadSettings()
    }

    func addImages(_ urls: [URL]) {
        let existingSet = Set(imageFiles)
        let newUrls = urls.filter { url in
            guard !existingSet.contains(url) else { return false }
            guard let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else { return false }
            return NSImage.imageTypes.contains(typeIdentifier)
        }
        guard !newUrls.isEmpty else { return }

        imageFiles.append(contentsOf: newUrls)
        calculateTotalSize()
    }

    func addFolder(_ url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            guard let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.typeIdentifierKey],
                options: [.skipsHiddenFiles]
            ) else { return }

            var imageUrls: [URL] = []
            for case let fileURL as URL in enumerator {
                guard let typeIdentifier = try? fileURL.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
                      NSImage.imageTypes.contains(typeIdentifier) else {
                    continue
                }
                imageUrls.append(fileURL)
            }

            DispatchQueue.main.async { [weak self] in
                self?.addImages(imageUrls)
            }
        }
    }

    func clearImages() {
        imageFiles.removeAll()
        progress = 0
        currentFileName = ""
        totalFileSize = 0
    }

    func selectFormat(_ format: ImageFormat) {
        selectedFormat = format
        quality = format.defaultQuality
    }

    func startConversion() async {
        guard !imageFiles.isEmpty else {
            alertMessage = locStr("请先添加图片")
            showAlert = true
            return
        }

        isConverting = true
        totalFileCount = imageFiles.count
        progress = 0

        let destinationDir = resolveOutputDirectory()
        let targetFormat = selectedFormat
        let targetQuality = quality
        let shouldResize = resizeEnabled
        let targetWidth = resizeWidth
        let targetHeight = resizeHeight
        let targetResizeMode = resizeMode
        let shouldKeepExif = keepExif

        let files = imageFiles

        await converter.convertBatch(
            files: files,
            format: targetFormat,
            quality: targetQuality,
            resize: shouldResize,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
            resizeMode: targetResizeMode,
            keepExif: shouldKeepExif,
            outputDirectory: destinationDir,
            onProgress: { [weak self] completed, fileName in
                Task { @MainActor [weak self] in
                    self?.progress = Double(completed) / Double(max(files.count, 1))
                    self?.currentFileName = fileName
                }
            }
        )

        isConverting = false
        progress = 1.0

        if openFolderAfterConvert {
            NSWorkspace.shared.open(destinationDir)
        }
    }

    private func resolveOutputDirectory() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("com.formatquick.app")
            .appendingPathComponent(UUID().uuidString)
        return dir
    }

    private func calculateTotalSize() {
        let files = imageFiles
        DispatchQueue.global(qos: .utility).async {
            var total: UInt64 = 0
            for url in files {
                if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let size = attrs[.size] as? UInt64 {
                    total += size
                }
            }
            DispatchQueue.main.async { [weak self] in
                self?.totalFileSize = total
            }
        }
    }

    private func loadSettings() {
        openFolderAfterConvert = UserDefaults.standard.object(forKey: "openFolderAfterConvert") as? Bool ?? true
    }

    func saveSettings() {
        UserDefaults.standard.set(openFolderAfterConvert, forKey: "openFolderAfterConvert")
    }
}
