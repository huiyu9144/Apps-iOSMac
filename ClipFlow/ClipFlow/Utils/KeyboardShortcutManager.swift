import Cocoa
import Carbon

private class HotKeyRegistry {
    static var instance: KeyboardShortcutManager?
}

private func hotKeyCallback(nextHandler: EventHandlerCallRef?, event: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus {
    HotKeyRegistry.instance?.handleHotKeyPress()
    return noErr
}

class KeyboardShortcutManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var onToggle: (() -> Void)?

    func registerToggleShortcut(action: @escaping () -> Void) {
        unregisterShortcut()
        onToggle = action
        HotKeyRegistry.instance = self

        var outHotKey: EventHotKeyRef?
        let id = EventHotKeyID(signature: 0, id: 1)

        let status = RegisterEventHotKey(
            9,
            UInt32(cmdKey) | UInt32(shiftKey),
            id,
            GetApplicationEventTarget(),
            0,
            &outHotKey
        )

        guard status == noErr else { return }

        hotKeyRef = outHotKey

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        var outHandler: EventHandlerRef?
        _ = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyCallback,
            1,
            &spec,
            nil,
            &outHandler
        )
        eventHandlerRef = outHandler
    }

    func handleHotKeyPress() {
        onToggle?()
    }

    func unregisterShortcut() {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
        if let ref = eventHandlerRef { RemoveEventHandler(ref) }
        hotKeyRef = nil
        eventHandlerRef = nil
        onToggle = nil
        HotKeyRegistry.instance = nil
    }

    deinit { unregisterShortcut() }
}
