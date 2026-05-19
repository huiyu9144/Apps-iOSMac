import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var viewModel: NetMeterViewModel!
    private var eventMonitor: Any?
    private let iconImage: NSImage = {
        NSImage(systemSymbolName: "antenna.radiowaves.left.and.right", accessibilityDescription: "NetMeter")!
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        viewModel = NetMeterViewModel()
        viewModel.applyAppearance()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = iconImage
            button.action = #selector(handleStatusBarClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 520)
        popover.behavior = .transient
        popover.contentViewController = NSViewController()

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            Task { @MainActor in
                guard let self = self, self.popover.isShown else { return }
                if let window = self.popover.contentViewController?.view.window, !window.isKeyWindow {
                    self.closePopover()
                }
            }
        }

        startMenuBarTimer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        viewModel?.stopMonitoring()
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    @objc private func handleStatusBarClick() {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
            return
        }

        togglePopover()
    }

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            openPopover()
        }
    }

    private func openPopover() {
        rebuildPopoverContent()
        viewModel.startMonitoring()
        viewModel.refreshProcesses()
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func closePopover() {
        popover.performClose(nil)
        viewModel.stopMonitoring()
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: locStr("设置…"), action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: locStr("退出"), action: #selector(terminateApp), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        if let button = statusItem.button {
            menu.popUp(positioning: nil, at: CGPoint(x: 0, y: button.bounds.height), in: button)
        }
    }

    @objc private func openSettings() {
        if !popover.isShown {
            openPopover()
        }
        viewModel.showSettings = true
    }

    @objc private func terminateApp() {
        NSApplication.shared.terminate(nil)
    }

    private func rebuildPopoverContent() {
        let hostingView = NSHostingView(rootView: AnyView(MenuBarPopoverView(viewModel: viewModel)))
        popover.contentViewController?.view = hostingView
    }

    private func startMenuBarTimer() {
        statusItem.button?.title = ""
        statusItem.button?.image = iconImage
    }
}
