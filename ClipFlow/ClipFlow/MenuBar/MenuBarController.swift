import AppKit
import SwiftUI
import Combine

class MenuBarController {
    private var statusItem: NSStatusItem?
    private var clipboardMonitor: ClipboardMonitor
    private var panelController: HistoryPanelController
    private var cancellables = Set<AnyCancellable>()

    init(clipboardMonitor: ClipboardMonitor, panelController: HistoryPanelController) {
        self.clipboardMonitor = clipboardMonitor
        self.panelController = panelController
        setupMenuBar()
        observeChanges()
    }

    private func observeChanges() {
        clipboardMonitor.$history
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.buildMenu()
            }
            .store(in: &cancellables)
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            let image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "PasteLite")
            image?.isTemplate = true
            button.image = image
        }

        buildMenu()
    }

    private func buildMenu() {
        let menu = NSMenu()

        if let firstItem = clipboardMonitor.history.first {
            let countItem = NSMenuItem(title: "\(clipboardMonitor.history.count) items in clipboard", action: nil, keyEquivalent: "")
            countItem.isEnabled = false
            menu.addItem(countItem)

            let preview = firstItem.textPreview
            let previewItem = NSMenuItem(title: "Latest: \(preview.prefix(60))", action: nil, keyEquivalent: "")
            previewItem.isEnabled = false
            menu.addItem(previewItem)
        } else {
            let emptyItem = NSMenuItem(title: "No recent copies", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        }

        menu.addItem(NSMenuItem.separator())

        let openPanelItem = NSMenuItem(title: "Show History", action: #selector(openHistoryPanel), keyEquivalent: "v")
        openPanelItem.keyEquivalentModifierMask = [.command, .shift]
        openPanelItem.target = self
        menu.addItem(openPanelItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let clearItem = NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit PasteLite", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc func openHistoryPanel() {
        panelController.togglePanel()
    }

    @objc func openSettings() {
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.setContentSize(NSSize(width: 420, height: 400))
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    @objc func clearHistory() {
        clipboardMonitor.clearAll()
    }
}
