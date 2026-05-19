import AppKit

@MainActor
class KeyboardShortcutManager {
    var onShortcutTriggered: (() -> Void)?

    func register(shortcut: (keyCode: UInt32, modifiers: UInt32)) {
    }

    func unregister() {
    }
}
