import SwiftUI
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var viewModel: CompressionViewModel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        viewModel = CompressionViewModel()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "photo.badge.arrow.down",
            accessibilityDescription: "PicShrink"
        )
        statusItem.button?.target = self
        statusItem.button?.action = #selector(handleStatusItemClick)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        let hostingView = NSHostingView(rootView: MenuBarPopoverView(viewModel: viewModel))
        popover = NSPopover()
        popover.contentSize = NSSize(width: 390, height: 320)
        popover.behavior = .transient
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = hostingView
    }

    @objc private func handleStatusItemClick() {
        guard let button = statusItem.button else { return }
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu(for: button)
        } else {
            togglePopover(from: button)
        }
    }

    private func showContextMenu(for button: NSStatusBarButton) {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: locStr("设置…"),
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: locStr("退出"),
            action: #selector(terminateApp),
            keyEquivalent: "q"
        ))
        statusItem.menu = menu
        button.performClick(nil)
        statusItem.menu = nil
    }

    private func togglePopover(from button: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            rebuildPopoverContent()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func rebuildPopoverContent() {
        let hostingView = NSHostingView(rootView: MenuBarPopoverView(viewModel: viewModel))
        popover.contentViewController?.view = hostingView
    }

    @objc private func openSettings() {
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = locStr("设置")
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 380, height: 350))
        window.center()
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func terminateApp() {
        NSApplication.shared.terminate(nil)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
