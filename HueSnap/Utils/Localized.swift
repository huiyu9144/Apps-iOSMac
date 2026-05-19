import SwiftUI

enum Language: String, CaseIterable {
    case system = "system"
    case zhHans = "zh-Hans"
    case en = "en"
    case ja = "ja"

    var displayName: String {
        switch self {
        case .system: return locStr("跟随系统")
        case .zhHans: return "中文"
        case .en: return "English"
        case .ja: return "日本語"
        }
    }
}

private let translations: [String: [String: String]] = [
    "设置": ["en": "Settings", "zh-Hans": "设置", "ja": "設定"],
    "设置…": ["en": "Settings…", "zh-Hans": "设置…", "ja": "設定…"],
    "退出": ["en": "Quit", "zh-Hans": "退出", "ja": "終了"],
    "退出应用": ["en": "Quit App", "zh-Hans": "退出应用", "ja": "アプリを終了"],
    "跟随系统": ["en": "System Default", "zh-Hans": "跟随系统", "ja": "システムに従う"],
    "语言": ["en": "Language", "zh-Hans": "语言", "ja": "言語"],
    "应用界面显示语言": ["en": "App display language", "zh-Hans": "应用界面显示语言", "ja": "アプリの表示言語"],
    "完成": ["en": "Done", "zh-Hans": "完成", "ja": "完了"],
    "关于": ["en": "About", "zh-Hans": "关于", "ja": "について"],
    "通用": ["en": "General", "zh-Hans": "通用", "ja": "一般"],
    "首页": ["en": "Home", "zh-Hans": "首页", "ja": "ホーム"],
    "版本": ["en": "Version", "zh-Hans": "版本", "ja": "バージョン"],
    "删除": ["en": "Delete", "zh-Hans": "删除", "ja": "削除"],
    "开始取色": ["en": "Start Picker", "zh-Hans": "开始取色", "ja": "スポイト開始"],
    "取色历史": ["en": "History", "zh-Hans": "取色历史", "ja": "履歴"],
    "色板": ["en": "Palette", "zh-Hans": "色板", "ja": "パレット"],
    "复制Hex": ["en": "Copy Hex", "zh-Hans": "复制Hex", "ja": "Hexをコピー"],
    "复制RGB": ["en": "Copy RGB", "zh-Hans": "复制RGB", "ja": "RGBをコピー"],
    "复制HSL": ["en": "Copy HSL", "zh-Hans": "复制HSL", "ja": "HSLをコピー"],
    "复制Tailwind": ["en": "Copy Tailwind", "zh-Hans": "复制Tailwind", "ja": "Tailwindをコピー"],
    "保存到色板": ["en": "Save to Palette", "zh-Hans": "保存到色板", "ja": "パレットに保存"],
    "输出格式": ["en": "Output Format", "zh-Hans": "输出格式", "ja": "出力形式"],
    "已复制": ["en": "Copied", "zh-Hans": "已复制", "ja": "コピーしました"],
    "导出色板": ["en": "Export Palette", "zh-Hans": "导出色板", "ja": "パレットをエクスポート"],
    "导入色板": ["en": "Import Palette", "zh-Hans": "导入色板", "ja": "パレットをインポート"],
    "吸取颜色": ["en": "Pick Color", "zh-Hans": "吸取颜色", "ja": "色を吸い取る"],
]

private var currentLanguage: String {
    let raw = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
    if raw == "system" {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("zh") { return "zh-Hans" }
        if preferred.hasPrefix("ja") { return "ja" }
        return "en"
    }
    return raw
}

func locStr(_ key: String) -> String {
    let lang = currentLanguage
    return translations[key]?[lang] ?? key
}
