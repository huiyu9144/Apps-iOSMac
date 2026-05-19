import AppKit
import Foundation

enum ClipboardContentType: Codable, Equatable {
    case text
    case image
    case files
    case rtf
}

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let type: ClipboardContentType
    let textContent: String?
    var imageData: Data?
    let fileURLs: [String]?
    var rtfData: Data?
    let createdAt: Date
    var isFavorite: Bool

    var displayText: String {
        switch type {
        case .text:
            return textContent ?? ""
        case .image:
            return "🖼️ Image"
        case .files:
            return fileURLs?.joined(separator: ", ") ?? ""
        case .rtf:
            return textContent ?? "[Rich Text]"
        }
    }

    var textPreview: String {
        switch type {
        case .text, .rtf:
            let text = textContent ?? ""
            let maxLength = 80
            if text.count > maxLength {
                return String(text.prefix(maxLength)) + "..."
            }
            return text
        case .image:
            return "🖼️ Image"
        case .files:
            return fileURLs?.compactMap { URL(string: $0)?.lastPathComponent }.joined(separator: ", ") ?? ""
        }
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
}
