import Foundation
import AppKit
import CoreGraphics
import ApplicationServices
import IOKit
import Darwin

private let kVK_ANSI_A: UInt16 = 0x00
private let kVK_ANSI_S: UInt16 = 0x01
private let kVK_ANSI_D: UInt16 = 0x02
private let kVK_ANSI_F: UInt16 = 0x03
private let kVK_ANSI_H: UInt16 = 0x04
private let kVK_ANSI_G: UInt16 = 0x05
private let kVK_ANSI_Z: UInt16 = 0x06
private let kVK_ANSI_X: UInt16 = 0x07
private let kVK_ANSI_C: UInt16 = 0x08
private let kVK_ANSI_V: UInt16 = 0x09
private let kVK_ANSI_B: UInt16 = 0x0B
private let kVK_ANSI_Q: UInt16 = 0x0C
private let kVK_ANSI_W: UInt16 = 0x0D
private let kVK_ANSI_E: UInt16 = 0x0E
private let kVK_ANSI_R: UInt16 = 0x0F
private let kVK_ANSI_Y: UInt16 = 0x10
private let kVK_ANSI_T: UInt16 = 0x11
private let kVK_ANSI_1: UInt16 = 0x12
private let kVK_ANSI_2: UInt16 = 0x13
private let kVK_ANSI_3: UInt16 = 0x14
private let kVK_ANSI_4: UInt16 = 0x15
private let kVK_ANSI_6: UInt16 = 0x16
private let kVK_ANSI_5: UInt16 = 0x17
private let kVK_ANSI_Equal: UInt16 = 0x18
private let kVK_ANSI_9: UInt16 = 0x19
private let kVK_ANSI_7: UInt16 = 0x1A
private let kVK_ANSI_Minus: UInt16 = 0x1B
private let kVK_ANSI_8: UInt16 = 0x1C
private let kVK_ANSI_0: UInt16 = 0x1D
private let kVK_ANSI_RightBracket: UInt16 = 0x1E
private let kVK_ANSI_O: UInt16 = 0x1F
private let kVK_ANSI_U: UInt16 = 0x20
private let kVK_ANSI_LeftBracket: UInt16 = 0x21
private let kVK_ANSI_I: UInt16 = 0x22
private let kVK_ANSI_P: UInt16 = 0x23
private let kVK_Return: UInt16 = 0x24
private let kVK_ANSI_L: UInt16 = 0x25
private let kVK_ANSI_J: UInt16 = 0x26
private let kVK_ANSI_Quote: UInt16 = 0x27
private let kVK_ANSI_K: UInt16 = 0x28
private let kVK_ANSI_Semicolon: UInt16 = 0x29
private let kVK_ANSI_Backslash: UInt16 = 0x2A
private let kVK_ANSI_Comma: UInt16 = 0x2B
private let kVK_ANSI_Slash: UInt16 = 0x2C
private let kVK_ANSI_N: UInt16 = 0x2D
private let kVK_ANSI_M: UInt16 = 0x2E
private let kVK_ANSI_Period: UInt16 = 0x2F
private let kVK_Tab: UInt16 = 0x30
private let kVK_Space: UInt16 = 0x31
private let kVK_ANSI_Grave: UInt16 = 0x32
private let kVK_Delete: UInt16 = 0x33
private let kVK_Escape: UInt16 = 0x35
private let kVK_Command: UInt16 = 0x37
private let kVK_Shift: UInt16 = 0x38
private let kVK_Control: UInt16 = 0x3B
private let kVK_UpArrow: UInt16 = 0x7E

struct AXWindowInfo {
    let windowID: CGWindowID
    let title: String
    let appName: String
    let pid: pid_t
    let isOnScreen: Bool
}

enum InputControllerError: Error, LocalizedError {
    case noDisplayAvailable
    case windowNotFound
    case elementNotFound(String)
    case actionFailed(String)
    case appLaunchFailed(String)
    case appNotFound(String)
    case scriptExecutionFailed(String)
    case accessibilityPermissionDenied

    var errorDescription: String? {
        switch self {
        case .noDisplayAvailable:
            return "No display is available for coordinate conversion."
        case .windowNotFound:
            return "The requested window was not found."
        case .elementNotFound(let name):
            return "UI element \"\(name)\" was not found."
        case .actionFailed(let action):
            return "Failed to perform action: \(action)"
        case .appLaunchFailed(let bundleID):
            return "Failed to launch app with bundle ID: \(bundleID)"
        case .appNotFound(let bundleID):
            return "App with bundle ID \"\(bundleID)\" is not installed."
        case .scriptExecutionFailed(let detail):
            return "Script execution failed: \(detail)"
        case .accessibilityPermissionDenied:
            return "Accessibility permission has not been granted."
        }
    }
}

final class InputController {

    private static let clickInterval: useconds_t = 10000
    private static let dblClickInterval: useconds_t = 50000
    private static let scrollPixelMultiplier: Double = 1.0

    private let commandQueue = DispatchQueue(label: "com.jiaremote.input.controller", qos: .userInitiated)

    private var currentMouseLocation: CGPoint = .zero

    init() {
        if let event = CGEvent(source: nil) {
            currentMouseLocation = event.location
        }
    }

    deinit {
        ()
    }

    private var displayAssertionID: UInt32 = 0

    func normalizedToScreen(x: Float, y: Float) -> CGPoint {
        let screenBounds = CGDisplayBounds(CGMainDisplayID())
        return CGPoint(
            x: screenBounds.origin.x + CGFloat(x) * screenBounds.width,
            y: screenBounds.origin.y + CGFloat(y) * screenBounds.height
        )
    }

    func screenToNormalized(point: CGPoint) -> (Float, Float) {
        let screenBounds = CGDisplayBounds(CGMainDisplayID())
        let normalizedX = Float((point.x - screenBounds.origin.x) / screenBounds.width)
        let normalizedY = Float((point.y - screenBounds.origin.y) / screenBounds.height)
        return (normalizedX, normalizedY)
    }

    func moveMouse(to point: CGPoint) {
        currentMouseLocation = point
        guard let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                                   mouseCursorPosition: point, mouseButton: .left) else { return }
        event.post(tap: .cghidEventTap)
    }

    func mouseDown(button: CGMouseButton) {
        let eventType = Self.mouseDownEventType(for: button)
        guard let event = CGEvent(mouseEventSource: nil, mouseType: eventType,
                                   mouseCursorPosition: currentMouseLocation, mouseButton: button) else { return }
        event.post(tap: .cghidEventTap)
    }

    func mouseUp(button: CGMouseButton) {
        let eventType = Self.mouseUpEventType(for: button)
        guard let event = CGEvent(mouseEventSource: nil, mouseType: eventType,
                                   mouseCursorPosition: currentMouseLocation, mouseButton: button) else { return }
        event.post(tap: .cghidEventTap)
    }

    func mouseClick(button: CGMouseButton) {
        mouseDown(button: button)
        usleep(Self.clickInterval)
        mouseUp(button: button)
    }

    func mouseDblClick(button: CGMouseButton) {
        let eventTypeDown = Self.mouseDownEventType(for: button)
        let eventTypeUp = Self.mouseUpEventType(for: button)
        guard let down1 = CGEvent(mouseEventSource: nil, mouseType: eventTypeDown,
                                   mouseCursorPosition: currentMouseLocation, mouseButton: button),
              let up1 = CGEvent(mouseEventSource: nil, mouseType: eventTypeUp,
                                 mouseCursorPosition: currentMouseLocation, mouseButton: button) else { return }
        down1.post(tap: .cghidEventTap)
        usleep(Self.clickInterval)
        up1.post(tap: .cghidEventTap)

        usleep(Self.dblClickInterval)

        guard let down2 = CGEvent(mouseEventSource: nil, mouseType: eventTypeDown,
                                   mouseCursorPosition: currentMouseLocation, mouseButton: button),
              let up2 = CGEvent(mouseEventSource: nil, mouseType: eventTypeUp,
                                 mouseCursorPosition: currentMouseLocation, mouseButton: button) else { return }
        down2.post(tap: .cghidEventTap)
        usleep(Self.clickInterval)
        up2.post(tap: .cghidEventTap)
    }

    func scrollMouse(deltaX: Double, deltaY: Double) {
        let pixPerLine: Int64 = 10
        var pixelDeltaX = Int64(deltaX * Self.scrollPixelMultiplier * Double(pixPerLine))
        var pixelDeltaY = Int64(deltaY * Self.scrollPixelMultiplier * Double(pixPerLine))

        guard let event = CGEvent(scrollWheelEvent2Source: nil, units: .line,
                                   wheelCount: 2, wheel1: Int32(-deltaY), wheel2: Int32(deltaX), wheel3: 0) else { return }
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 0)

        let linesX = Int64(deltaX)
        let linesY = Int64(deltaY)
        let limit: Int64 = Int64(UInt32.max)

        if pixelDeltaX < -limit {
            pixelDeltaX = -limit
        } else if pixelDeltaX > limit {
            pixelDeltaX = limit
        }
        if pixelDeltaY < -limit {
            pixelDeltaY = -limit
        } else if pixelDeltaY > limit {
            pixelDeltaY = limit
        }

        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: linesX)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: linesY)
        event.setIntegerValueField(.scrollWheelEventFixedPtDeltaAxis2, value: pixelDeltaX)
        event.setIntegerValueField(.scrollWheelEventFixedPtDeltaAxis1, value: pixelDeltaY)
        event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: linesX)
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: linesY)

        event.setIntegerValueField(.scrollWheelEventMomentumPhase, value: 0)
        event.setIntegerValueField(.scrollWheelEventScrollPhase, value: 1)
        event.setIntegerValueField(.scrollWheelEventScrollCount, value: 1)

        event.setIntegerValueField(CGEventField(rawValue: 133)!, value: pixPerLine)
        event.setIntegerValueField(.scrollWheelEventInstantMouser, value: 1)
        event.setIntegerValueField(CGEventField(rawValue: 146)!, value: 1)

        event.post(tap: .cghidEventTap)
    }

    func keyDown(keyCode: CGKeyCode, flags: CGEventFlags) {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) else { return }
        event.flags = flags
        event.post(tap: .cghidEventTap)
    }

    func keyUp(keyCode: CGKeyCode, flags: CGEventFlags) {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else { return }
        event.flags = flags
        event.post(tap: .cghidEventTap)
    }

    func keyCombo(keyCodes: [CGKeyCode], flags: CGEventFlags) {
        for keyCode in keyCodes {
            keyDown(keyCode: keyCode, flags: flags)
            usleep(10000)
        }
        for keyCode in keyCodes.reversed() {
            keyUp(keyCode: keyCode, flags: flags)
            usleep(10000)
        }
    }

    func typeText(_ text: String) {
        for character in text {
            let utf16Chars = Array(character.utf16)
            for utf16Char in utf16Chars {
                var keyCode: CGKeyCode = 0
                var modifierFlags: CGEventFlags = []
                Self.mapCharacterToKey(utf16Char, keyCode: &keyCode, modifierFlags: &modifierFlags)

                if modifierFlags.contains(.maskShift) {
                    keyDown(keyCode: CGKeyCode(kVK_Shift), flags: modifierFlags)
                }

                keyDown(keyCode: keyCode, flags: modifierFlags)
                usleep(5000)
                keyUp(keyCode: keyCode, flags: modifierFlags)

                if modifierFlags.contains(.maskShift) {
                    keyUp(keyCode: CGKeyCode(kVK_Shift), flags: modifierFlags)
                }

                usleep(5000)
            }
        }
    }

    func sleep() {
        commandQueue.async {
            _ = Self.runAppleScript("tell application \"System Events\" to sleep")
        }
    }

    func restart() {
        commandQueue.async {
            let script = """
            tell application "System Events" to restart
            """
            _ = Self.runAppleScript(script)
        }
    }

    func shutdown() {
        commandQueue.async {
            let script = """
            tell application "System Events" to shut down
            """
            _ = Self.runAppleScript(script)
        }
    }

    func lockScreen() {
        commandQueue.async {
            if !Self.lockScreenViaSAC() {
                if !Self.lockScreenViaCGSSession() {
                    Self.lockScreenViaKeyCombo()
                }
            }
        }
    }

    func setVolume(_ level: Float) {
        let clampedLevel = max(0, min(100, level))
        commandQueue.async {
            _ = Self.runAppleScript("set volume output volume \(Int(clampedLevel))")
        }
    }

    func adjustVolume(up: Bool) {
        commandQueue.async {
            if up {
                _ = Self.runAppleScript("set volume output volume (output volume of (get volume settings) + 6.25)")
            } else {
                _ = Self.runAppleScript("set volume output volume (output volume of (get volume settings) - 6.25)")
            }
        }
    }

    func setBrightness(_ level: Float) {
        let clampedLevel = max(0, min(1, level))
        commandQueue.async {
            if !Self.setBrightnessViaIOKit(clampedLevel) {
                _ = Self.runAppleScript("tell application \"System Events\" to repeat with d in displays\nset brightness of d to \(clampedLevel)\nend repeat")
            }
        }
    }

    func adjustBrightness(up: Bool) {
        commandQueue.async {
            if !Self.adjustBrightnessViaIOKit(up) {
                let currentLevel = Self.getBrightnessLevel()
                let step: Float = 0.0625
                let newLevel = up ? min(1.0, currentLevel + step) : max(0.0, currentLevel - step)
                _ = Self.runAppleScript("tell application \"System Events\" to repeat with d in displays\nset brightness of d to \(newLevel)\nend repeat")
            }
        }
    }

    func openLaunchpad() {
        commandQueue.async {
            _ = Self.runAppleScript("tell application \"Dock\" to activate")
            usleep(100000)
            _ = Self.runAppleScript("""
            tell application "System Events"
                key code 160 using {option down}
            end tell
            """)
        }
    }

    func openMissionControl() {
        commandQueue.async {
            if let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Control), keyDown: true) {
                event.flags = .maskControl
                event.post(tap: .cghidEventTap)
            }
            usleep(50000)
            if let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_UpArrow), keyDown: true) {
                event.flags = .maskControl
                event.post(tap: .cghidEventTap)
            }
            usleep(50000)
            if let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_UpArrow), keyDown: false) {
                event.flags = .maskControl
                event.post(tap: .cghidEventTap)
            }
            usleep(50000)
            if let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Control), keyDown: false) {
                event.post(tap: .cghidEventTap)
            }
        }
    }

    func wake() {
        commandQueue.async {
            _ = Self.runAppleScript("tell application \"System Events\" to key code 102")
        }
    }

    func fetchAllWindows() -> [AXWindowInfo] {
        var windows: [AXWindowInfo] = []

        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return windows
        }

        for entry in windowList {
            guard let windowIDValue = entry[kCGWindowNumber as String] as? UInt32,
                  let ownerPID = entry[kCGWindowOwnerPID as String] as? pid_t,
                  let ownerName = entry[kCGWindowOwnerName as String] as? String else {
                continue
            }

            let windowID = CGWindowID(windowIDValue)
            let title = entry[kCGWindowName as String] as? String ?? ""

            var isOnScreen = false
            if let boundsDict = entry[kCGWindowBounds as String] as? [String: Any],
               let x = boundsDict["X"] as? CGFloat,
               let y = boundsDict["Y"] as? CGFloat,
               let w = boundsDict["Width"] as? CGFloat,
               let h = boundsDict["Height"] as? CGFloat {
                let frame = CGRect(x: x, y: y, width: w, height: h)
                let screenBounds = CGDisplayBounds(CGMainDisplayID())
                isOnScreen = frame.intersects(screenBounds) && w > 0 && h > 0
            }

            windows.append(AXWindowInfo(
                windowID: windowID,
                title: title,
                appName: ownerName,
                pid: ownerPID,
                isOnScreen: isOnScreen
            ))
        }

        windows.sort { $0.appName < $1.appName }
        return windows
    }

    func focusWindow(windowID: CGWindowID) {
        guard let windowInfo = findWindowInfo(by: windowID) else { return }

        let appElement = AXUIElementCreateApplication(windowInfo.pid)

        var windowList: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowList)

        guard result == .success, let windows = windowList as? [AXUIElement] else {
            Self.activateAppByPID(windowInfo.pid)
            return
        }

        var focused = false
        for axWindow in windows {
            if Self.axWindowMatchesWindowID(axWindow, targetWindowID: windowID) {
                let raiseResult = AXUIElementSetAttributeValue(axWindow, kAXMainAttribute as CFString, kCFBooleanTrue)
                if raiseResult == .success {
                    focused = true
                }
                let frontResult = AXUIElementSetAttributeValue(axWindow, kAXFocusedAttribute as CFString, kCFBooleanTrue)
                if frontResult == .success {
                    focused = true
                }
                break
            }
        }

        if !focused {
            Self.activateAppByPID(windowInfo.pid)
        }
    }

    func closeWindow(windowID: CGWindowID) {
        guard let windowInfo = findWindowInfo(by: windowID) else { return }

        let appElement = AXUIElementCreateApplication(windowInfo.pid)
        var windowList: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowList)

        if result == .success, let windows = windowList as? [AXUIElement] {
            for axWindow in windows {
                if Self.axWindowMatchesWindowID(axWindow, targetWindowID: windowID) {
                    let closeResult = AXUIElementPerformAction(axWindow, "AXClose" as CFString)
                    if closeResult != .success {
                        if let closeButton = Self.findElement(
                            attribute: kAXCloseButtonAttribute as String,
                            in: axWindow
                        ) {
                            AXUIElementPerformAction(closeButton, kAXPressAction as CFString)
                        }
                    }
                }
            }
        }
    }

    func findButton(named: String, in windowID: CGWindowID) -> AXUIElement? {
        guard let rootElement = getUIElementTree(windowID: windowID) else { return nil }
        return Self.findUIElement(named: named, role: kAXButtonRole as String, in: rootElement)
    }

    func clickButton(named: String, in windowID: CGWindowID) -> Bool {
        guard let button = findButton(named: named, in: windowID) else { return false }
        return performAction(kAXPressAction as String, on: button)
    }

    func findTextField(named: String, in windowID: CGWindowID) -> AXUIElement? {
        guard let rootElement = getUIElementTree(windowID: windowID) else { return nil }
        return Self.findUIElement(named: named, role: kAXTextFieldRole as String, in: rootElement)
    }

    func typeInField(named: String, text: String, in windowID: CGWindowID) -> Bool {
        guard let textField = findTextField(named: named, in: windowID) else { return false }
        let result = AXUIElementSetAttributeValue(textField, kAXValueAttribute as CFString, text as CFTypeRef)
        if result != .success {
            let focusResult = AXUIElementSetAttributeValue(textField, kAXFocusedAttribute as CFString, kCFBooleanTrue)
            if focusResult == .success {
                typeText(text)
                return true
            }
            return false
        }
        return true
    }

    func getUIElementTree(windowID: CGWindowID) -> AXUIElement? {
        guard let windowInfo = findWindowInfo(by: windowID) else { return nil }
        let appElement = AXUIElementCreateApplication(windowInfo.pid)
        var windowList: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowList)
        guard result == .success, let windows = windowList as? [AXUIElement] else { return nil }
        for axWindow in windows {
            if Self.axWindowMatchesWindowID(axWindow, targetWindowID: windowID) {
                return axWindow
            }
        }
        return nil
    }

    func performAction(_ action: String, on element: AXUIElement) -> Bool {
        let result = AXUIElementPerformAction(element, action as CFString)
        return result == .success
    }

    func getAttribute(_ attribute: String, on element: AXUIElement) -> Any? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else { return nil }
        return value
    }

    func setAttribute(_ attribute: String, value: Any, on element: AXUIElement) -> Bool {
        let result = AXUIElementSetAttributeValue(element, attribute as CFString, value as CFTypeRef)
        return result == .success
    }

    func launchApp(bundleID: String) -> Bool {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return false
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { _, error in
            if let error {
                JiaLog("[InputController] Failed to launch app \(bundleID): \(error)")
            }
        }
        return true
    }

    func runningApplications() -> [NSRunningApplication] {
        return NSWorkspace.shared.runningApplications
    }

    func getUIElementRoot(for pid: pid_t) -> AXUIElement {
        return AXUIElementCreateApplication(pid)
    }

    func wakeDisplay() {
        commandQueue.async {
            _ = Self.runAppleScript("tell application \"System Events\" to key code 102")
        }
    }

    func sleepSystem() {
        commandQueue.async {
            _ = Self.runAppleScript("tell application \"System Events\" to sleep")
        }
    }

    func restartSystem() {
        commandQueue.async {
            _ = Self.runAppleScript("tell application \"System Events\" to restart")
        }
    }

    func shutdownSystem() {
        commandQueue.async {
            _ = Self.runAppleScript("tell application \"System Events\" to shut down")
        }
    }

    func checkAccessibilityPermission() -> Bool {
        let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    func requestAccessibilityPermission() {
        let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    func fetchWindowList() -> [(windowID: CGWindowID, title: String, ownerName: String)] {
        var windowList: [(windowID: CGWindowID, title: String, ownerName: String)] = []

        guard let list = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return windowList
        }

        for entry in list {
            guard let windowIDValue = entry[kCGWindowNumber as String] as? UInt32,
                  let ownerName = entry[kCGWindowOwnerName as String] as? String else {
                continue
            }
            let windowID = CGWindowID(windowIDValue)
            let title = entry[kCGWindowName as String] as? String ?? ""
            windowList.append((windowID: windowID, title: title, ownerName: ownerName))
        }

        return windowList
    }

    func focusWindowAX(windowID: CGWindowID) -> Bool {
        guard let windowInfo = findWindowInfo(by: windowID) else { return false }

        let appElement = AXUIElementCreateApplication(windowInfo.pid)

        var windowList: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowList)

        guard result == .success, let windows = windowList as? [AXUIElement] else {
            Self.activateAppByPID(windowInfo.pid)
            return true
        }

        for axWindow in windows {
            if Self.axWindowMatchesWindowID(axWindow, targetWindowID: windowID) {
                AXUIElementSetAttributeValue(axWindow, kAXMainAttribute as CFString, kCFBooleanTrue)
                AXUIElementSetAttributeValue(axWindow, kAXFocusedAttribute as CFString, kCFBooleanTrue)
                return true
            }
        }

        Self.activateAppByPID(windowInfo.pid)
        return true
    }

    func closeWindowAX(windowID: CGWindowID) -> Bool {
        guard let windowInfo = findWindowInfo(by: windowID) else { return false }

        let appElement = AXUIElementCreateApplication(windowInfo.pid)
        var windowList: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowList)

        if result == .success, let windows = windowList as? [AXUIElement] {
            for axWindow in windows {
                if Self.axWindowMatchesWindowID(axWindow, targetWindowID: windowID) {
                    let closeResult = AXUIElementPerformAction(axWindow, "AXClose" as CFString)
                    if closeResult != .success {
                        if let closeButton = Self.findElement(
                            attribute: kAXCloseButtonAttribute as String,
                            in: axWindow
                        ) {
                            AXUIElementPerformAction(closeButton, kAXPressAction as CFString)
                        }
                    }
                    return true
                }
            }
        }
        return false
    }

    func getUIElementTreeForPID(_ pid: pid_t) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(pid)
        var windowList: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowList)
        guard result == .success, let windows = windowList as? [AXUIElement], !windows.isEmpty else {
            return nil
        }
        return windows.first
    }

    func performActionAX(on element: AXUIElement, action: String) -> Bool {
        let result = AXUIElementPerformAction(element, action as CFString)
        return result == .success
    }

    func getUIElementAttribute(_ element: AXUIElement, attribute: String) -> Any? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else { return nil }
        return value
    }
}

extension InputController {

    func injectMouseMove(x: Float, y: Float) {
        let screenPoint = normalizedToScreen(x: x, y: y)
        currentMouseLocation = screenPoint
        guard let event = CGEvent(mouseEventSource: nil,
                                   mouseType: .mouseMoved,
                                   mouseCursorPosition: screenPoint,
                                   mouseButton: .left) else { return }
        event.post(tap: .cghidEventTap)
    }

    func injectMouseDown(button: CGMouseButton) {
        let eventType = Self.mouseDownEventType(for: button)
        guard let event = CGEvent(mouseEventSource: nil,
                                   mouseType: eventType,
                                   mouseCursorPosition: currentMouseLocation,
                                   mouseButton: button) else { return }
        event.post(tap: .cghidEventTap)
    }

    func injectMouseUp(button: CGMouseButton) {
        let eventType = Self.mouseUpEventType(for: button)
        guard let event = CGEvent(mouseEventSource: nil,
                                   mouseType: eventType,
                                   mouseCursorPosition: currentMouseLocation,
                                   mouseButton: button) else { return }
        event.post(tap: .cghidEventTap)
    }

    func injectMouseClick(at point: CGPoint, button: CGMouseButton) {
        currentMouseLocation = point

        guard let moveEvent = CGEvent(mouseEventSource: nil,
                                       mouseType: .mouseMoved,
                                       mouseCursorPosition: point,
                                       mouseButton: .left) else { return }
        moveEvent.post(tap: .cghidEventTap)

        let eventTypeDown = Self.mouseDownEventType(for: button)
        let eventTypeUp = Self.mouseUpEventType(for: button)

        guard let downEvent = CGEvent(mouseEventSource: nil,
                                       mouseType: eventTypeDown,
                                       mouseCursorPosition: point,
                                       mouseButton: button) else { return }
        guard let upEvent = CGEvent(mouseEventSource: nil,
                                     mouseType: eventTypeUp,
                                     mouseCursorPosition: point,
                                     mouseButton: button) else { return }

        downEvent.post(tap: .cghidEventTap)
        usleep(Self.clickInterval)
        upEvent.post(tap: .cghidEventTap)
    }

    func injectMouseDblClick(at point: CGPoint, button: CGMouseButton) {
        currentMouseLocation = point

        guard let moveEvent = CGEvent(mouseEventSource: nil,
                                       mouseType: .mouseMoved,
                                       mouseCursorPosition: point,
                                       mouseButton: .left) else { return }
        moveEvent.post(tap: .cghidEventTap)

        let eventTypeDown = Self.mouseDownEventType(for: button)
        let eventTypeUp = Self.mouseUpEventType(for: button)

        guard let down1 = CGEvent(mouseEventSource: nil,
                                   mouseType: eventTypeDown,
                                   mouseCursorPosition: point,
                                   mouseButton: button),
              let up1 = CGEvent(mouseEventSource: nil,
                                 mouseType: eventTypeUp,
                                 mouseCursorPosition: point,
                                 mouseButton: button) else { return }

        down1.post(tap: .cghidEventTap)
        usleep(Self.clickInterval)
        up1.post(tap: .cghidEventTap)

        usleep(Self.dblClickInterval)

        guard let down2 = CGEvent(mouseEventSource: nil,
                                   mouseType: eventTypeDown,
                                   mouseCursorPosition: point,
                                   mouseButton: button),
              let up2 = CGEvent(mouseEventSource: nil,
                                 mouseType: eventTypeUp,
                                 mouseCursorPosition: point,
                                 mouseButton: button) else { return }

        down2.post(tap: .cghidEventTap)
        usleep(Self.clickInterval)
        up2.post(tap: .cghidEventTap)
    }

    func injectScroll(deltaY: Float, deltaX: Float) {
        let pixPerLine: Int64 = 10
        let dY = Double(deltaY)
        let dX = Double(deltaX)
        var pixelDeltaX = Int64(dX * Self.scrollPixelMultiplier * Double(pixPerLine))
        var pixelDeltaY = Int64(dY * Self.scrollPixelMultiplier * Double(pixPerLine))

        guard let event = CGEvent(scrollWheelEvent2Source: nil, units: .line,
                                   wheelCount: 2, wheel1: Int32(-dY), wheel2: Int32(dX), wheel3: 0) else { return }
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 0)

        let linesX = Int64(dX)
        let linesY = Int64(dY)
        let limit: Int64 = Int64(UInt32.max)

        if pixelDeltaX < -limit { pixelDeltaX = -limit }
        else if pixelDeltaX > limit { pixelDeltaX = limit }
        if pixelDeltaY < -limit { pixelDeltaY = -limit }
        else if pixelDeltaY > limit { pixelDeltaY = limit }

        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: linesX)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: linesY)
        event.setIntegerValueField(.scrollWheelEventFixedPtDeltaAxis2, value: pixelDeltaX)
        event.setIntegerValueField(.scrollWheelEventFixedPtDeltaAxis1, value: pixelDeltaY)
        event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: linesX)
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: linesY)

        event.setIntegerValueField(.scrollWheelEventMomentumPhase, value: 0)
        event.setIntegerValueField(.scrollWheelEventScrollPhase, value: 1)
        event.setIntegerValueField(.scrollWheelEventScrollCount, value: 1)

        event.setIntegerValueField(CGEventField(rawValue: 133)!, value: pixPerLine)
        event.setIntegerValueField(.scrollWheelEventInstantMouser, value: 1)
        event.setIntegerValueField(CGEventField(rawValue: 146)!, value: 1)

        event.post(tap: .cghidEventTap)
    }

    func injectKeyDown(keyCode: CGKeyCode, flags: CGEventFlags) {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) else { return }
        event.flags = flags
        event.post(tap: .cghidEventTap)
    }

    func injectKeyUp(keyCode: CGKeyCode, flags: CGEventFlags) {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else { return }
        event.flags = flags
        event.post(tap: .cghidEventTap)
    }

    func injectKeyPress(keyCode: CGKeyCode, flags: CGEventFlags) {
        injectKeyDown(keyCode: keyCode, flags: flags)
        usleep(10000)
        injectKeyUp(keyCode: keyCode, flags: flags)
    }

    func injectKeyCombo(keyCodes: [CGKeyCode], flags: CGEventFlags) {
        for keyCode in keyCodes {
            injectKeyDown(keyCode: keyCode, flags: flags)
            usleep(10000)
        }
        for keyCode in keyCodes.reversed() {
            injectKeyUp(keyCode: keyCode, flags: flags)
            usleep(10000)
        }
    }

    func fetchRunningApplications() -> [NSRunningApplication] {
        return NSWorkspace.shared.runningApplications
    }

    func launchApplication(bundleID: String) {
        commandQueue.async {
            guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
                return
            }
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { _, error in
                if let error {
                    JiaLog("[InputController] Failed to launch app \(bundleID): \(error)")
                }
            }
        }
    }
}

private extension InputController {

    static func mouseDownEventType(for button: CGMouseButton) -> CGEventType {
        switch button {
        case .left:
            return .leftMouseDown
        case .right:
            return .rightMouseDown
        case .center:
            return .otherMouseDown
        @unknown default:
            return .otherMouseDown
        }
    }

    static func mouseUpEventType(for button: CGMouseButton) -> CGEventType {
        switch button {
        case .left:
            return .leftMouseUp
        case .right:
            return .rightMouseUp
        case .center:
            return .otherMouseUp
        @unknown default:
            return .otherMouseUp
        }
    }

    @discardableResult
    static func runAppleScript(_ script: String) -> Bool {
        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else {
            return false
        }
        appleScript.executeAndReturnError(&error)
        return error == nil
    }

    static func mapCharacterToKey(_ utf16Char: UInt16, keyCode: inout CGKeyCode, modifierFlags: inout CGEventFlags) {
        let lowerChar = utf16Char

        switch lowerChar {
        case 0x61...0x7A:
            keyCode = CGKeyCode(lowerChar - 0x61 + UInt16(kVK_ANSI_A))
        case 0x41...0x5A:
            keyCode = CGKeyCode(lowerChar - 0x41 + UInt16(kVK_ANSI_A))
            modifierFlags = .maskShift
        case 0x30...0x39:
            keyCode = CGKeyCode(lowerChar - 0x30 + UInt16(kVK_ANSI_0))
        case 0x20:
            keyCode = CGKeyCode(kVK_Space)
        case 0x0D:
            keyCode = CGKeyCode(kVK_Return)
        case 0x1B:
            keyCode = CGKeyCode(kVK_Escape)
        case 0x09:
            keyCode = CGKeyCode(kVK_Tab)
        case 0x08:
            keyCode = CGKeyCode(kVK_Delete)
        case 0x2E:
            keyCode = CGKeyCode(kVK_ANSI_Period)
        case 0x2C:
            keyCode = CGKeyCode(kVK_ANSI_Comma)
        case 0x2F:
            keyCode = CGKeyCode(kVK_ANSI_Slash)
        case 0x3B:
            keyCode = CGKeyCode(kVK_ANSI_Semicolon)
        case 0x27:
            keyCode = CGKeyCode(kVK_ANSI_Quote)
        case 0x5B:
            keyCode = CGKeyCode(kVK_ANSI_LeftBracket)
        case 0x5D:
            keyCode = CGKeyCode(kVK_ANSI_RightBracket)
        case 0x5C:
            keyCode = CGKeyCode(kVK_ANSI_Backslash)
        case 0x2D:
            keyCode = CGKeyCode(kVK_ANSI_Minus)
        case 0x3D:
            keyCode = CGKeyCode(kVK_ANSI_Equal)
        case 0x60:
            keyCode = CGKeyCode(kVK_ANSI_Grave)
        case 0x21:
            keyCode = CGKeyCode(kVK_ANSI_1)
            modifierFlags = .maskShift
        case 0x40:
            keyCode = CGKeyCode(kVK_ANSI_2)
            modifierFlags = .maskShift
        case 0x23:
            keyCode = CGKeyCode(kVK_ANSI_3)
            modifierFlags = .maskShift
        case 0x24:
            keyCode = CGKeyCode(kVK_ANSI_4)
            modifierFlags = .maskShift
        case 0x25:
            keyCode = CGKeyCode(kVK_ANSI_5)
            modifierFlags = .maskShift
        case 0x5E:
            keyCode = CGKeyCode(kVK_ANSI_6)
            modifierFlags = .maskShift
        case 0x26:
            keyCode = CGKeyCode(kVK_ANSI_7)
            modifierFlags = .maskShift
        case 0x2A:
            keyCode = CGKeyCode(kVK_ANSI_8)
            modifierFlags = .maskShift
        case 0x28:
            keyCode = CGKeyCode(kVK_ANSI_9)
            modifierFlags = .maskShift
        case 0x29:
            keyCode = CGKeyCode(kVK_ANSI_0)
            modifierFlags = .maskShift
        default:
            keyCode = CGKeyCode(kVK_ANSI_A)
        }
    }

    static func lockScreenViaSAC() -> Bool {
        typealias SACLockScreenImmediateFunc = @convention(c) () -> Void
        guard let handle = dlopen("/System/Library/PrivateFrameworks/login.framework/login", RTLD_LAZY) else {
            return false
        }
        defer { dlclose(handle) }
        guard let sym = dlsym(handle, "SACLockScreenImmediate") else {
            return false
        }
        let lockFunc = unsafeBitCast(sym, to: SACLockScreenImmediateFunc.self)
        lockFunc()
        return true
    }

    static func lockScreenViaCGSSession() -> Bool {
        typealias CGSessionCopyCurrentDictionaryFunc = @convention(c) () -> CFDictionary?
        guard let handle = dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_LAZY) else {
            return false
        }
        defer { dlclose(handle) }
        guard let sym = dlsym(handle, "CGSessionCopyCurrentDictionary"),
              let dict = unsafeBitCast(sym, to: CGSessionCopyCurrentDictionaryFunc.self)() else {
            return false
        }
        guard let kCGSSessionOnConsoleKey = dlsym(handle, "kCGSSessionOnConsoleKey") else {
            return false
        }
        let key = UnsafeRawPointer(kCGSSessionOnConsoleKey)
        if let value = CFDictionaryGetValue(dict, key) {
            let numValue = Unmanaged<CFNumber>.fromOpaque(value).takeUnretainedValue()
            var isOnConsole: Int = 0
            if CFNumberGetValue(numValue, .intType, &isOnConsole), isOnConsole == 1 {
                if let suspendSym = dlsym(handle, "CGSSuspendConsole") {
                    typealias CGSSuspendConsoleFunc = @convention(c) () -> Int32
                    let suspend = unsafeBitCast(suspendSym, to: CGSSuspendConsoleFunc.self)
                    return suspend() == 0
                }
            }
        }
        return false
    }

    static func lockScreenViaKeyCombo() {
        guard let ctrlDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Control), keyDown: true),
              let cmdDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Command), keyDown: true),
              let qDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_Q), keyDown: true) else { return }

        ctrlDown.flags = CGEventFlags.maskControl
        cmdDown.flags = [CGEventFlags.maskControl, CGEventFlags.maskCommand]
        qDown.flags = [CGEventFlags.maskControl, CGEventFlags.maskCommand]

        ctrlDown.post(tap: CGEventTapLocation.cghidEventTap)
        usleep(10000)
        cmdDown.post(tap: CGEventTapLocation.cghidEventTap)
        usleep(10000)
        qDown.post(tap: CGEventTapLocation.cghidEventTap)
        usleep(20000)

        guard let qUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_Q), keyDown: false),
              let cmdUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Command), keyDown: false),
              let ctrlUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Control), keyDown: false) else { return }

        qUp.post(tap: CGEventTapLocation.cghidEventTap)
        usleep(10000)
        cmdUp.post(tap: CGEventTapLocation.cghidEventTap)
        usleep(10000)
        ctrlUp.post(tap: CGEventTapLocation.cghidEventTap)
    }

    static func setBrightnessViaIOKit(_ level: Float) -> Bool {
        var iterator: io_iterator_t = 0
        let matchResult = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IODisplayConnect"),
            &iterator
        )
        guard matchResult == kIOReturnSuccess else { return false }

        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        var brightnessSet = false

        while service != 0 {
            let clampedLevel = max(0, min(1, level))
            let floatLevel: Float = clampedLevel

            let result = IODisplaySetFloatParameter(service, 0, "brightness" as CFString, floatLevel)
            if result == kIOReturnSuccess {
                brightnessSet = true
            }

            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }

        return brightnessSet
    }

    static func adjustBrightnessViaIOKit(_ up: Bool) -> Bool {
        var iterator: io_iterator_t = 0
        let matchResult = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IODisplayConnect"),
            &iterator
        )
        guard matchResult == kIOReturnSuccess else { return false }

        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        var adjusted = false

        while service != 0 {
            var currentBrightness: Float = 0.5
            IODisplayGetFloatParameter(service, 0, "brightness" as CFString, &currentBrightness)

            let step: Float = 0.0625
            let newLevel = up
                ? min(1.0, currentBrightness + step)
                : max(0.0, currentBrightness - step)

            let result = IODisplaySetFloatParameter(service, 0, "brightness" as CFString, newLevel)
            if result == kIOReturnSuccess {
                adjusted = true
            }

            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }

        return adjusted
    }

    static func getBrightnessLevel() -> Float {
        var iterator: io_iterator_t = 0
        let matchResult = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IODisplayConnect"),
            &iterator
        )
        guard matchResult == kIOReturnSuccess else { return 0.5 }

        defer { IOObjectRelease(iterator) }

        let service = IOIteratorNext(iterator)
        var brightness: Float = 0.5

        if service != 0 {
            IODisplayGetFloatParameter(service, 0, "brightness" as CFString, &brightness)
            IOObjectRelease(service)
        }

        return brightness
    }

    static func findUIElement(named targetName: String, role targetRole: String, in element: AXUIElement) -> AXUIElement? {
        var nameValue: CFTypeRef?
        let nameResult = AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &nameValue)

        if nameResult == .success,
           let name = nameValue as? String,
           name.localizedCaseInsensitiveContains(targetName) {
            var roleValue: CFTypeRef?
            let roleResult = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
            if roleResult == .success,
               let role = roleValue as? String,
               role == targetRole {
                return element
            }
        }

        var childrenValue: CFTypeRef?
        let childrenResult = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue)
        guard childrenResult == .success, let children = childrenValue as? [AXUIElement] else { return nil }

        for child in children {
            if let found = findUIElement(named: targetName, role: targetRole, in: child) {
                return found
            }
        }

        return nil
    }

    static func findElement(attribute: String, in element: AXUIElement) -> AXUIElement? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else { return nil }
        return (value as! AXUIElement)
    }

    func findWindowInfo(by windowID: CGWindowID) -> AXWindowInfo? {
        return fetchAllWindows().first { $0.windowID == windowID }
    }

    static func axWindowMatchesWindowID(_ axWindow: AXUIElement, targetWindowID: CGWindowID) -> Bool {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?

        guard AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute as CFString, &sizeValue) == .success else {
            return false
        }

        var axPoint = CGPoint.zero
        var axSize = CGSize.zero

        guard let positionRef = positionValue,
              AXValueGetValue(positionRef as! AXValue, .cgPoint, &axPoint),
              let sizeRef = sizeValue,
              AXValueGetValue(sizeRef as! AXValue, .cgSize, &axSize) else {
            return false
        }

        let axFrame = CGRect(origin: axPoint, size: axSize)

        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return false
        }

        for entry in windowList {
            guard let wid = entry[kCGWindowNumber as String] as? UInt32,
                  CGWindowID(wid) == targetWindowID,
                  let boundsDict = entry[kCGWindowBounds as String] as? [String: Any],
                  let x = boundsDict["X"] as? CGFloat,
                  let y = boundsDict["Y"] as? CGFloat,
                  let w = boundsDict["Width"] as? CGFloat,
                  let h = boundsDict["Height"] as? CGFloat else {
                continue
            }

            let cgFrame = CGRect(x: x, y: y, width: w, height: h)

            if abs(axFrame.origin.x - cgFrame.origin.x) < 2 &&
               abs(axFrame.origin.y - cgFrame.origin.y) < 2 &&
               abs(axFrame.size.width - cgFrame.size.width) < 2 &&
               abs(axFrame.size.height - cgFrame.size.height) < 2 {
                return true
            }
        }

        return false
    }

    static func activateAppByPID(_ pid: pid_t) {
        if let app = NSRunningApplication(processIdentifier: pid) {
            app.activate(options: [.activateIgnoringOtherApps])
        }
    }
}
