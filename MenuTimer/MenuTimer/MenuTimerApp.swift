import SwiftUI
import AppKit

@main
struct MenuTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var timerManager: TimerManager!
    private var menuUpdateTimer: Timer?
    private var timerIcon: NSImage?

    func applicationDidFinishLaunching(_ notification: Notification) {
        timerManager = TimerManager()
        timerManager.requestNotificationPermission()

        timerIcon = NSImage(
            systemSymbolName: "timer",
            accessibilityDescription: "DashTimer"
        )

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.target = self
        statusItem.button?.image = timerIcon

        let hostingView = NSHostingView(rootView: AnyView(buildPopoverView()))

        popover = NSPopover()
        popover.contentSize = NSSize(width: 236, height: 340)
        popover.behavior = .transient
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = hostingView

        menuUpdateTimer = Timer.scheduledTimer(
            timeInterval: 0.5,
            target: self,
            selector: #selector(updateMenuBar),
            userInfo: nil,
            repeats: true
        )
    }

    private func buildPopoverView() -> MenuBarPopoverView {
        MenuBarPopoverView(timerManager: timerManager)
    }

    @objc private func updateMenuBar() {
        if popover.isShown { return }
        let title = timerManager.menuBarTitle
        if title.isEmpty {
            statusItem.button?.title = ""
            if timerManager.state == .idle {
                statusItem.button?.image = timerIcon
            }
        } else {
            statusItem.button?.image = nil
            statusItem.button?.title = title
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

    private func rebuildPopoverContent() {
        let hostingView = NSHostingView(rootView: AnyView(buildPopoverView()))
        popover.contentViewController?.view = hostingView
    }
}
