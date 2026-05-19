import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject private var captureManager: CaptureManager
    @AppStorage("saveToDesktop") private var saveToDesktop = true
    @AppStorage("autoCopyToClipboard") private var autoCopyToClipboard = true
    @AppStorage("showFloatingThumbnail") private var showFloatingThumbnail = true
    @AppStorage("playCaptureSound") private var playCaptureSound = false

    @State private var customSavePath = ""
    @State private var shortcutRegion = "⌘⇧4"
    @State private var shortcutWindow = "⌘⇧5"
    @State private var shortcutFullscreen = "⌘⇧6"
    @State private var shortcutScrolling = "⌘⇧7"

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            shortcutsTab
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 360)
    }

    private var generalTab: some View {
        Form {
            Section("Save") {
                Toggle("Save to Desktop", isOn: $saveToDesktop)
                    .onChange(of: saveToDesktop) { _, newValue in
                        if newValue {
                            let paths = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)
                            captureManager.saveDirectory = paths.first ?? FileManager.default.temporaryDirectory
                        }
                    }

                if !saveToDesktop {
                    HStack {
                        TextField("Custom Path", text: $customSavePath)
                            .textFieldStyle(.roundedBorder)

                        Button("Browse...") {
                            selectSaveDirectory()
                        }
                    }
                }

                Toggle("Auto-copy to Clipboard", isOn: $autoCopyToClipboard)

                Toggle("Show floating thumbnail preview", isOn: $showFloatingThumbnail)
            }

            Section("Capture") {
                Toggle("Play capture sound", isOn: $playCaptureSound)
            }

            Section("History") {
                HStack {
                    Text("CleanShot keeps your last 20 screenshots")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    private var shortcutsTab: some View {
        Form {
            Section("Capture Shortcuts") {
                ShortcutField(label: "Capture Region", shortcut: $shortcutRegion)
                ShortcutField(label: "Capture Window", shortcut: $shortcutWindow)
                ShortcutField(label: "Capture Fullscreen", shortcut: $shortcutFullscreen)
                ShortcutField(label: "Scrolling Capture", shortcut: $shortcutScrolling)
            }

            Section {
                HStack {
                    Spacer()
                    Button("Restore Defaults") {
                        shortcutRegion = "⌘⇧4"
                        shortcutWindow = "⌘⇧5"
                        shortcutFullscreen = "⌘⇧6"
                        shortcutScrolling = "⌘⇧7"
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                }
            }
        }
        .padding()
    }

    private var aboutTab: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("CleanShot")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("A lightweight screen capture tool that lives in your menu bar. Capture, annotate, and share — all in seconds.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 40)

            Spacer()

            Text("Built with SwiftUI for macOS 14+")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func selectSaveDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder to save screenshots"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        customSavePath = url.path
        captureManager.saveDirectory = url
    }
}

struct ShortcutField: View {
    let label: String
    @Binding var shortcut: String

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 140, alignment: .leading)

            TextField("Shortcut", text: $shortcut)
                .textFieldStyle(.roundedBorder)
                .font(.monospaced(.caption)())

            Spacer()
        }
    }
}
