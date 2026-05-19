import Foundation

struct Formatters {
    static func truncate(_ text: String, maxLength: Int = 80) -> String {
        if text.count > maxLength {
            return String(text.prefix(maxLength)) + "..."
        }
        return text
    }

    static func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    static func formatDimensions(width: CGFloat, height: CGFloat) -> String {
        "\(Int(width)) × \(Int(height))"
    }
}
