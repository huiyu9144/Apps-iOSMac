import Foundation

actor FileDeleter {
    enum DeleteError: Error, LocalizedError {
        case trashFailed(String)

        var errorDescription: String? {
            switch self {
            case .trashFailed(let path): return "无法将文件移到废纸篓: \(path)"
            }
        }
    }

    struct DeleteResult {
        let successCount: Int
        let failureCount: Int
        let freedSpace: Int64
    }

    func moveToTrash(files: [FileInfo]) async -> DeleteResult {
        var successCount = 0
        var failureCount = 0
        var freedSpace: Int64 = 0

        for file in files {
            do {
                var resultingURL: NSURL?
                try FileManager.default.trashItem(at: file.url, resultingItemURL: &resultingURL)
                successCount += 1
                freedSpace += file.size
            } catch {
                failureCount += 1
            }
        }

        return DeleteResult(
            successCount: successCount,
            failureCount: failureCount,
            freedSpace: freedSpace
        )
    }
}
