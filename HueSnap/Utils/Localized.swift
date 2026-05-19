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
    "退出应用": ["en": "Quit", "zh-Hans": "退出应用", "ja": "アプリを終了"],
    "外观": ["en": "Appearance", "zh-Hans": "外观", "ja": "外観"],
    "跟随系统": ["en": "Follow System", "zh-Hans": "跟随系统", "ja": "システムに従う"],
    "浅色": ["en": "Light", "zh-Hans": "浅色", "ja": "ライト"],
    "深色": ["en": "Dark", "zh-Hans": "深色", "ja": "ダーク"],
    "语言": ["en": "Language", "zh-Hans": "语言", "ja": "言語"],
    "语言 Language 言語": ["en": "Language", "zh-Hans": "语言", "ja": "言語"],
    "开机自启": ["en": "Launch at Login", "zh-Hans": "开机自启", "ja": "ログイン時に起動"],
    "完成": ["en": "Done", "zh-Hans": "完成", "ja": "完了"],
    "关于": ["en": "About", "zh-Hans": "关于", "ja": "について"],
    "版本": ["en": "Version", "zh-Hans": "版本", "ja": "バージョン"],
    "取消": ["en": "Cancel", "zh-Hans": "取消", "ja": "キャンセル"],
    "保存": ["en": "Save", "zh-Hans": "保存", "ja": "保存"],
    "复制": ["en": "Copy", "zh-Hans": "复制", "ja": "コピー"],
    "删除": ["en": "Delete", "zh-Hans": "删除", "ja": "削除"],
    "编辑": ["en": "Edit", "zh-Hans": "编辑", "ja": "編集"],
    "搜索": ["en": "Search", "zh-Hans": "搜索", "ja": "検索"],
    "无结果": ["en": "No Results", "zh-Hans": "无结果", "ja": "結果なし"],
    "HueSnap": ["en": "HueSnap", "zh-Hans": "HueSnap", "ja": "HueSnap"],
    "开始取色": ["en": "Start Picker", "zh-Hans": "开始取色", "ja": "スポイト開始"],
    "取色历史": ["en": "History", "zh-Hans": "取色历史", "ja": "履歴"],
    "色板": ["en": "Palette", "zh-Hans": "色板", "ja": "パレット"],
    "全部": ["en": "All", "zh-Hans": "全部", "ja": "すべて"],
    "当前取色": ["en": "Current Color", "zh-Hans": "当前取色", "ja": "現在の色"],
    "复制Hex": ["en": "Copy Hex", "zh-Hans": "复制Hex", "ja": "Hexをコピー"],
    "复制RGB": ["en": "Copy RGB", "zh-Hans": "复制RGB", "ja": "RGBをコピー"],
    "复制HSL": ["en": "Copy HSL", "zh-Hans": "复制HSL", "ja": "HSLをコピー"],
    "复制Tailwind": ["en": "Copy Tailwind", "zh-Hans": "复制Tailwind", "ja": "Tailwindをコピー"],
    "保存到色板": ["en": "Save to Palette", "zh-Hans": "保存到色板", "ja": "パレットに保存"],
    "输出格式": ["en": "Output Format", "zh-Hans": "输出格式", "ja": "出力形式"],
    "取色器已就绪": ["en": "Color Picker Ready", "zh-Hans": "取色器已就绪", "ja": "スポイト準備完了"],
    "单击取色": ["en": "Click to Pick", "zh-Hans": "单击取色", "ja": "クリックで選択"],
    "按 ESC 取消": ["en": "Press ESC to Cancel", "zh-Hans": "按 ESC 取消", "ja": "ESCでキャンセル"],
    "放大倍数": ["en": "Zoom Level", "zh-Hans": "放大倍数", "ja": "ズーム倍率"],
    "快捷键": ["en": "Shortcut", "zh-Hans": "快捷键", "ja": "ショートカット"],
    "已复制": ["en": "Copied", "zh-Hans": "已复制", "ja": "コピーしました"],
    "确定删除此色块？": ["en": "Delete this color?", "zh-Hans": "确定删除此色块？", "ja": "この色を削除しますか？"],
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
