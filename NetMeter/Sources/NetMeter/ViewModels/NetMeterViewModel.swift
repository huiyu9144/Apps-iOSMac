import SwiftUI
import Combine
import ServiceManagement

enum MenuBarDisplayMode: String, CaseIterable {
    case speed = "speed"
    case totalTraffic = "total"

    var displayName: String {
        switch self {
        case .speed: return locStr("显示速度")
        case .totalTraffic: return locStr("显示总流量")
        }
    }
}

enum AppearanceMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .system: return locStr("跟随系统")
        case .light: return locStr("浅色")
        case .dark: return locStr("深色")
        }
    }
}

enum ProcessSortMode: String, CaseIterable {
    case totalSpeed = "total"
    case uploadSpeed = "upload"
    case downloadSpeed = "download"
    case name = "name"

    var displayName: String {
        switch self {
        case .totalSpeed: return locStr("总速度")
        case .uploadSpeed: return locStr("上传速度")
        case .downloadSpeed: return locStr("下载速度")
        case .name: return locStr("名称")
        }
    }
}

@MainActor
class NetMeterViewModel: ObservableObject {
    private let networkMonitor = NetworkMonitorService()
    private let trafficService = TrafficService()
    private let processTrafficService = ProcessTrafficService()

    @Published var isConnected = true
    @Published var interfaceType = "Wi-Fi"
    @Published var ipAddress = ""
    @Published var uploadSpeed: Double = 0
    @Published var downloadSpeed: Double = 0
    @Published var sessionUpload: UInt64 = 0
    @Published var sessionDownload: UInt64 = 0
    @Published var speedHistory: [TrafficSnapshot] = []
    @Published var processes: [ProcessTrafficInfo] = []
    @Published var processIsRefreshing = false
    @Published var dailyTotals: [(date: Date, upload: UInt64, download: UInt64)] = []

    @Published var showLiveChart = false
    @Published var showSettings = false
    @Published var isMonitoring = false

    @Published var displayMode: MenuBarDisplayMode = .speed
    @Published var refreshInterval: Double = 1.0
    @Published var appearance: AppearanceMode = .system
    @Published var launchAtLogin = false
    @Published var monthlyLimitEnabled = false
    @Published var monthlyLimitGB: Double = 100
    @Published var notifyAt80 = true
    @Published var appLanguage: Language = .system
    @Published var processSortMode: ProcessSortMode = .totalSpeed

    private var cancellables = Set<AnyCancellable>()

    var menuBarTitle: String {
        if !isConnected {
            return ""
        }
        switch displayMode {
        case .speed:
            if uploadSpeed < 1 && downloadSpeed < 1 { return "" }
            return "↑\(formatSpeed(uploadSpeed)) ↓\(formatSpeed(downloadSpeed))"
        case .totalTraffic:
            return "↑\(formatBytes(sessionUpload)) ↓\(formatBytes(sessionDownload))"
        }
    }

    var networkInfoText: String {
        if isConnected {
            return "\(interfaceType) (\(ipAddress))"
        }
        return locStr("未连接")
    }

    var sortedProcesses: [ProcessTrafficInfo] {
        switch processSortMode {
        case .totalSpeed:
            return processes.sorted { $0.downloadSpeed + $0.uploadSpeed > $1.downloadSpeed + $1.uploadSpeed }
        case .uploadSpeed:
            return processes.sorted { $0.uploadSpeed > $1.uploadSpeed }
        case .downloadSpeed:
            return processes.sorted { $0.downloadSpeed > $1.downloadSpeed }
        case .name:
            return processes.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
    }

    var maxProcessSpeed: Double {
        sortedProcesses.first.map { $0.downloadSpeed + $0.uploadSpeed } ?? 1
    }

    init() {
        loadSettings()
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: "menuBarDisplayMode"),
           let mode = MenuBarDisplayMode(rawValue: raw) {
            displayMode = mode
        }
        refreshInterval = defaults.double(forKey: "refreshInterval").nonzeroOr(1.0)
        if let raw = defaults.string(forKey: "appearance"),
           let mode = AppearanceMode(rawValue: raw) {
            appearance = mode
        }
        launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        monthlyLimitEnabled = defaults.bool(forKey: "monthlyLimitEnabled")
        monthlyLimitGB = defaults.double(forKey: "monthlyLimitGB").nonzeroOr(100)
        notifyAt80 = defaults.bool(forKey: "notifyAt80")
        if let raw = defaults.string(forKey: "appLanguage"),
           let lang = Language(rawValue: raw) {
            appLanguage = lang
        }
        if let raw = defaults.string(forKey: "processSortMode"),
           let mode = ProcessSortMode(rawValue: raw) {
            processSortMode = mode
        }
    }

    private func saveSetting(_ key: String, value: Any) {
        UserDefaults.standard.set(value, forKey: key)
    }

    func setDisplayMode(_ mode: MenuBarDisplayMode) {
        displayMode = mode
        saveSetting("menuBarDisplayMode", value: mode.rawValue)
    }

    func setRefreshInterval(_ interval: Double) {
        refreshInterval = interval
        saveSetting("refreshInterval", value: interval)
        restartTrafficMonitoring()
    }

    func setAppearance(_ mode: AppearanceMode) {
        appearance = mode
        saveSetting("appearance", value: mode.rawValue)
        applyAppearance()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLogin = enabled
        saveSetting("launchAtLogin", value: enabled)
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
        }
    }

    func setMonthlyLimitEnabled(_ enabled: Bool) {
        monthlyLimitEnabled = enabled
        saveSetting("monthlyLimitEnabled", value: enabled)
    }

    func setMonthlyLimitGB(_ gb: Double) {
        monthlyLimitGB = gb
        saveSetting("monthlyLimitGB", value: gb)
    }

    func setNotifyAt80(_ notify: Bool) {
        notifyAt80 = notify
        saveSetting("notifyAt80", value: notify)
    }

    func setLanguage(_ lang: Language) {
        appLanguage = lang
        saveSetting("appLanguage", value: lang.rawValue)
    }

    func setProcessSortMode(_ mode: ProcessSortMode) {
        processSortMode = mode
        saveSetting("processSortMode", value: mode.rawValue)
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        networkMonitor.startMonitoring()
        trafficService.startMonitoring(interval: refreshInterval)

        networkMonitor.$isConnected
            .receive(on: RunLoop.main)
            .assign(to: \.isConnected, on: self)
            .store(in: &cancellables)

        networkMonitor.$interfaceType
            .receive(on: RunLoop.main)
            .assign(to: \.interfaceType, on: self)
            .store(in: &cancellables)

        networkMonitor.$ipAddress
            .receive(on: RunLoop.main)
            .assign(to: \.ipAddress, on: self)
            .store(in: &cancellables)

        trafficService.$uploadSpeed
            .receive(on: RunLoop.main)
            .assign(to: \.uploadSpeed, on: self)
            .store(in: &cancellables)

        trafficService.$downloadSpeed
            .receive(on: RunLoop.main)
            .assign(to: \.downloadSpeed, on: self)
            .store(in: &cancellables)

        trafficService.$sessionUpload
            .receive(on: RunLoop.main)
            .assign(to: \.sessionUpload, on: self)
            .store(in: &cancellables)

        trafficService.$sessionDownload
            .receive(on: RunLoop.main)
            .assign(to: \.sessionDownload, on: self)
            .store(in: &cancellables)

        trafficService.$speedHistory
            .receive(on: RunLoop.main)
            .assign(to: \.speedHistory, on: self)
            .store(in: &cancellables)

        trafficService.$dailyTotals
            .receive(on: RunLoop.main)
            .assign(to: \.dailyTotals, on: self)
            .store(in: &cancellables)

        processTrafficService.$processes
            .receive(on: RunLoop.main)
            .assign(to: \.processes, on: self)
            .store(in: &cancellables)

        processTrafficService.$isRefreshing
            .receive(on: RunLoop.main)
            .assign(to: \.processIsRefreshing, on: self)
            .store(in: &cancellables)
    }

    func refreshProcesses() {
        processTrafficService.refresh()
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        networkMonitor.stopMonitoring()
        trafficService.stopMonitoring()
        processTrafficService.stopMonitoring()
        cancellables.removeAll()
    }

    func restartTrafficMonitoring() {
        trafficService.stopMonitoring()
        trafficService.startMonitoring(interval: refreshInterval)
    }

    func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond >= 1024 * 1024 {
            return String(format: "%.0f \(locStr("MB/s"))", bytesPerSecond / (1024 * 1024))
        } else if bytesPerSecond >= 1024 {
            return String(format: "%.0f \(locStr("KB/s"))", bytesPerSecond / 1024)
        } else {
            return String(format: "%.0f \(locStr("B/s"))", bytesPerSecond)
        }
    }

    func formatBytes(_ bytes: UInt64) -> String {
        let b = Double(bytes)
        if b >= 1024 * 1024 * 1024 {
            return String(format: "%.0f \(locStr("GB"))", b / (1024 * 1024 * 1024))
        } else if b >= 1024 * 1024 {
            return String(format: "%.0f \(locStr("MB"))", b / (1024 * 1024))
        } else if b >= 1024 {
            return String(format: "%.0f \(locStr("KB"))", b / 1024)
        } else {
            return String(format: "%.0f \(locStr("B"))", b)
        }
    }

    func applyAppearance() {
        switch appearance {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}

private extension Double {
    func nonzeroOr(_ fallback: Double) -> Double {
        self == 0 ? fallback : self
    }
}
