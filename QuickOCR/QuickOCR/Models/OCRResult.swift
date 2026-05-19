import Foundation

struct OCRResult: Identifiable, Codable {
    let id: UUID
    let text: String
    let timestamp: Date
    let sourceImageRect: RectEncodable
    let language: String

    init(id: UUID = UUID(), text: String, timestamp: Date = Date(), sourceImageRect: CGRect = .zero, language: String = "en-US") {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.sourceImageRect = RectEncodable(rect: sourceImageRect)
        self.language = language
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var previewText: String {
        let maxLength = 80
        if text.count > maxLength {
            return String(text.prefix(maxLength)) + "..."
        }
        return text
    }
}

struct RectEncodable: Codable {
    let originX: CGFloat
    let originY: CGFloat
    let width: CGFloat
    let height: CGFloat

    init(rect: CGRect) {
        self.originX = rect.origin.x
        self.originY = rect.origin.y
        self.width = rect.width
        self.height = rect.height
    }

    var cgRect: CGRect {
        CGRect(x: originX, y: originY, width: width, height: height)
    }
}
