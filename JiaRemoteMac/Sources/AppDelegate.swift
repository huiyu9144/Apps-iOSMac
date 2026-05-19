import Cocoa
import SwiftUI
import Combine
import Network

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var hostingController: NSHostingController<SettingsView>?

    let captureEngine = CaptureEngine()
    let inputController = InputController()
    let tcpServer = TCPServer()
    let bonjourService = BonjourService()
    let udpScanner = UDPScanner()
    lazy var debugLogController = DebugLogWindowController()
    let config = ConfigManager.shared

    private var cancellables = Set<AnyCancellable>()

    var isServiceRunning: Bool { tcpServer.isRunning }
    var isClientConnected: Bool { tcpServer.connectedClientHost != nil }
    var clientHost: String? { tcpServer.connectedClientHost }

    func applicationDidFinishLaunching(_ notification: Notification) {
        config.load()

        setupStatusBar()
        setupCaptureDelegate()
        setupServerDelegate()
        setupInputHandler()
        setupBonjourDelegate()

        NSApp.setActivationPolicy(.accessory)

        if config.autoStartService {
            startAllServices()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopAllServices()
        config.save()
    }

    // MARK: - Status Bar
    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusBarItem?.button else { return }

        button.title = "🖥"
        button.toolTip = "JiaRemote 被控端"
        button.action = #selector(statusBarClicked)
        button.target = self
    }

    @objc private func statusBarClicked() {
        guard let button = statusBarItem?.button else { return }
        let menu = NSMenu()

        if isServiceRunning {
            menu.addItem(NSMenuItem(title: "服务运行中 \(clientHost.map { "· 已连接 \($0)" } ?? "· 等待连接")", action: nil, keyEquivalent: ""))
        } else {
            menu.addItem(NSMenuItem(title: "服务未启动", action: nil, keyEquivalent: ""))
        }
        menu.addItem(.separator())

        let toggleItem = NSMenuItem(
            title: isServiceRunning ? "⏹ 停止服务" : "▶ 启动服务",
            action: #selector(toggleServiceFromMenu),
            keyEquivalent: ""
        )
        menu.addItem(toggleItem)

        let settingsItem = NSMenuItem(
            title: "⚙ 设置...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        menu.addItem(settingsItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "关于 JiaRemote", action: #selector(showAbout), keyEquivalent: ""))

        menu.addItem(NSMenuItem(title: "🧪 调试日志", action: #selector(showDebugLog), keyEquivalent: ""))

        let quitItem = NSMenuItem(
            title: "退出 JiaRemote",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusBarItem?.menu = menu
        button.performClick(nil)
    }

    @objc private func toggleServiceFromMenu() {
        if isServiceRunning {
            stopAllServices()
        } else {
            checkPermissionsAndStart()
        }
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView(appDelegate: self)
            hostingController = NSHostingController(rootView: settingsView)

            settingsWindow = NSWindow(contentViewController: hostingController!)
            settingsWindow?.title = "JiaRemote 设置"
            settingsWindow?.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            settingsWindow?.setContentSize(NSSize(width: 480, height: 620))
            settingsWindow?.center()
            settingsWindow?.isReleasedWhenClosed = false
            settingsWindow?.titlebarAppearsTransparent = true
            settingsWindow?.backgroundColor = NSColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "JiaRemote"
        alert.informativeText = """
        局域网无损原生远程控制系统
        Mac 被控端 v1.0

        ScreenCaptureKit 原生捕获
        IOSurface 零拷贝传输
        CGEvent + AX API 原生操控
        仅内网运行 · 无数据上传
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }

    @objc private func showDebugLog() {
        debugLogController.showWindow(nil)
        debugLogController.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        stopAllServices()
        config.save()
        NSApp.terminate(nil)
    }

    // MARK: - Service Lifecycle
    func checkPermissionsAndStart() {
        if !config.checkScreenRecordingPermission() {
            Task {
                let granted = await config.requestScreenRecordingPermission()
                if granted {
                    await MainActor.run { self.startAllServices() }
                } else {
                    await MainActor.run {
                        let alert = NSAlert()
                        alert.messageText = "需要屏幕录制权限"
                        alert.informativeText = "请在系统设置 → 隐私与安全性 → 屏幕录制中允许 JiaRemote"
                        alert.addButton(withTitle: "打开系统设置")
                        alert.addButton(withTitle: "取消")
                        if alert.runModal() == .alertFirstButtonReturn {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
                        }
                    }
                }
            }
            return
        }
        if !config.checkAccessibilityPermission() {
            let granted = config.requestAccessibilityPermission()
            if !granted {
                let alert = NSAlert()
                alert.messageText = "需要辅助功能权限"
                alert.informativeText = "请在系统设置 → 隐私与安全性 → 辅助功能中允许 JiaRemote"
                alert.addButton(withTitle: "打开系统设置")
                alert.addButton(withTitle: "取消")
                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
                return
            }
        }
        startAllServices()
    }

    func startAllServices() {
        do {
            try tcpServer.start(port: UInt16(config.listenPort))
        } catch {
            print("[JiaRemote] TCP server failed to start: \(error)")
            return
        }

        if config.bonjourEnabled {
            bonjourService.startPublish(port: Int32(tcpServer.listeningPort ?? UInt16(config.listenPort)))
        }

        udpScanner.start(port: UInt16(config.listenPort))

        updateStatusBar()
        startCaptureWithRetry()
    }

    private func startCaptureWithRetry() {
        Task {
            for attempt in 1...5 {
                do {
                    if config.captureMode == "window", config.selectedWindowID != 0 {
                        try captureEngine.start(target: .window(windowID: config.selectedWindowID))
                    } else {
                        let displays = try await CaptureEngine.fetchDisplays()
                        let targetID = config.selectedDisplayID != 0 ? config.selectedDisplayID : displays.first?.displayID ?? 0
                        try captureEngine.start(target: .display(displayID: targetID))
                    }
                    print("[JiaRemote] Capture started successfully")
                    return
                } catch {
                    print("[JiaRemote] Capture attempt \(attempt)/5 failed: \(error)")
                    if attempt == 3 {
                        print("[JiaRemote] Re-requesting screen recording permission...")
                        _ = await config.requestScreenRecordingPermission()
                    }
                    if attempt < 5 {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                    }
                }
            }
            print("[JiaRemote] All capture attempts failed. Please restart the app after confirming Screen Recording permission in System Settings.")
        }
    }

    func stopAllServices() {
        captureEngine.stop()
        tcpServer.stop()
        bonjourService.stopPublish()
        udpScanner.stop()
        updateStatusBar()
    }

    private func updateStatusBar() {
        guard let button = statusBarItem?.button else { return }
        if isServiceRunning {
            button.title = isClientConnected ? "🖥" : "🖥"
            button.toolTip = isClientConnected
                ? "JiaRemote · 已连接 \(clientHost ?? "")"
                : "JiaRemote · 等待连接"
        } else {
            button.title = "💤"
            button.toolTip = "JiaRemote · 未启动"
        }
    }

    // MARK: - Capture → Server Bridge
    private func setupCaptureDelegate() {
        tcpServer.captureEngine = captureEngine
    }

    // MARK: - Server → Input Bridge
    private func setupServerDelegate() {
        tcpServer.delegate = self
    }

    private func setupInputHandler() {
    }

    private func setupBonjourDelegate() {
        bonjourService.delegate = self
    }
}

// MARK: - TCPServerDelegate
extension AppDelegate: TCPServerDelegate {
    func tcpServerDidAcceptClient(_ server: TCPServer, host: String) {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusBar()
        }
    }

    func tcpServerDidDisconnectClient(_ server: TCPServer) {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusBar()
        }
    }

    func tcpServer(_ server: TCPServer, didReceiveCommand type: JiaProtocol.CommandType, payload: Data) {
        handleCommand(type: type, payload: payload)
    }
}

// MARK: - BonjourServiceDelegate
extension AppDelegate: BonjourServiceDelegate {
    func bonjourServiceDidPublish(_ service: BonjourService) {
        print("[JiaRemote] Bonjour published as: \(service.currentServiceName)")
    }

    func bonjourService(_ service: BonjourService, didFailToPublish error: Error) {
        print("[JiaRemote] Bonjour publish failed: \(error)")
    }

    func bonjourService(_ service: BonjourService, didDiscoverService name: String, host: String, port: Int) {
        print("[JiaRemote] Discovered: \(name) @ \(host):\(port)")
    }
}

// MARK: - Command Handler
extension AppDelegate {
    private func handleCommand(type: JiaProtocol.CommandType, payload: Data) {
        switch type {
        case .mouseMove:
            if let pt = try? JSONDecoder().decode(JiaProtocol.MousePoint.self, from: payload) {
                inputController.injectMouseMove(x: pt.x, y: pt.y)
            }

        case .mouseDown:
            if let evt = try? JSONDecoder().decode(JiaProtocol.MouseButtonEvent.self, from: payload) {
                let button: CGMouseButton = evt.button == 1 ? .right : evt.button == 2 ? .center : .left
                inputController.injectMouseMove(x: evt.point.x, y: evt.point.y)
                inputController.injectMouseDown(button: button)
            }

        case .mouseUp:
            if let evt = try? JSONDecoder().decode(JiaProtocol.MouseButtonEvent.self, from: payload) {
                let button: CGMouseButton = evt.button == 1 ? .right : evt.button == 2 ? .center : .left
                inputController.injectMouseUp(button: button)
            }

        case .mouseScroll:
            if let evt = try? JSONDecoder().decode(JiaProtocol.MouseScrollEvent.self, from: payload) {
                inputController.injectScroll(deltaY: evt.deltaY, deltaX: evt.deltaX)
            }

        case .mouseDblClick:
            if let evt = try? JSONDecoder().decode(JiaProtocol.MouseButtonEvent.self, from: payload) {
                let button: CGMouseButton = evt.button == 1 ? .right : evt.button == 2 ? .center : .left
                inputController.injectMouseDblClick(at: CGPoint(x: CGFloat(evt.point.x), y: CGFloat(evt.point.y)), button: button)
            }

        case .keyDown:
            if let evt = try? JSONDecoder().decode(JiaProtocol.KeyEvent.self, from: payload) {
                inputController.injectKeyDown(keyCode: CGKeyCode(evt.keyCode), flags: CGEventFlags(rawValue: evt.flags))
            }

        case .keyUp:
            if let evt = try? JSONDecoder().decode(JiaProtocol.KeyEvent.self, from: payload) {
                inputController.injectKeyUp(keyCode: CGKeyCode(evt.keyCode), flags: CGEventFlags(rawValue: evt.flags))
            }

        case .keyCombo:
            if let evt = try? JSONDecoder().decode(JiaProtocol.KeyComboEvent.self, from: payload) {
                let codes = evt.keyCodes.map { CGKeyCode($0) }
                inputController.injectKeyCombo(keyCodes: codes, flags: CGEventFlags(rawValue: evt.flags))
            }

        case .systemCommand:
            if let evt = try? JSONDecoder().decode(JiaProtocol.SystemCommandEvent.self, from: payload) {
                handleSystemCommand(evt)
            }

        case .clipboardPush:
            if let data = try? JSONDecoder().decode(JiaProtocol.ClipboardData.self, from: payload) {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(data.text, forType: .string)
            }

        case .clipboardPull:
            let text = NSPasteboard.general.string(forType: .string) ?? ""
            let data = JiaProtocol.ClipboardData(text: text)
            if let jsonData = try? JSONEncoder().encode(data) {
                tcpServer.sendCommandResponse(type: .clipboardPull, payload: jsonData)
            }

        case .windowListRequest:
            let windows = inputController.fetchWindowList()
            let winInfoList = windows.map { JiaProtocol.RemoteWindowInfo(id: UInt32($0.windowID), title: $0.title, appName: $0.ownerName, isOnScreen: true) }
            if let jsonData = try? JSONEncoder().encode(winInfoList) {
                tcpServer.sendCommandResponse(type: .windowListResponse, payload: jsonData)
            }

        case .windowFocus:
            if let winInfo = try? JSONDecoder().decode(JiaProtocol.RemoteWindowInfo.self, from: payload) {
                _ = inputController.focusWindowAX(windowID: winInfo.id)
            }

        case .windowClose:
            if let winInfo = try? JSONDecoder().decode(JiaProtocol.RemoteWindowInfo.self, from: payload) {
                _ = inputController.closeWindowAX(windowID: winInfo.id)
            }

        case .displayInfoRequest:
            Task {
                if let displays = try? await CaptureEngine.fetchDisplays() {
                    let infoList = displays.map { JiaProtocol.RemoteDisplayInfo(id: $0.displayID, width: UInt16($0.width), height: UInt16($0.height), refreshRate: 0) }
                    if let jsonData = try? JSONEncoder().encode(infoList) {
                        await MainActor.run { tcpServer.sendCommandResponse(type: .displayInfoResponse, payload: jsonData) }
                    }
                }
            }

        case .ping:
            tcpServer.sendCommandResponse(type: .pong, payload: Data())

        default:
            break
        }
    }

    private func handleSystemCommand(_ evt: JiaProtocol.SystemCommandEvent) {
        switch evt.commandType {
        case "sleep":
            inputController.sleepSystem()
        case "restart":
            inputController.restartSystem()
        case "shutdown":
            inputController.shutdownSystem()
        case "lockScreen":
            inputController.lockScreen()
        case "volumeUp":
            inputController.setVolume(min(1.0, 0.75))
        case "volumeDown":
            inputController.setVolume(max(0.0, 0.25))
        case "mute":
            inputController.setVolume(0)
        case "brightnessUp":
            inputController.setBrightness(min(1.0, 0.8))
        case "brightnessDown":
            inputController.setBrightness(max(0.0, 0.2))
        case "launchpad":
            inputController.openLaunchpad()
        case "missionControl":
            inputController.openMissionControl()
        case "wake":
            inputController.wakeDisplay()
        default:
            if let bundleID = evt.value.flatMap({ String(describing: $0) }), !bundleID.isEmpty {
                inputController.launchApplication(bundleID: bundleID)
            }
        }
    }
}

// MARK: - SwiftUI Settings View
struct SettingsView: View {
    @ObservedObject var config = ConfigManager.shared
    weak var appDelegate: AppDelegate?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader("📺 画面捕获")
                captureModeRow
                displayOrWindowRow
                colorSpaceRow

                Divider().background(Color.white.opacity(0.1))

                sectionHeader("🔐 权限状态")
                permissionRow("屏幕录制", granted: config.screenRecordingGranted)
                permissionRow("辅助功能", granted: config.accessibilityGranted)

                Divider().background(Color.white.opacity(0.1))

                sectionHeader("🌐 网络")
                portRow
                bonjourRow
                ipInfoRow

                Divider().background(Color.white.opacity(0.1))

                sectionHeader("👁 显示")
                overlayRow
                autoStartRow

                Divider().background(Color.white.opacity(0.1))

                sectionHeader("⚡ 快捷控制")
                quickActionsGrid

                Spacer().frame(height: 20)
            }
            .padding(20)
        }
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .onAppear { config.refreshPermissions() }
        .onReceive(Timer.publish(every: 3, on: .main, in: .common).autoconnect()) { _ in
            config.refreshPermissions()
        }
    }

    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Color.white.opacity(0.36))
            .textCase(.uppercase)
    }

    var captureModeRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("捕获模式").font(.system(size: 14)).foregroundColor(.white)
                Text("ScreenCaptureKit 原生捕获").font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            Picker("", selection: $config.captureMode) {
                Text("全屏捕获").tag("fullscreen")
                Text("单窗口捕获").tag("window")
            }
            .pickerStyle(.menu)
            .frame(width: 130)
            .onChange(of: config.captureMode) { _ in config.save() }
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
    }

    @ViewBuilder
    var displayOrWindowRow: some View {
        if config.captureMode == "fullscreen" {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("目标显示器").font(.system(size: 14)).foregroundColor(.white)
                }
                Spacer()
                Text("主显示器").font(.system(size: 13)).foregroundColor(.white.opacity(0.5))
            }
            .padding(12)
            .background(Color.white.opacity(0.06))
            .cornerRadius(10)
        } else {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("选择窗口").font(.system(size: 14)).foregroundColor(.white)
                }
                Spacer()
                Text("点击选择...").font(.system(size: 13)).foregroundColor(.blue)
            }
            .padding(12)
            .background(Color.white.opacity(0.06))
            .cornerRadius(10)
        }
    }

    var colorSpaceRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("色彩空间").font(.system(size: 14)).foregroundColor(.white)
            }
            Spacer()
            Picker("", selection: $config.colorSpace) {
                Text("Display P3").tag("Display P3")
                Text("sRGB").tag("sRGB")
            }
            .pickerStyle(.menu)
            .frame(width: 130)
            .onChange(of: config.colorSpace) { _ in config.save() }
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
    }

    func permissionRow(_ name: String, granted: Bool) -> some View {
        HStack {
            Text(name).font(.system(size: 14)).foregroundColor(.white)
            Spacer()
            Circle()
                .fill(granted ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(granted ? "已授权" : "未授权")
                .font(.system(size: 12))
                .foregroundColor(granted ? .green : .red)
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
    }

    var portRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("监听端口").font(.system(size: 14)).foregroundColor(.white)
            }
            Spacer()
            TextField("9527", value: $config.listenPort, format: .number)
                .textFieldStyle(.plain)
                .frame(width: 70)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .onChange(of: config.listenPort) { _ in config.save() }
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
    }

    var bonjourRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Bonjour 发现").font(.system(size: 14)).foregroundColor(.white)
                Text("局域网自动发现").font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            Toggle("", isOn: $config.bonjourEnabled)
                .toggleStyle(.switch)
                .onChange(of: config.bonjourEnabled) { _ in config.save() }
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
    }

    var ipInfoRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("本机 IP").font(.system(size: 14)).foregroundColor(.white)
            }
            Spacer()
            Text(config.getLocalIPAddress() ?? "未知")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(Color(red: 0.04, green: 0.52, blue: 1.0))
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
    }

    var overlayRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("画面上显示参数").font(.system(size: 14)).foregroundColor(.white)
                Text("FPS / 延迟 / 画质覆盖层").font(.system(size: 11)).foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            Toggle("", isOn: $config.showOverlay)
                .toggleStyle(.switch)
                .onChange(of: config.showOverlay) { _ in config.save() }
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
    }

    var autoStartRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("启动时自动运行服务").font(.system(size: 14)).foregroundColor(.white)
            }
            Spacer()
            Toggle("", isOn: $config.autoStartService)
                .toggleStyle(.switch)
                .onChange(of: config.autoStartService) { _ in config.save() }
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
    }

    var quickActionsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
            quickButton("😴", "休眠") { appDelegate?.inputController.sleepSystem() }
            quickButton("🔄", "重启") { appDelegate?.inputController.restartSystem() }
            quickButton("⏻", "关机") { appDelegate?.inputController.shutdownSystem() }
            quickButton("🔒", "锁屏") { appDelegate?.inputController.lockScreen() }
            quickButton("🔊", "音量") { appDelegate?.inputController.setVolume(0.5) }
            quickButton("☀️", "亮度") { appDelegate?.inputController.setBrightness(0.5) }
            quickButton("🚀", "Launchpad") { appDelegate?.inputController.openLaunchpad() }
            quickButton("⚡", "唤醒") { appDelegate?.inputController.wakeDisplay() }
        }
    }

    func quickButton(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(icon).font(.system(size: 22))
                Text(label).font(.system(size: 10))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
