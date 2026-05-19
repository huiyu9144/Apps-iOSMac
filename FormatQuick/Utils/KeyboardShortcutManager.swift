import AppKit
import Carbon

@MainActor
class KeyboardShortcutManager {
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyId: UInt32 = 1
    private var isRegistered = false

    var onShortcutTriggered: (() -> Void)?

    func register(shortcut: (keyCode: UInt32, modifiers: UInt32)) {
        guard !isRegistered else { return }
        isRegistered = true

        let hotKeyId = EventHotKeyID(signature: 0x464D5443, id: shortcut.keyCode)
        RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyId,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        let eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return Int32(eventNotHandledErr) }
                let manager = Unmanaged<KeyboardShortcutManager>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                manager.onShortcutTriggered?()
                return Int32(noErr)
            },
            1,
            [eventSpec],
            selfPtr,
            &eventHandler
        )
    }

    func unregister() {
        guard isRegistered else { return }

        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }

        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        isRegistered = false
    }
}
