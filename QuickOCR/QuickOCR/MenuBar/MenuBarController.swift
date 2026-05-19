import Cocoa
import SwiftUI

class MenuBarController: NSObject, NSPopoverDelegate {
    static weak var shared: MenuBarController?

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var settingsPopover: NSPopover?
    private var conflictPopoverWindow: NSWindow?
    private var isPopoverShown = false
    private var outsideClickMonitor: Any?
    private var recognitionManager = RecognitionManager.shared
    private var history = CaptureHistory.shared
    private var settings = AppSettings.shared

    func setup() {
        MenuBarController.shared = self

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = statusItem

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: "QuickOCR")
            image?.isTemplate = true
            button.image = image
            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 220)
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: MenuBarContentView())
        self.popover = popover

        startHotkey()
    }

    func popoverDidClose(_ notification: Notification) {
        if let popover = notification.object as? NSPopover, popover == self.popover {
            closePopover()
        }
    }

    private func startHotkey() {
        let ok = KeyboardShortcutManager.shared.register(
            keyCode: settings.shortcutKeyCode,
            modifiers: settings.shortcutModifiers
        ) { [weak self] in
            self?.startCapture()
        }
        if !ok {
            showShortcutConflict()
        }
    }

    func restartHotkey() {
        KeyboardShortcutManager.shared.unregister()
        startHotkey()
    }

    private func showShortcutConflict() {
        guard let button = statusItem?.button else { return }

        conflictPopoverWindow?.orderOut(nil)
        conflictPopoverWindow = nil

        let shortcutStr = KeyboardShortcutManager.shortcutDisplayString(keyCode: settings.shortcutKeyCode, modifiers: settings.shortcutModifiers)
        let view = ShortcutConflictView(shortcut: shortcutStr) { [weak self] in
            self?.conflictPopoverWindow?.orderOut(nil)
            self?.conflictPopoverWindow = nil
            self?.showSettings()
        }

        let hosting = NSHostingView(rootView: view)
        let width: CGFloat = 300
        let height: CGFloat = 120
        hosting.frame = NSRect(x: 0, y: 0, width: width, height: height)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.ignoresMouseEvents = false
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentView = hosting

        let buttonRect = button.convert(button.bounds, to: nil)
        let screenRect = button.window?.convertToScreen(buttonRect) ?? .zero
        let windowX = screenRect.midX - width / 2
        let windowY = screenRect.minY - height - 8
        window.setFrameOrigin(NSPoint(x: windowX, y: windowY))
        window.orderFront(nil)

        self.conflictPopoverWindow = window
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if isPopoverShown {
            closePopover()
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            isPopoverShown = true
            startOutsideClickMonitor()
        }
    }

    private func closePopover() {
        popover?.performClose(nil)
        isPopoverShown = false
        stopOutsideClickMonitor()
    }

    private func startOutsideClickMonitor() {
        stopOutsideClickMonitor()
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func stopOutsideClickMonitor() {
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
    }


    private func startCapture() {
        closePopover()
        CaptureService.shared.startCapture()
    }

    func showSettings() {
        closePopover()

        if settingsPopover?.isShown == true {
            settingsPopover?.performClose(nil)
            settingsPopover = nil
            return
        }

        let settingsPopover = NSPopover()
        settingsPopover.contentSize = NSSize(width: 400, height: 360)
        settingsPopover.behavior = .transient
        settingsPopover.delegate = self
        settingsPopover.contentViewController = NSHostingController(rootView: SettingsView())
        self.settingsPopover = settingsPopover

        if let button = statusItem?.button {
            settingsPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func showFirstLaunchWindow() {
        closePopover()
        NotificationCenter.default.post(name: .showFirstLaunchWindow, object: nil)
    }

    func cleanup() {
        KeyboardShortcutManager.shared.unregister()
        stopOutsideClickMonitor()
        conflictPopoverWindow?.orderOut(nil)
        conflictPopoverWindow = nil
    }
}

struct ShortcutConflictView: View {
    let shortcut: String
    let onChangeShortcut: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                Text("Shortcut Conflict")
                    .font(.headline)
            }

            Text("\"\(shortcut)\" is already in use by another app. QuickOCR cannot use this shortcut.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button("Change Shortcut") {
                onChangeShortcut()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor).opacity(0.96))
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
        )
    }
}

struct MenuBarContentView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var isRecording = false
    @State private var keyMonitor: Any?

    private var shortcutDisplay: String {
        "⌘+⇧+\(keyCodeToCharacter(settings.shortcutKeyCode))"
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "text.viewfinder")
                        .font(.system(size: 14, weight: .medium))
                    Text("QuickOCR")
                        .font(.headline)
                }
                .padding(.top, 16)

                Group {
                    if isRecording {
                        Text("Press a key...")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                    } else {
                        Text(shortcutDisplay)
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                }
                .frame(height: 36)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isRecording ? Color.clear : Color(.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isRecording ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                )
                .padding(.horizontal, 20)
                .contentShape(Rectangle())
                .onTapGesture {
                    isRecording = true
                }
            }
            .padding(.bottom, 16)

            Divider()
                .padding(.horizontal, 16)

            HStack(spacing: 0) {
                Button(action: { MenuBarController.shared?.showFirstLaunchWindow() }) {
                    Label("Home", systemImage: "house")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                Divider()
                    .frame(height: 24)

                Button(action: { MenuBarController.shared?.showSettings() }) {
                    Label("Settings", systemImage: "gearshape")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                Divider()
                    .frame(height: 24)

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Label("Quit", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
        .frame(width: 280)
        .onChange(of: isRecording) { _, newValue in
            if let existing = keyMonitor as? NSObjectProtocol {
                NSEvent.removeMonitor(existing)
                keyMonitor = nil
            }
            if newValue {
                keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    guard let chars = event.charactersIgnoringModifiers, !chars.isEmpty else { return event }
                    let keyStr = chars.uppercased().first.map(String.init) ?? chars.uppercased()
                    let code = KeyboardShortcutManager.carbonKeyCode(from: keyStr)
                    AppSettings.shared.shortcutKeyCode = code
                    AppSettings.shared.shortcutModifiers = 768
                    MenuBarController.shared?.restartHotkey()
                    DispatchQueue.main.async {
                        self.keyMonitor = nil
                        self.isRecording = false
                    }
                    return nil
                }
            }
        }
    }

    private func keyCodeToCharacter(_ code: Int) -> String {
        let map: [Int: String] = [
            0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H",
            34: "I", 38: "J", 40: "K", 37: "L", 46: "M", 45: "N", 31: "O", 35: "P",
            12: "Q", 15: "R", 1: "S", 17: "T", 32: "U", 9: "V", 13: "W", 7: "X",
            16: "Y", 6: "Z"
        ]
        return map[code] ?? "?"
    }
}
