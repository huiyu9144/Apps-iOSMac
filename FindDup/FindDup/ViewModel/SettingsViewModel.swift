import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable {
    case system
    case zhHans
    case en

    var displayName: String {
        switch self {
        case .system: return isCurrentChinese ? "跟随系统" : "System"
        case .zhHans: return "简体中文"
        case .en: return "English"
        }
    }

    private var isCurrentChinese: Bool {
        let preferredLang = Locale.preferredLanguages.first ?? "en"
        return preferredLang.hasPrefix("zh")
    }
}

@MainActor
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.system.rawValue
        currentLanguage = AppLanguage(rawValue: saved) ?? .system
    }

    nonisolated static func isCurrentlyChinese() -> Bool {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.system.rawValue
        let lang = AppLanguage(rawValue: saved) ?? .system
        switch lang {
        case .system:
            let preferredLang = Locale.preferredLanguages.first ?? "en"
            return preferredLang.hasPrefix("zh")
        case .zhHans:
            return true
        case .en:
            return false
        }
    }
}

func loc(_ zh: String, _ en: String) -> String {
    LocalizationManager.isCurrentlyChinese() ? zh : en
}

class SettingsViewModel: ObservableObject {
    @Published var minimumFileSize: Int64 = 1024
    @Published var fileTypeFilter: FileTypeFilter = .all
    @Published var deleteToTrash: Bool = true

    var minimumFileSizeDisplay: String {
        if minimumFileSize < 1024 {
            return "\(minimumFileSize) B"
        } else if minimumFileSize < 1024 * 1024 {
            return "\(minimumFileSize / 1024) KB"
        } else {
            return "\(minimumFileSize / (1024 * 1024)) MB"
        }
    }
}
