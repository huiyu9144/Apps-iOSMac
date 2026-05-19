import AppKit
import SwiftUI

class HistoryPanelController: NSObject {
    private var panel: NSPanel?
    private var clipboardMonitor: ClipboardMonitor
    private var isVisible = false

    init(clipboardMonitor: ClipboardMonitor) {
        self.clipboardMonitor = clipboardMonitor
    }

    func togglePanel() {
        if isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    func showPanel() {
        if panel == nil {
            createPanel()
        }
        panel?.orderFront(nil)
        panel?.makeKey()
        isVisible = true
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func hidePanel() {
        panel?.orderOut(nil)
        isVisible = false
    }

    private func createPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 480),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.title = ""
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.hasShadow = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.delegate = self
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let historyView = HistoryPanelView(
            clipboardMonitor: clipboardMonitor
        )

        let hostingController = NSHostingController(rootView: historyView)

        let containerView = NSView()
        let visualEffect = NSVisualEffectView()
        visualEffect.state = .active
        visualEffect.material = .popover
        visualEffect.blendingMode = .behindWindow
        visualEffect.isEmphasized = true

        containerView.addSubview(visualEffect)
        containerView.addSubview(hostingController.view)

        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            visualEffect.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            visualEffect.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            visualEffect.topAnchor.constraint(equalTo: containerView.topAnchor),
            visualEffect.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            hostingController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        panel.contentView = containerView
        panel.setContentSize(NSSize(width: 380, height: 480))

        centerPanel(panel)

        self.panel = panel
    }

    private func centerPanel(_ panel: NSPanel) {
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let panelSize = panel.frame.size
            let x = screenRect.midX - panelSize.width / 2
            let y = screenRect.midY - panelSize.height / 2 + 40
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
}

extension HistoryPanelController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        isVisible = false
    }
}