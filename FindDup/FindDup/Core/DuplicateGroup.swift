import Foundation

struct DuplicateGroup: Identifiable {
    let id = UUID()
    let files: [FileInfo]
    let totalSize: Int64
    let wastedSize: Int64

    var fileCount: Int { files.count }
    var displayName: String { files.first?.fileName ?? "Unknown" }

    var formattedTotalSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }

    var formattedWastedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: wastedSize)
    }
}
