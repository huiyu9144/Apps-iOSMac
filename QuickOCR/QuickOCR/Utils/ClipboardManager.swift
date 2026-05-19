import Cocoa

class ClipboardManager {
    static let shared = ClipboardManager()

    private init() {}

    func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func getClipboardContent() -> String? {
        NSPasteboard.general.string(forType: .string)
    }
}
