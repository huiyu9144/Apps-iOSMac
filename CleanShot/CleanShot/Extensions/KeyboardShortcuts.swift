import AppKit
import Carbon

private var shortcutManagerRef: KeyboardShortcutManager?

private let hotKeySignature: OSType = 0x434C4E53

private func hotKeyHandler(nextHandler: EventHandlerCallRef?, theEvent: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus {
    guard let theEvent else { return noErr }

    var hotKeyID = EventHotKeyID()
    GetEventParameter(
        theEvent,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    let manager = Unmanaged<KeyboardShortcutManager>.fromOpaque(userData!).takeUnretainedValue()
    let index = Int(hotKeyID.id)
    guard index < KeyboardShortcutManager.CaptureMode.allCases.count else { return noErr }

    manager.handleShortcut(at: index)
    return noErr
}

final class KeyboardShortcutManager: ObservableObject {
    @Published var shortcuts: [CaptureMode: Shortcut] = [
        .region: Shortcut(keyCode: 0x15, modifiers: [.command, .shift]),
        .window: Shortcut(keyCode: 0x17, modifiers: [.command, .shift]),
        .fullscreen: Shortcut(keyCode: 0x16, modifiers: [.command, .shift]),
        .scrolling: Shortcut(keyCode: 0x18, modifiers: [.command, .shift]),
    ]

    private var hotKeyRefs: [EventHotKeyRef] = []
    private var eventHandler: EventHandlerRef?

    private weak var captureManager: CaptureManager?

    enum CaptureMode: String, CaseIterable {
        case region
        case window
        case fullscreen
        case scrolling
    }

    struct Shortcut {
        var keyCode: UInt16
        var modifiers: NSEvent.ModifierFlags
    }

    func handleShortcut(at index: Int) {
        guard let captureManager else { return }
        let modes = CaptureMode.allCases
        guard index < modes.count else { return }

        switch modes[index] {
        case .region: captureManager.captureRegion()
        case .window: captureManager.captureWindow()
        case .fullscreen: captureManager.captureFullScreen()
        case .scrolling: captureManager.captureScrolling()
        }
    }

    func registerShortcuts(captureManager: CaptureManager) {
        self.captureManager = captureManager
        shortcutManagerRef = self

        unregisterShortcuts()

        for (index, (_, shortcut)) in shortcuts.enumerated() {
            let hotKeyID = EventHotKeyID(signature: hotKeySignature, id: UInt32(index))
            let modifiers = mapModifiers(shortcut.modifiers)
            var hotKeyRef: EventHotKeyRef?

            RegisterEventHotKey(
                UInt32(shortcut.keyCode),
                modifiers,
                hotKeyID,
                GetEventDispatcherTarget(),
                0,
                &hotKeyRef
            )

            if let hotKeyRef {
                hotKeyRefs.append(hotKeyRef)
            }
        }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetEventDispatcherTarget(),
            hotKeyHandler,
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
    }

    private func mapModifiers(_ modifiers: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if modifiers.contains(.command) { carbon |= UInt32(cmdKey) }
        if modifiers.contains(.shift) { carbon |= UInt32(shiftKey) }
        if modifiers.contains(.option) { carbon |= UInt32(optionKey) }
        if modifiers.contains(.control) { carbon |= UInt32(controlKey) }
        return carbon
    }

    func unregisterShortcuts() {
        for ref in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()

        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    deinit {
        unregisterShortcuts()
        shortcutManagerRef = nil
    }
}
