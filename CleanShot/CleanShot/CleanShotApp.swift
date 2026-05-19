import SwiftUI
import AppKit

@main
struct CleanShotApp: App {
    @StateObject private var captureManager = CaptureManager()
    @StateObject private var menuBarManager = MenuBarManager()
    @StateObject private var historyManager = HistoryManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(captureManager)
                .environmentObject(historyManager)
                .frame(width: 400, height: 500)
                .onAppear {
                    menuBarManager.configure(
                        captureManager: captureManager,
                        historyManager: historyManager
                    )
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environmentObject(captureManager)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var captureManager: CaptureManager
    @EnvironmentObject private var historyManager: HistoryManager
    @State private var showHistory = false

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            captureModesView
            Divider()
            quickActionsView
            if showHistory {
                Divider()
                historyView
            }
            Spacer()
            footerView
        }
        .frame(width: 320)
        .padding()
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "camera.viewfinder")
                .font(.title2)
                .foregroundStyle(.tint)
            Text("CleanShot")
                .font(.headline)
            Spacer()
            Button {
                showHistory.toggle()
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Capture History")
        }
        .padding(.bottom, 12)
    }

    private var captureModesView: some View {
        VStack(spacing: 8) {
            CaptureModeButton(
                icon: "rectangle.dashed",
                title: "Capture Region",
                shortcut: "⌘⇧4",
                color: .blue
            ) {
                captureManager.captureRegion()
            }

            CaptureModeButton(
                icon: "macwindow",
                title: "Capture Window",
                shortcut: "⌘⇧5",
                color: .purple
            ) {
                captureManager.captureWindow()
            }

            CaptureModeButton(
                icon: "rectangle.fill.on.rectangle.fill",
                title: "Capture Fullscreen",
                shortcut: "⌘⇧6",
                color: .green
            ) {
                captureManager.captureFullScreen()
            }

            CaptureModeButton(
                icon: "arrow.down.doc.fill",
                title: "Scrolling Capture",
                shortcut: "⌘⇧7",
                color: .orange
            ) {
                captureManager.captureScrolling()
            }
        }
    }

    private var quickActionsView: some View {
        HStack(spacing: 12) {
            ActionButton(icon: "folder", title: "Open Folder") {
                captureManager.openScreenshotsFolder()
            }
            ActionButton(icon: "clock", title: "History") {
                showHistory.toggle()
            }
            SettingsLink {
                VStack(spacing: 4) {
                    Image(systemName: "gearshape")
                        .font(.title3)
                    Text("Settings")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(nsColor: .windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
    }

    private var historyView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recent Captures")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(historyManager.recentCaptures) { capture in
                        HistoryThumbnail(capture: capture)
                            .onTapGesture {
                                captureManager.openCapture(capture)
                            }
                    }
                }
            }
            .frame(height: 60)
        }
        .padding(.vertical, 4)
    }

    private var footerView: some View {
        HStack {
            Text("v1.0.0")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Spacer()
            Text("CleanShot")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 8)
    }
}

struct CaptureModeButton: View {
    let icon: String
    let title: String
    let shortcut: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 24)

                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                Text(shortcut)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .monospaced()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct HistoryThumbnail: View {
    let capture: CaptureItem

    var body: some View {
        if let image = capture.thumbnail {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                )
        }
    }
}
