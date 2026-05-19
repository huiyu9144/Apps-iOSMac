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
    "选择文件/文件夹": ["en": "Select Files/Folder", "zh-Hans": "选择文件/文件夹", "ja": "ファイル/フォルダを選択"],
    "已选择": ["en": "Selected", "zh-Hans": "已选择", "ja": "選択済み"],
    "张图片": ["en": " images", "zh-Hans": " 张图片", "ja": " 枚の画像"],
    "压缩后质量": ["en": "Output Quality", "zh-Hans": "压缩后质量", "ja": "出力品質"],
    "最佳画质": ["en": "Best", "zh-Hans": "最佳画质", "ja": "最高画質"],
    "高质量": ["en": "High", "zh-Hans": "高质量", "ja": "高品質"],
    "中等质量": ["en": "Medium", "zh-Hans": "中等质量", "ja": "中品質"],
    "最小体积": ["en": "Smallest", "zh-Hans": "最小体积", "ja": "最小サイズ"],
    "压缩并导出": ["en": "Compress & Export", "zh-Hans": "压缩并导出", "ja": "圧縮してエクスポート"],
    "取消压缩": ["en": "Cancel", "zh-Hans": "取消压缩", "ja": "圧縮をキャンセル"],
    "正在压缩...": ["en": "Compressing...", "zh-Hans": "正在压缩...", "ja": "圧縮中..."],
    "节省": ["en": "Saved", "zh-Hans": "节省", "ja": "節約"],
    "张图片已压缩": ["en": " images compressed", "zh-Hans": " 张图片已压缩", "ja": " 枚の画像を圧縮"],
    "输出格式": ["en": "Output Format", "zh-Hans": "输出格式", "ja": "出力フォーマット"],
    "覆盖原文件": ["en": "Overwrite Original", "zh-Hans": "覆盖原文件", "ja": "元ファイルを上書き"],
    "保留 EXIF": ["en": "Preserve EXIF", "zh-Hans": "保留 EXIF", "ja": "EXIFを保持"],
    "压缩后自动打开文件夹": ["en": "Auto Open Folder After Compression", "zh-Hans": "压缩后自动打开文件夹", "ja": "圧縮後にフォルダを開く"],
    "选择图片": ["en": "Select Images", "zh-Hans": "选择图片", "ja": "画像を選択"],
    "选择文件夹": ["en": "Select Folder", "zh-Hans": "选择文件夹", "ja": "フォルダを選択"],
    "所有图片": ["en": "All Images", "zh-Hans": "所有图片", "ja": "すべての画像"],
    "压缩完成": ["en": "Compression Complete", "zh-Hans": "压缩完成", "ja": "圧縮完了"],
    "压缩失败": ["en": "Compression Failed", "zh-Hans": "压缩失败", "ja": "圧縮失敗"],
    "导出至": ["en": "Export to", "zh-Hans": "导出至", "ja": "エクスポート先"],
]

var currentLanguage: String {
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
