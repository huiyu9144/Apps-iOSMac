import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var isRecording = false
    @State private var recordedKey: String = "A"
    @State private var keyMonitor: Any?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close")
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            TabView {
                generalTab
                    .tabItem {
                        Label("General", systemImage: "gearshape")
                    }

                shortcutTab
                    .tabItem {
                        Label("Shortcut", systemImage: "keyboard")
                    }

                languageTab
                    .tabItem {
                        Label("Languages", systemImage: "globe")
                    }
            }
            .frame(width: 400, height: 300)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(width: 400)
    }

    private var generalTab: some View {
        Form {
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                .onChange(of: settings.launchAtLogin) { _, newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        print("Failed to update login item: \(error)")
                    }
                }

            Toggle("Auto-Copy to Clipboard", isOn: $settings.autoCopy)

            Picker("Notification Mode", selection: $settings.notificationMode) {
                ForEach(NotificationMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.radioGroup)
        }
        .padding()
    }

    private var shortcutTab: some View {
        VStack(spacing: 16) {
            Text("Press the shortcut you want to use for capturing text")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isRecording ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 200, height: 44)

                if isRecording {
                    Text("Press a key...")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                } else {
                    Text("⌘+⇧+\(recordedKey)")
                        .font(.title2)
                }
            }
            .onTapGesture {
                isRecording = true
            }

            Button("Record Shortcut") {
                isRecording = true
            }
            .buttonStyle(.borderedProminent)

            Button("Reset to Default") {
                resetShortcut()
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding()
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
    }

    private var languageTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select recognition languages")
                .font(.subheadline)
                .foregroundColor(.secondary)

            List(LanguageManager.shared.availableLanguages) { lang in
                HStack {
                    Text(lang.displayName)
                        .font(.body)
                    Spacer()
                    if settings.recognitionLanguages.contains(lang.code) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleLanguage(lang.code)
                }
            }
            .listStyle(.plain)
        }
        .padding()
    }

    private func toggleLanguage(_ code: String) {
        if settings.recognitionLanguages.contains(code) {
            if settings.recognitionLanguages.count > 1 {
                settings.recognitionLanguages.removeAll { $0 == code }
            }
        } else {
            settings.recognitionLanguages.append(code)
        }
    }

    private func resetShortcut() {
        settings.shortcutKeyCode = 0
        settings.shortcutModifiers = 768
        recordedKey = "A"
    }
}
