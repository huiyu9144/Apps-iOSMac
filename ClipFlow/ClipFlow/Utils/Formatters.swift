import Foundation

enum Formatters {
    static func relativeTime(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        switch interval {
        case ..<60:
            return "Just now"
        case ..<3600:
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        case ..<86400:
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        case ..<604800:
            let days = Int(interval / 86400)
            return "\(days)d ago"
        default:
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }

    static func contentTypeIcon(for type: ClipboardContentType) -> String {
        switch type {
        case .text:
            return "text.alignleft"
        case .image:
            return "photo"
        case .files:
            return "folder"
        case .rtf:
            return "doc.richtext"
        }
    }
}
