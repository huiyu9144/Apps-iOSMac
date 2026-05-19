import Foundation

struct FileInfo: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let size: Int64
    let modificationDate: Date
    var sha256Hash: String?

    var fileName: String { url.lastPathComponent }
    var fileExtension: String { url.pathExtension.lowercased() }

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FileInfo, rhs: FileInfo) -> Bool {
        lhs.id == rhs.id
    }
}
