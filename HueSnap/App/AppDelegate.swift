import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var statusItemMenu: NSMenu!
    private var popover: NSPopover!
    var viewModel: HueSnapViewModel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        viewModel = HueSnapViewModel()
        viewModel.onContentChanged = { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                guard let self = self else { return }
                guard let view = self.popover.contentViewController?.view else { return }
                view.invalidateIntrinsicContentSize()
                view.layoutSubtreeIfNeeded()
                let fittingSize = view.fittingSize
                let clampedHeight = min(max(fittingSize.height, 300), 520)
                if abs(self.popover.contentSize.height - clampedHeight) > 1 {
                    self.popover.contentSize = NSSize(width: 340, height: clampedHeight)
                }
            }
        }

        setupStatusItem()
        setupPopover()
        NSApp.appearance = nil
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "eyedropper", accessibilityDescription: "HueCatch")
        statusItem.button?.action = #selector(handleStatusItemClick)
        statusItem.button?.target = self
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        statusItemMenu = NSMenu()
        let pickItem = NSMenuItem(title: locStr("吸取颜色"), action: #selector(startPickerFromMenu), keyEquivalent: "")
        pickItem.image = NSImage(systemSymbolName: "eyedropper.halffull", accessibilityDescription: nil)
        pickItem.target = self
        statusItemMenu.addItem(pickItem)
        statusItemMenu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: locStr("退出"), action: #selector(terminateApp), keyEquivalent: "q")
        quitItem.target = self
        statusItemMenu.addItem(quitItem)
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 520)
        popover.behavior = .transient
        rebuildPopoverContent()
    }

    func rebuildPopoverContent() {
        let hostingController = NSHostingController(rootView: MenuBarPopoverView(viewModel: viewModel))
        popover.contentViewController = hostingController
    }

    @objc private func handleStatusItemClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            statusItemMenu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
        } else {
            togglePopover()
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            rebuildPopoverContent()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            scheduleResize()
        }
    }

    private func scheduleResize() {
        DispatchQueue.main.async {
            self.resizePopoverToFit()
        }
    }

    private func resizePopoverToFit() {
        guard let view = popover.contentViewController?.view else { return }
        view.invalidateIntrinsicContentSize()
        view.layoutSubtreeIfNeeded()
        let fittingSize = view.fittingSize
        let clampedHeight = min(max(fittingSize.height, 300), 520)
        if abs(popover.contentSize.height - clampedHeight) > 1 {
            popover.contentSize = NSSize(width: 340, height: clampedHeight)
        }
    }

    @objc private func startPickerFromMenu() {
        viewModel.startPicking()
    }

    @objc func terminateApp() {
        NSApplication.shared.terminate(nil)
    }
}
