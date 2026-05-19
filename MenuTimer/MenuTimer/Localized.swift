import SwiftUI

enum Language: String, CaseIterable {
    case system = "system"
    case zhHans = "zh-Hans"
    case en = "en"

    var displayName: String {
        switch self {
        case .system: return locStr("跟随系统")
        case .zhHans: return "中文"
        case .en: return "English"
        }
    }
}

private let translations: [String: [String: String]] = [
    "MenuTimer": ["en": "MenuTimer", "zh-Hans": "MenuTimer"],
    "自定义": ["en": "Custom", "zh-Hans": "自定义"],
    "输入分钟...": ["en": "Enter minutes...", "zh-Hans": "输入分钟..."],
    "番茄钟模式": ["en": "Pomodoro", "zh-Hans": "番茄钟模式"],
    "25/5 min": ["en": "25/5 min", "zh-Hans": "25/5 分钟"],
    "停止": ["en": "Stop", "zh-Hans": "停止"],
    "继续": ["en": "Resume", "zh-Hans": "继续"],
    "暂停": ["en": "Pause", "zh-Hans": "暂停"],
    "工作中": ["en": "Focusing", "zh-Hans": "工作中"],
    "休息中": ["en": "On Break", "zh-Hans": "休息中"],
    "番茄钟 ": ["en": "Pomodoro ", "zh-Hans": "番茄钟 "],
    "设置": ["en": "Settings", "zh-Hans": "设置"],
    "通知": ["en": "Notifications", "zh-Hans": "通知"],
    "通知中心提醒": ["en": "Notification Center", "zh-Hans": "通知中心提醒"],
    "播放提示音": ["en": "Play Sound", "zh-Hans": "播放提示音"],
    "番茄钟": ["en": "Pomodoro", "zh-Hans": "番茄钟"],
    "工作时长": ["en": "Work Duration", "zh-Hans": "工作时长"],
    "休息时长": ["en": "Break Duration", "zh-Hans": "休息时长"],
    " 分钟": ["en": " min", "zh-Hans": " 分钟"],
    "关于": ["en": "About", "zh-Hans": "关于"],
    "版本": ["en": "Version", "zh-Hans": "版本"],
    "MenuTimer — 菜单栏极简倒计时器": ["en": "MenuTimer — Minimal menu bar timer", "zh-Hans": "MenuTimer — 菜单栏极简倒计时器"],
    "外观": ["en": "Appearance", "zh-Hans": "外观"],
    "跟随系统": ["en": "Follow System", "zh-Hans": "跟随系统"],
    "浅色": ["en": "Light", "zh-Hans": "浅色"],
    "深色": ["en": "Dark", "zh-Hans": "深色"],
    "退出应用": ["en": "Quit", "zh-Hans": "退出应用"],
    "语言": ["en": "Language", "zh-Hans": "语言"],
    "timer_up": ["en": "Timer is up!", "zh-Hans": "时间到！"],
    "work_complete": ["en": "Work session complete! Time for a break.", "zh-Hans": "工作完成！该休息了。"],
    "break_over": ["en": "Break over! Time to work.", "zh-Hans": "休息结束！开始工作吧。"],
    "退出番茄模式": ["en": "Exit Pomodoro", "zh-Hans": "退出番茄模式"],
]

private var currentLanguage: String {
    let raw = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
    if raw == "system" {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("zh") { return "zh-Hans" }
        return "en"
    }
    return raw
}

func locStr(_ key: String) -> String {
    let lang = currentLanguage
    return translations[key]?[lang] ?? key
}
