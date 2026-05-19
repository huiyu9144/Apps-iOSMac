import AppKit
import Carbon

@MainActor
class KeyboardShortcutManager {
    private var eventHandler: EventHandlerRef?
    private var hotKeyId: UInt32 = 1
    private var isRegistered = false

    var onShortcutTriggered: (() -> Void)?

    func register(shortcut: (keyCode: UInt32, modifiers: UInt32)) {
        guard !isRegistered else { return }
        isRegistered = true

        let hotKeyId = EventHotKeyID(signature: 0x48554545, id: shortcut.keyCode)
        var hotKeyRef: EventHotKeyRef?

        RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyId,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        let eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: OSType(kEventHotKeyPressed))

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { (_, event, userData) in
                guard let userData = userData else { return OSStatus(-9874) }
                let manager = Unmanaged<KeyboardShortcutManager>.fromOpaque(userData).takeUnretainedValue()
                manager.onShortcutTriggered?()
                return OSStatus(noErr)
            },
            1,
            [eventSpec],
            selfPtr,
            &eventHandler
        )
    }

    func unregister() {
        guard isRegistered else { return }
        isRegistered = false
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    static let cmdShiftC: (keyCode: UInt32, modifiers: UInt32) = {
        return (keyCode: 8, modifiers: UInt32(cmdKey | shiftKey))
    }()
}
