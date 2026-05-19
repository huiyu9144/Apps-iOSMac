import Cocoa
import SwiftUI
import ServiceManagement
import ApplicationServices

extension Notification.Name {
    static let showFirstLaunchWindow = Notification.Name("showFirstLaunchWindow")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var firstLaunchWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController = MenuBarController()
        menuBarController?.setup()

        NotificationCenter.default.addObserver(self, selector: #selector(handleShowFirstLaunchWindow), name: .showFirstLaunchWindow, object: nil)

        let settings = AppSettings.shared
        let perms = PermissionManager.shared

        let needsSetup = !settings.hasCompletedFirstLaunch || !perms.allGranted

        if needsSetup {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showFirstLaunchWindow()
            }
        }
    }

    @objc private func handleShowFirstLaunchWindow() {
        guard firstLaunchWindow == nil else { return }
        showFirstLaunchWindow()
    }

    private func showFirstLaunchWindow() {
        let view = FirstLaunchView(
            onClose: { [weak self] in
                AppSettings.shared.hasCompletedFirstLaunch = true
                self?.firstLaunchWindow?.close()
                self?.firstLaunchWindow = nil
            },
            onOpenSettings: { [weak self] in
                AppSettings.shared.hasCompletedFirstLaunch = true
                self?.firstLaunchWindow?.close()
                self?.firstLaunchWindow = nil
                self?.menuBarController?.showSettings()
            }
        )

        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 340, height: 460)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 460),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "QuickOCR"
        window.isMovableByWindowBackground = true
        window.styleMask.remove(.resizable)
        window.center()
        window.contentView = hosting
        window.delegate = self
        window.isReleasedWhenClosed = false

        self.firstLaunchWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        firstLaunchWindow?.close()
        firstLaunchWindow = nil
        menuBarController?.cleanup()
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == firstLaunchWindow {
            AppSettings.shared.hasCompletedFirstLaunch = true
            firstLaunchWindow = nil
        }
    }
}

class PermissionManager {
    static let shared = PermissionManager()

    var screenRecordingGranted: Bool {
        if #available(macOS 11.0, *) {
            return CGPreflightScreenCaptureAccess()
        }
        return false
    }

    var accessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    var allGranted: Bool {
        screenRecordingGranted && accessibilityGranted
    }

    func requestScreenRecording() {
        if #available(macOS 11.0, *) {
            CGRequestScreenCaptureAccess()
        } else {
            openScreenRecordingPrefs()
        }
    }

    func openScreenRecordingPrefs() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
    }

    func openAccessibilityPrefs() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    func openPrivacyPrefs() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
    }
}

// MARK: - First Launch View

struct SystemPermission: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
    let isGranted: Bool
}

struct FirstLaunchView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var isRecording = false
    @State private var recordedKey: String = {
        KeyboardShortcutManager.keyCodeToCharacter(AppSettings.shared.shortcutKeyCode)
    }()
    @State private var keyMonitor: Any?

    let onClose: () -> Void
    let onOpenSettings: () -> Void

    private var allGranted: Bool {
        PermissionManager.shared.allGranted
    }

    private var permissionItems: [SystemPermission] {
        let perms = PermissionManager.shared
        return [
            SystemPermission(
                name: "Screen Recording",
                icon: "display",
                description: "Required to capture screen content for OCR text recognition.",
                isGranted: perms.screenRecordingGranted
            ),
            SystemPermission(
                name: "Accessibility",
                icon: "figure.accessibility",
                description: "Required to listen for the global screenshot hotkey.",
                isGranted: perms.accessibilityGranted
            )
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    Image(systemName: "text.viewfinder")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)

                    Text("Welcome to QuickOCR")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top, 20)

                if !allGranted {
                    permissionsSection
                        .padding(.top, 12)
                }

                shortcutSection
                    .padding(.top, allGranted ? 16 : 8)

                Divider()
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)

                HStack(spacing: 12) {
                    Button(action: onClose) {
                        Text(allGranted ? "Close" : "Skip")
                            .frame(width: 80)
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.escape)

                    Button(action: onOpenSettings) {
                        Text("Settings")
                            .frame(width: 80)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.bottom, 16)
            }
        }
        .frame(width: 340)
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
                        self.recordedKey = keyStr.uppercased()
                        self.keyMonitor = nil
                        self.isRecording = false
                    }
                    return nil
                }
            }
        }
        .onDisappear {
            if let existing = keyMonitor as? NSObjectProtocol {
                NSEvent.removeMonitor(existing)
                keyMonitor = nil
            }
        }
    }

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Required Permissions")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal, 24)

            ForEach(permissionItems) { perm in
                HStack(spacing: 10) {
                    Image(systemName: perm.isGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(perm.isGranted ? .green : .orange)
                        .font(.system(size: 16))

                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Image(systemName: perm.icon)
                                .font(.caption)
                            Text(perm.name)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        Text(perm.description)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    if !perm.isGranted {
                        Button(perm.name == "Screen Recording" ? "Allow" : "Grant") {
                            if perm.name == "Screen Recording" {
                                PermissionManager.shared.requestScreenRecording()
                            } else {
                                PermissionManager.shared.openAccessibilityPrefs()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, 24)
            }

            Text("After granting permission, restart the app for changes to take effect.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
        }
    }

    private var shortcutSection: some View {
        VStack(spacing: 8) {
            Text("Capture Shortcut")
                .font(.subheadline)
                .fontWeight(.semibold)

            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isRecording ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 200, height: 48)

                if isRecording {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.5)
                        Text("Press a key...")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                    }
                } else {
                    Text("\u{2318}+\u{21E7}+\(recordedKey)")
                        .font(.title)
                        .fontWeight(.medium)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isRecording = true
            }

            Button("Record Shortcut") {
                isRecording = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }
}
