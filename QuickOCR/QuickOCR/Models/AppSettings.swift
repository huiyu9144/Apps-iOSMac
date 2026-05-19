import Foundation

enum NotificationMode: String, CaseIterable, Codable {
    case silent
    case notification
    case sound

    var displayName: String {
        switch self {
        case .silent: return "Silent"
        case .notification: return "Notification"
        case .sound: return "Sound"
        }
    }
}

class AppSettings: ObservableObject {
    @Published var shortcutKeyCode: Int {
        didSet { save() }
    }
    @Published var shortcutModifiers: Int {
        didSet { save() }
    }
    @Published var recognitionLanguages: [String] {
        didSet { save() }
    }
    @Published var autoCopy: Bool {
        didSet { save() }
    }
    @Published var notificationMode: NotificationMode {
        didSet { save() }
    }
    @Published var launchAtLogin: Bool {
        didSet { save() }
    }
    @Published var hasCompletedFirstLaunch: Bool {
        didSet { save() }
    }

    static let shared = AppSettings()

    private let userDefaultsKey = "QuickOCR.Settings"

    private init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(SettingsData.self, from: data) {
            self.shortcutKeyCode = decoded.shortcutKeyCode
            self.shortcutModifiers = decoded.shortcutModifiers
            self.recognitionLanguages = decoded.recognitionLanguages
            self.autoCopy = decoded.autoCopy
            self.notificationMode = decoded.notificationMode
            self.launchAtLogin = decoded.launchAtLogin
            self.hasCompletedFirstLaunch = decoded.hasCompletedFirstLaunch
        } else {
            self.shortcutKeyCode = 0
            self.shortcutModifiers = 768
            self.recognitionLanguages = ["zh-Hans", "en-US"]
            self.autoCopy = true
            self.notificationMode = .silent
            self.launchAtLogin = false
            self.hasCompletedFirstLaunch = false
        }
    }

    private func save() {
        let data = SettingsData(
            shortcutKeyCode: shortcutKeyCode,
            shortcutModifiers: shortcutModifiers,
            recognitionLanguages: recognitionLanguages,
            autoCopy: autoCopy,
            notificationMode: notificationMode,
            launchAtLogin: launchAtLogin,
            hasCompletedFirstLaunch: hasCompletedFirstLaunch
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            UserDefaults.standard.synchronize()
        }
    }

    private struct SettingsData: Codable {
        let shortcutKeyCode: Int
        let shortcutModifiers: Int
        let recognitionLanguages: [String]
        let autoCopy: Bool
        let notificationMode: NotificationMode
        let launchAtLogin: Bool
        let hasCompletedFirstLaunch: Bool
    }
}
