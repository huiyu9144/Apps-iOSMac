import Foundation

enum FileTypeFilter: String, CaseIterable {
    case all = "all"
    case images = "images"
    case documents = "documents"
    case videos = "videos"
    case music = "music"

    var localizedName: String {
        switch self {
        case .all: return loc("全部文件", "All Files")
        case .images: return loc("图片", "Images")
        case .documents: return loc("文档", "Documents")
        case .videos: return loc("视频", "Videos")
        case .music: return loc("音乐", "Music")
        }
    }

    var extensions: [String] {
        switch self {
        case .all: return []
        case .images: return ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
        case .documents: return ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf", "md", "csv"]
        case .videos: return ["mp4", "mov", "avi", "mkv", "wmv", "flv", "webm"]
        case .music: return ["mp3", "wav", "aac", "flac", "ogg", "wma", "m4a"]
        }
    }
}

actor FileScanner {
    private var isCancelled = false

    func cancel() {
        isCancelled = true
    }

    func scanDirectory(
        _ url: URL,
        minimumSize: Int64 = 1024,
        fileTypeFilter: FileTypeFilter = .all,
        progressHandler: @escaping (Int) -> Void
    ) async throws -> [FileInfo] {
        isCancelled = false
        var files: [FileInfo] = []
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw ScannerError.directoryAccessFailed
        }

        while let fileURL = enumerator.nextObject() as? URL {
            if isCancelled { throw ScannerError.cancelled }

            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(keys)),
                  let fileSize = resourceValues.fileSize,
                  fileSize >= minimumSize
            else { continue }

            if fileTypeFilter != .all {
                let ext = fileURL.pathExtension.lowercased()
                guard fileTypeFilter.extensions.contains(ext) else { continue }
            }

            let fileInfo = FileInfo(
                url: fileURL,
                size: Int64(fileSize),
                modificationDate: resourceValues.contentModificationDate ?? Date()
            )
            files.append(fileInfo)

            if files.count % 100 == 0 {
                progressHandler(files.count)
            }
        }

        progressHandler(files.count)
        return files
    }
}

enum ScannerError: Error, LocalizedError {
    case cancelled
    case directoryAccessFailed

    var errorDescription: String? {
        switch self {
        case .cancelled: return loc("扫描已取消", "Scan cancelled")
        case .directoryAccessFailed: return loc("无法访问该文件夹", "Cannot access the folder")
        }
    }
}
