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

    "拖拽图片或文件夹到此处": ["en": "Drop images or folders here", "zh-Hans": "拖拽图片或文件夹到此处", "ja": "画像またはフォルダをここにドロップ"],
    "选择图片": ["en": "Select Images", "zh-Hans": "选择图片", "ja": "画像を選択"],
    "或拖拽到此处": ["en": "or drag & drop here", "zh-Hans": "或拖拽到此处", "ja": "またはここにドロップ"],
    "支持多选": ["en": "Multi-select supported", "zh-Hans": "支持多选", "ja": "複数選択可"],
    "已添加": ["en": "Added", "zh-Hans": "已添加", "ja": "追加済み"],
    "张图片": ["en": " images", "zh-Hans": "张图片", "ja": "枚の画像"],
    "张": ["en": "", "zh-Hans": "张", "ja": "枚"],
    "个": ["en": " files", "zh-Hans": "个", "ja": "個"],
    "清除": ["en": "Clear", "zh-Hans": "清除", "ja": "クリア"],
    "格式": ["en": "Format", "zh-Hans": "格式", "ja": "形式"],
    "目标格式": ["en": "Target Format", "zh-Hans": "目标格式", "ja": "出力形式"],
    "选项": ["en": "Options", "zh-Hans": "选项", "ja": "オプション"],
    "质量": ["en": "Quality", "zh-Hans": "质量", "ja": "品質"],
    "调整尺寸": ["en": "Resize", "zh-Hans": "调整尺寸", "ja": "サイズ変更"],
    "保持 EXIF": ["en": "Preserve Metadata", "zh-Hans": "保留照片信息", "ja": "写真情報を保持"],
    "保留照片信息": ["en": "Preserve Metadata", "zh-Hans": "保留照片信息", "ja": "写真情報を保持"],
    "开始转换": ["en": "Convert", "zh-Hans": "开始转换", "ja": "変換開始"],
    "转换中": ["en": "Converting", "zh-Hans": "转换中", "ja": "変換中"],
    "正在转换": ["en": "Converting", "zh-Hans": "正在转换", "ja": "変換中"],
    "转换完成": ["en": "Conversion Complete", "zh-Hans": "转换完成", "ja": "変換完了"],
    "转换失败": ["en": "Conversion Failed", "zh-Hans": "转换失败", "ja": "変換失敗"],
    "输出目录": ["en": "Output Folder", "zh-Hans": "输出目录", "ja": "出力フォルダ"],
    "与源文件相同": ["en": "Same as Source", "zh-Hans": "与源文件相同", "ja": "元と同じ"],
    "桌面": ["en": "Desktop", "zh-Hans": "桌面", "ja": "デスクトップ"],
    "自定义": ["en": "Custom", "zh-Hans": "自定义", "ja": "カスタム"],
    "覆盖同名文件": ["en": "Overwrite Existing", "zh-Hans": "覆盖同名文件", "ja": "同名ファイルを上書き"],
    "转换后打开文件夹": ["en": "Open Folder After Convert", "zh-Hans": "转换后打开文件夹", "ja": "変換後にフォルダを開く"],
    "通用": ["en": "General", "zh-Hans": "通用", "ja": "一般"],
    "输出": ["en": "Output", "zh-Hans": "输出", "ja": "出力"],
    "请先添加图片": ["en": "Please add images first", "zh-Hans": "请先添加图片", "ja": "最初に画像を追加してください"],
    "宽度": ["en": "Width", "zh-Hans": "宽度", "ja": "幅"],
    "高度": ["en": "Height", "zh-Hans": "高度", "ja": "高さ"],
    "全部清除": ["en": "Clear All", "zh-Hans": "全部清除", "ja": "すべてクリア"],
    "添加图片": ["en": "Add Images", "zh-Hans": "添加图片", "ja": "画像を追加"],
    "没有选择图片": ["en": "No images selected", "zh-Hans": "没有选择图片", "ja": "画像が選択されていません"],
    "张 → 约": ["en": " files → ~", "zh-Hans": "张 → 约", "ja": "枚 → 約"],
    "秒": ["en": "s", "zh-Hans": "秒", "ja": "秒"],
    "适应": ["en": "Fit", "zh-Hans": "适应", "ja": "フィット"],
    "填充": ["en": "Fill", "zh-Hans": "填充", "ja": "塗りつぶし"],
    "拉伸": ["en": "Stretch", "zh-Hans": "拉伸", "ja": "伸縮"],
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
