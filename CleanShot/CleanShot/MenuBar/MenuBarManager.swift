import AppKit
import SwiftUI

final class MenuBarManager: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    private var captureManager: CaptureManager?
    private var historyManager: HistoryManager?

    func configure(captureManager: CaptureManager, historyManager: HistoryManager) {
        self.captureManager = captureManager
        self.historyManager = historyManager
        setupMenuBar()
    }

    private func setupMenuBar() {
        guard let captureManager, let historyManager else { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "CleanShot")
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 280, height: 360)
        popover?.behavior = .applicationDefined

        let contentView = MenuBarPopoverView(captureManager: captureManager, historyManager: historyManager)
        popover?.contentViewController = NSHostingController(rootView: contentView)
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                if let window = popover.contentViewController?.view.window {
                    window.makeKey()
                }
            }
        }
    }

    func showPopover() {
        guard let button = statusItem?.button else { return }
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func hidePopover() {
        popover?.performClose(nil)
    }
}

struct MenuBarPopoverView: View {
    @ObservedObject var captureManager: CaptureManager
    @ObservedObject var historyManager: HistoryManager

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            modeList
            Divider()
            bottomActions
        }
        .frame(width: 280)
        .padding()
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "camera.viewfinder")
                .font(.title3)
                .foregroundStyle(.tint)
            Text("CleanShot")
                .font(.headline)
            Spacer()
        }
        .padding(.bottom, 12)
    }

    private var modeList: some View {
        VStack(spacing: 4) {
            MenuBarButton(icon: "rectangle.dashed", title: "Capture Region", shortcut: "⌘⇧4") {
                captureManager.captureRegion()
            }
            MenuBarButton(icon: "macwindow", title: "Capture Window", shortcut: "⌘⇧5") {
                captureManager.captureWindow()
            }
            MenuBarButton(icon: "rectangle.fill.on.rectangle.fill", title: "Capture Fullscreen", shortcut: "⌘⇧6") {
                captureManager.captureFullScreen()
            }
            MenuBarButton(icon: "arrow.down.doc.fill", title: "Scrolling Capture", shortcut: "⌘⇧7") {
                captureManager.captureScrolling()
            }
        }
    }

    private var bottomActions: some View {
        HStack {
            Button("History") {
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.plain)
            .font(.caption)

            Spacer()

            SettingsLink {
                Text("Settings...")
                    .font(.caption)
            }
            .buttonStyle(.plain)

            Spacer()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
    }
}

struct MenuBarButton: View {
    let icon: String
    let title: String
    let shortcut: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .frame(width: 18)
                    .foregroundStyle(.tint)
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Text(shortcut)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospaced()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
