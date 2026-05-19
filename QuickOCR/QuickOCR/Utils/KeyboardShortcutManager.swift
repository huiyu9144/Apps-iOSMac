import Cocoa
import Carbon

class KeyboardShortcutManager {
    static let shared = KeyboardShortcutManager()

    private var hotKeyId: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var onShortcut: (() -> Void)?

    private init() {}

    func register(keyCode: Int = 31, modifiers: Int = 768, action: @escaping () -> Void) -> Bool {
        unregister()
        self.onShortcut = action

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(GetApplicationEventTarget(), { (_, event, userData) -> OSStatus in
            guard let userData = userData else { return noErr }
            let manager = Unmanaged<KeyboardShortcutManager>.fromOpaque(userData).takeUnretainedValue()
            manager.onShortcut?()
            return noErr
        }, 1, &eventType, selfPtr, &eventHandler)

        let signature = OSType("QOCR".utf8.reduce(0) { ($0 << 8) | OSType($1) })
        let hotKeyId = EventHotKeyID(signature: signature, id: 1)
        let status = RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers), hotKeyId, GetApplicationEventTarget(), 0, &self.hotKeyId)

        if status != noErr {
            unregister()
            return false
        }
        return true
    }

    func unregister() {
        if let hotKeyId = hotKeyId {
            UnregisterEventHotKey(hotKeyId)
            self.hotKeyId = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            self.eventHandler = nil
        }
        onShortcut = nil
    }

    deinit {
        unregister()
    }

    static func carbonModifierFlags(from eventModifiers: NSEvent.ModifierFlags) -> Int {
        var carbon: Int = 0
        if eventModifiers.contains(.command) { carbon |= cmdKey }
        if eventModifiers.contains(.option) { carbon |= optionKey }
        if eventModifiers.contains(.shift) { carbon |= shiftKey }
        if eventModifiers.contains(.control) { carbon |= controlKey }
        return carbon
    }

    static func carbonKeyCode(from character: String) -> Int {
        let keyMap: [String: Int] = [
            "a": 0, "b": 11, "c": 8, "d": 2, "e": 14, "f": 3, "g": 5, "h": 4, "i": 34,
            "j": 38, "k": 40, "l": 37, "m": 46, "n": 45, "o": 31, "p": 35, "q": 12, "r": 15,
            "s": 1, "t": 17, "u": 32, "v": 9, "w": 13, "x": 7, "y": 16, "z": 6,
            "0": 29, "1": 18, "2": 19, "3": 20, "4": 21, "5": 23, "6": 22, "7": 26, "8": 28, "9": 25
        ]
        return keyMap[character.lowercased()] ?? 31
    }

    static func modifierDisplayName(_ carbonModifiers: Int) -> String {
        var parts: [String] = []
        if carbonModifiers & cmdKey != 0 { parts.append("⌘") }
        if carbonModifiers & shiftKey != 0 { parts.append("⇧") }
        if carbonModifiers & optionKey != 0 { parts.append("⌥") }
        if carbonModifiers & controlKey != 0 { parts.append("⌃") }
        return parts.joined()
    }

    static func keyCodeToCharacter(_ code: Int) -> String {
        let map: [Int: String] = [
            0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H",
            34: "I", 38: "J", 40: "K", 37: "L", 46: "M", 45: "N", 31: "O", 35: "P",
            12: "Q", 15: "R", 1: "S", 17: "T", 32: "U", 9: "V", 13: "W", 7: "X",
            16: "Y", 6: "Z",
            29: "0", 18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7", 28: "8", 25: "9"
        ]
        return map[code] ?? "?"
    }

    static func shortcutDisplayString(keyCode: Int, modifiers: Int) -> String {
        "\(modifierDisplayName(modifiers))+\(keyCodeToCharacter(keyCode))"
    }
}
