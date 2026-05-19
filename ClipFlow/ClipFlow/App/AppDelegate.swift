import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var clipboardMonitor: ClipboardMonitor?
    private var keyboardShortcutManager: KeyboardShortcutManager?
    private var historyService: HistoryService?
    private var panelController: HistoryPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let historyService = HistoryService()
        self.historyService = historyService

        let clipboardMonitor = ClipboardMonitor(historyService: historyService)
        self.clipboardMonitor = clipboardMonitor
        clipboardMonitor.startMonitoring()

        let limit = UserDefaults.standard.integer(forKey: "historyLimit")
        if limit > 0 {
            clipboardMonitor.setHistoryLimit(limit)
        }

        let panelController = HistoryPanelController(
            clipboardMonitor: clipboardMonitor
        )
        self.panelController = panelController

        let menuBarController = MenuBarController(
            clipboardMonitor: clipboardMonitor,
            panelController: panelController
        )
        self.menuBarController = menuBarController

        let keyboardManager = KeyboardShortcutManager()
        self.keyboardShortcutManager = keyboardManager

        keyboardManager.registerToggleShortcut { [weak panelController] in
            panelController?.togglePanel()
        }

        setupAutoLaunch()
    }

    private func setupAutoLaunch() {
        let launcher = UserDefaults.standard.bool(forKey: "launchAtLogin")
        if launcher {
            LoginItemsService.shared.addLoginItem()
        }
    }
}
