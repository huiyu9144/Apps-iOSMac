import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor
@Observable
final class CompressionViewModel {
    var selectedURLs: [URL] = []
    var totalOriginalSize: Int64 = 0
    var quality: CompressionQuality = .high
    var outputFormat: OutputFormat = .jpeg
    var preserveEXIF: Bool = true
    var autoOpenFolder: Bool = true

    var isCompressing: Bool = false
    var progress: Double = 0
    var currentFileIndex: Int = 0
    var totalFiles: Int = 0
    var results: [CompressionResult] = []
    var compressionComplete: Bool = false
    var totalCompressedSize: Int64 = 0
    var errorMessage: String?

    private var compressionTask: Task<Void, Never>?

    var selectedFileCount: Int { selectedURLs.count }
    var totalSavedBytes: Int64 { totalOriginalSize - totalCompressedSize }
    var savedPercent: Double {
        guard totalOriginalSize > 0 else { return 0 }
        return Double(totalSavedBytes) / Double(totalOriginalSize) * 100.0
    }

    var formattedOriginalSize: String { ImageCompressor.formatByteSize(totalOriginalSize) }
    var formattedCompressedSize: String { ImageCompressor.formatByteSize(totalCompressedSize) }

    func selectFilesFromPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, UTType("org.webmproject.webp") ?? .png]
        panel.message = locStr("选择图片")
        panel.prompt = locStr("选择")

        guard panel.runModal() == .OK else { return }

        var urls: [URL] = []
        for url in panel.urls {
            if url.hasDirectoryPath {
                urls.append(contentsOf: scanDirectory(url))
            } else if ImageCompressor.isImageFile(url) {
                urls.append(url)
            }
        }

        selectedURLs = urls
        totalOriginalSize = urls.compactMap { try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize }.map(Int64.init).reduce(0, +)
    }

    private func scanDirectory(_ url: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        return enumerator.compactMap { $0 as? URL }.filter { ImageCompressor.isImageFile($0) }
    }

    func startCompression() {
        guard !selectedURLs.isEmpty else { return }

        isCompressing = true
        compressionComplete = false
        progress = 0
        currentFileIndex = 0
        totalFiles = selectedURLs.count
        results = []
        totalCompressedSize = 0
        errorMessage = nil

        let urls = selectedURLs
        let quality = self.quality
        let format = self.outputFormat
        let preserveExif = self.preserveEXIF
        let autoOpen = self.autoOpenFolder

        compressionTask = Task {
            let commonParent = findCommonParent(for: urls)
            let outputDir = commonParent.appendingPathComponent("PicShrink", isDirectory: true)
            try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

            let total = urls.count
            var localResults: [CompressionResult] = []
            var totalCompressed: Int64 = 0

            let batchResults = await withTaskGroup(of: (Int, Result<CompressionResult, Error>).self) { group in
                let semaphore = AsyncSemaphore(maxConcurrent: 4)
                for (index, url) in urls.enumerated() {
                    group.addTask {
                        await semaphore.wait()
                        defer { Task { await semaphore.signal() } }
                        do {
                            let result = try await ImageCompressor.compress(
                                imageAt: url,
                                quality: quality,
                                outputFormat: format,
                                preserveEXIF: preserveExif,
                                outputDirectory: outputDir
                            )
                            return (index, .success(result))
                        } catch {
                            return (index, .failure(error))
                        }
                    }
                }

                var results = Array<(Int, Result<CompressionResult, Error>)>()
                for await result in group {
                    results.append(result)
                    let completed = results.count
                    await MainActor.run {
                        self.currentFileIndex = completed
                        self.progress = Double(completed) / Double(total)
                    }
                }
                return results
            }

            for (_, result) in batchResults.sorted(by: { $0.0 < $1.0 }) {
                switch result {
                case .success(let cr):
                    localResults.append(cr)
                    totalCompressed += cr.compressedSize
                case .failure:
                    break
                }
            }

            await MainActor.run {
                self.results = localResults
                self.totalCompressedSize = totalCompressed
                self.compressionComplete = true
                self.isCompressing = false
                self.progress = 1.0

                if autoOpen {
                    NSWorkspace.shared.open(outputDir)
                }
            }
        }
    }

    func cancelCompression() {
        compressionTask?.cancel()
        compressionTask = nil
        isCompressing = false
        compressionComplete = false
    }

    private func findCommonParent(for urls: [URL]) -> URL {
        guard let first = urls.first else {
            return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        }

        guard urls.count > 1 else {
            let parent = first.deletingLastPathComponent()
            return parent.hasDirectoryPath ? parent : FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? parent
        }

        let pathComponents = urls.map { $0.pathComponents }
        guard let shortest = pathComponents.min(by: { $0.count < $1.count }) else { return first.deletingLastPathComponent() }

        var commonIndex = 0
        for i in 0..<shortest.count {
            let component = shortest[i]
            if pathComponents.allSatisfy({ $0.count > i && $0[i] == component }) {
                commonIndex = i
            } else {
                break
            }
        }

        if commonIndex > 0 {
            let commonComponents = Array(shortest[0...commonIndex])
            var commonURL = URL(fileURLWithPath: "/")
            for component in commonComponents {
                commonURL.appendPathComponent(component)
            }
            return commonURL
        }

        return first.deletingLastPathComponent()
    }
}

actor AsyncSemaphore {
    private var permits: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(maxConcurrent: Int) {
        self.permits = maxConcurrent
    }

    func wait() async {
        if permits > 0 {
            permits -= 1
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func signal() {
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        } else {
            permits += 1
        }
    }
}
