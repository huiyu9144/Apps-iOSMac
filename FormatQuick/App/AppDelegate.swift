import AppKit
import SwiftUI

extension Notification.Name {
    static let openSettings = Notification.Name("FormatQuickOpenSettings")
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var settingsWindow: NSWindow!
    private var contextMenu: NSMenu!
    var viewModel: FormatQuickViewModel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        viewModel = FormatQuickViewModel()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSettingsFromNotification),
            name: .openSettings,
            object: nil
        )

        setupStatusItem()
        setupPopover()
        setupAppearance()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "arrow.triangle.swap",
            accessibilityDescription: "FormatQuick"
        )
        statusItem.button?.action = #selector(handleStatusItemClick)
        statusItem.button?.target = self
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        contextMenu = NSMenu()
        contextMenu.addItem(NSMenuItem(
            title: locStr("设置…"),
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
        contextMenu.addItem(NSMenuItem.separator())
        contextMenu.addItem(NSMenuItem(
            title: locStr("退出"),
            action: #selector(terminateApp),
            keyEquivalent: "q"
        ))
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSViewController()
        rebuildPopoverContent()
    }

    func rebuildPopoverContent() {
        let hostingView = NSHostingView(
            rootView: AnyView(MenuBarPopoverView(viewModel: viewModel))
        )
        popover.contentViewController?.view = hostingView
    }

    @objc private func handleStatusItemClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            contextMenu.popUp(
                positioning: nil,
                at: NSEvent.mouseLocation,
                in: nil
            )
        } else {
            togglePopover()
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            rebuildPopoverContent()
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    @objc func openSettings() {
        openSettingsWindow()
    }

    @objc private func openSettingsFromNotification() {
        openSettingsWindow()
    }

    private func openSettingsWindow() {
        if settingsWindow == nil {
            let settingsView = SettingsView(viewModel: viewModel)
            let hostingView = NSHostingView(rootView: settingsView)
            hostingView.frame.size = NSSize(width: 400, height: 380)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 380),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = locStr("设置")
            window.center()
            window.contentView = hostingView
            window.isReleasedWhenClosed = false
            window.delegate = self
            settingsWindow = window
        }
        settingsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func terminateApp() {
        NSApplication.shared.terminate(nil)
    }

    private func setupAppearance() {
        let appearanceRaw = UserDefaults.standard.string(forKey: "appearance") ?? "system"
        applyAppearance(appearanceRaw)
    }

    func applyAppearance(_ rawValue: String) {
        switch rawValue {
        case "light":
            NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil
        }
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        settingsWindow = nil
    }
}
