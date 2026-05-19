import Foundation
import SwiftUI

enum ImageFormat: String, CaseIterable, Identifiable {
    case png = "PNG"
    case jpg = "JPG"
    case webp = "WebP"
    case heic = "HEIC"
    case avif = "AVIF"
    case gif = "GIF"

    var id: String { rawValue }

    var utType: String {
        switch self {
        case .png: return "public.png"
        case .jpg: return "public.jpeg"
        case .webp: return "org.webmproject.webp"
        case .heic: return "public.heic"
        case .avif: return "public.avif"
        case .gif: return "com.compuserve.gif"
        }
    }

    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpg: return "jpg"
        case .webp: return "webp"
        case .heic: return "heic"
        case .avif: return "avif"
        case .gif: return "gif"
        }
    }

    var defaultQuality: Double {
        switch self {
        case .png: return 1.0
        case .jpg: return 0.9
        case .webp: return 0.9
        case .heic: return 0.8
        case .avif: return 0.8
        case .gif: return 1.0
        }
    }
}

enum OutputDirectory: String, CaseIterable, Identifiable {
    case sameAsSource = "same"
    case desktop = "desktop"
    case custom = "custom"

    var id: String { rawValue }

    var displayKey: String {
        switch self {
        case .sameAsSource: return "与源文件相同"
        case .desktop: return "桌面"
        case .custom: return "自定义"
        }
    }
}

@MainActor
@Observable
class FormatQuickViewModel {
    var imageFiles: [URL] = []
    var selectedFormat: ImageFormat = .webp
    var quality: Double = 0.9
    var resizeEnabled = false
    var resizeWidth: Int = 1920
    var resizeHeight: Int = 1080
    var keepExif = true
    var isConverting = false
    var progress: Double = 0
    var currentFileName: String = ""
    var totalFileCount: Int = 0
    var outputDirectory: OutputDirectory = .sameAsSource
    var openFolderAfterConvert = true
    var showAlert = false
    var alertMessage = ""

    private let converter = FormatConverterService()
    private let shortcutManager = KeyboardShortcutManager()

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

    init() {
        loadSettings()
    }

    func addImages(_ urls: [URL]) {
        let newUrls = urls.filter { url in
            guard let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
                  NSImage.imageTypes.contains(typeIdentifier) else {
                return false
            }
            return !imageFiles.contains(url)
        }
        imageFiles.append(contentsOf: newUrls)
        if !newUrls.isEmpty {
            updateFormatForInput()
        }
    }

    func addFolder(_ url: URL) {
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
        addImages(imageUrls)
    }

    func clearImages() {
        imageFiles.removeAll()
        progress = 0
        currentFileName = ""
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
        let shouldKeepExif = keepExif

        let files = imageFiles

        await converter.convertBatch(
            files: files,
            format: targetFormat,
            quality: targetQuality,
            resize: shouldResize,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
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
        switch outputDirectory {
        case .desktop:
            let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
            return desktop.appendingPathComponent("FormatQuick")
        case .custom:
            if let customPath = UserDefaults.standard.string(forKey: "customOutputPath"),
               !customPath.isEmpty {
                return URL(fileURLWithPath: customPath)
            }
            fallthrough
        case .sameAsSource:
            return FileManager.default.temporaryDirectory.appendingPathComponent("FormatQuick")
        }
    }

    private func updateFormatForInput() {
        guard let firstFile = imageFiles.first,
              let typeIdentifier = try? firstFile.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else {
            return
        }
        if typeIdentifier == "public.png" {
            selectedFormat = .webp
            quality = ImageFormat.webp.defaultQuality
        }
    }

    private func loadSettings() {
        outputDirectory = OutputDirectory(
            rawValue: UserDefaults.standard.string(forKey: "outputDirectory") ?? "same"
        ) ?? .sameAsSource
        openFolderAfterConvert = UserDefaults.standard.object(forKey: "openFolderAfterConvert") as? Bool ?? true
    }

    func saveSettings() {
        UserDefaults.standard.set(outputDirectory.rawValue, forKey: "outputDirectory")
        UserDefaults.standard.set(openFolderAfterConvert, forKey: "openFolderAfterConvert")
    }
}
