import AppKit

final class KeyboardShortcutManager {
    private var monitor: Any?

    func registerShortcut(key: UInt16, modifiers: NSEvent.ModifierFlags, action: @escaping () -> Void) {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let eventModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.keyCode == key && eventModifiers == modifiers {
                action()
            }
        }
    }

    func unregister() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    deinit {
        unregister()
    }
}
