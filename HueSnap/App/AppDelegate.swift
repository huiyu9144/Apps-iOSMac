import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var settingsWindow: NSWindow!
    var viewModel: HueSnapViewModel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        viewModel = HueSnapViewModel()

        setupStatusItem()
        setupPopover()
        NSApp.appearance = nil
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "eyedropper", accessibilityDescription: "HueSnap")
        statusItem.button?.action = #selector(handleStatusItemClick)
        statusItem.button?.target = self
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        let menu = NSMenu()
        let pickItem = NSMenuItem(title: locStr("吸取颜色"), action: #selector(startPickerFromMenu), keyEquivalent: "")
        pickItem.image = NSImage(systemSymbolName: "eyedropper.halffull", accessibilityDescription: nil)
        menu.addItem(pickItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: locStr("设置…"), action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: locStr("退出"), action: #selector(terminateApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 520)
        popover.behavior = .transient
        popover.contentViewController = NSViewController()
        rebuildPopoverContent()
    }

    func rebuildPopoverContent() {
        let hostingView = NSHostingView(rootView: AnyView(MenuBarPopoverView(viewModel: viewModel)))
        popover.contentViewController?.view = hostingView
    }

    @objc private func handleStatusItemClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            statusItem.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
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
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    @objc private func startPickerFromMenu() {
        viewModel.startPicking()
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView(viewModel: viewModel)
            let hostingView = NSHostingView(rootView: settingsView)
            hostingView.frame.size = NSSize(width: 400, height: 220)

            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 220),
                                  styleMask: [.titled, .closable, .miniaturizable],
                                  backing: .buffered, defer: false)
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
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        settingsWindow = nil
    }
}
