import AppKit
import SwiftUI
import UniformTypeIdentifiers

final class CaptureManager: NSObject, ObservableObject {
    @Published var isCapturing = false
    @Published var capturedImage: NSImage?
    @Published var showEditor = false

    private let regionCapturer = RegionCapturer()
    private let windowCapturer = WindowCapturer()
    private let fullscreenCapturer = FullscreenCapturer()
    private let scrollingCapturer = ScrollingCapturer()

    var saveDirectory: URL = {
        let paths = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)
        return paths.first ?? FileManager.default.temporaryDirectory
    }()

    func captureRegion() {
        guard !isCapturing else { return }
        isCapturing = true
        regionCapturer.capture { [weak self] image in
            guard let self, let image else {
                self?.isCapturing = false
                return
            }
            self.handleCapturedImage(image)
        }
    }

    func captureWindow() {
        guard !isCapturing else { return }
        isCapturing = true
        windowCapturer.capture { [weak self] image in
            guard let self, let image else {
                self?.isCapturing = false
                return
            }
            self.handleCapturedImage(image)
        }
    }

    func captureFullScreen() {
        guard !isCapturing else { return }
        isCapturing = true
        fullscreenCapturer.capture { [weak self] image in
            guard let self, let image else {
                self?.isCapturing = false
                return
            }
            self.handleCapturedImage(image)
        }
    }

    func captureScrolling() {
        guard !isCapturing else { return }
        isCapturing = true
        scrollingCapturer.capture { [weak self] image in
            guard let self, let image else {
                self?.isCapturing = false
                return
            }
            self.handleCapturedImage(image)
        }
    }

    private func handleCapturedImage(_ image: NSImage) {
        isCapturing = false
        capturedImage = image
        showEditor = true
    }

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HHmmss"
        return df
    }()

    func saveImage(_ image: NSImage, filename: String? = nil) {
        let defaultName = "CleanShot_\(Self.dateFormatter.string(from: Date())).png"
        let name = filename ?? defaultName
        let fileURL = saveDirectory.appendingPathComponent(name)

        guard let data = image.pngData else { return }

        do {
            try data.write(to: fileURL)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([image])

            let captureItem = CaptureItem(
                id: UUID(),
                fileURL: fileURL,
                thumbnail: image.resizedThumbnail(),
                date: Date()
            )

            NotificationCenter.default.post(
                name: .captureSaved,
                object: nil,
                userInfo: ["capture": captureItem]
            )
        } catch {
            print("Failed to save image: \(error)")
        }
    }

    func copyToClipboard(_ image: NSImage) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
    }

    func openScreenshotsFolder() {
        NSWorkspace.shared.open(saveDirectory)
    }

    func openCapture(_ capture: CaptureItem) {
        guard let url = capture.fileURL else { return }
        NSWorkspace.shared.open(url)
    }
}

extension Notification.Name {
    static let captureSaved = Notification.Name("captureSaved")
}

struct CaptureItem: Identifiable {
    let id: UUID
    let fileURL: URL?
    let thumbnail: NSImage?
    let date: Date

    var image: NSImage? {
        guard let url = fileURL else { return nil }
        return NSImage(contentsOf: url)
    }
}

extension NSImage {
    var pngData: Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
