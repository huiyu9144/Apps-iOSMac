import AppKit

enum PasteboardContent {
    case text(String)
    case rtf(Data, String?)
    case image(NSImage)
    case files([URL])
}

struct PasteboardParser {
    static func parse(_ pasteboard: NSPasteboard) -> PasteboardContent? {
        guard let types = pasteboard.types, !types.isEmpty else { return nil }

        // fileURL must be checked before image to avoid image files being stored as image data
        if types.contains(.fileURL) {
            if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL], !urls.isEmpty {
                return .files(urls)
            }
        }

        if types.contains(.URL) {
            if let urlString = pasteboard.string(forType: .URL),
               let url = URL(string: urlString) {
                return .files([url])
            }
        }

        if types.contains(.rtf) {
            if let rtfData = pasteboard.data(forType: .rtf) {
                let attributed = try? NSAttributedString(data: rtfData, options: [:], documentAttributes: nil)
                let plainText = attributed?.string
                return .rtf(rtfData, plainText)
            }
        }

        if types.contains(.string) {
            if let text = pasteboard.string(forType: .string) {
                return .text(text)
            }
        }

        if types.contains(.tiff) || types.contains(.png) {
            if let image = pasteboard.readObjects(forClasses: [NSImage.self])?.first as? NSImage {
                return .image(image)
            }
        }

        return nil
    }
}
