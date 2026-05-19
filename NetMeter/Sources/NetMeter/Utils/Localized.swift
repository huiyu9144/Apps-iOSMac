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

    "NetMeter": ["en": "NetMeter", "zh-Hans": "NetMeter", "ja": "NetMeter"],
    "实时图表": ["en": "Live Chart", "zh-Hans": "实时图表", "ja": "リアルタイムチャート"],
    "概览": ["en": "Overview", "zh-Hans": "概览", "ja": "概要"],
    "上传": ["en": "Upload", "zh-Hans": "上传", "ja": "アップロード"],
    "下载": ["en": "Download", "zh-Hans": "下载", "ja": "ダウンロード"],
    "今日": ["en": "Today", "zh-Hans": "今日", "ja": "今日"],
    "当前网络": ["en": "Current Network", "zh-Hans": "当前网络", "ja": "現在のネットワーク"],
    "联网进程": ["en": "Active Processes", "zh-Hans": "联网进程", "ja": "ネットワークプロセス"],
    "每周流量报告": ["en": "Weekly Traffic Report", "zh-Hans": "每周流量报告", "ja": "週間トラフィックレポート"],
    "趋势图": ["en": "Trend", "zh-Hans": "趋势图", "ja": "トレンド"],
    "流量概览": ["en": "Traffic Overview", "zh-Hans": "流量概览", "ja": "トラフィック概要"],
    "菜单栏显示": ["en": "Menu Bar Display", "zh-Hans": "菜单栏显示", "ja": "メニューバー表示"],
    "显示速度": ["en": "Show Speed", "zh-Hans": "显示速度", "ja": "速度を表示"],
    "显示总流量": ["en": "Show Total Traffic", "zh-Hans": "显示总流量", "ja": "合計トラフィックを表示"],
    "刷新频率": ["en": "Refresh Interval", "zh-Hans": "刷新频率", "ja": "更新頻度"],
    "流量提醒": ["en": "Traffic Alert", "zh-Hans": "流量提醒", "ja": "トラフィックアラート"],
    "月流量上限": ["en": "Monthly Limit", "zh-Hans": "月流量上限", "ja": "月間上限"],
    "达到 80% 时通知": ["en": "Notify at 80%", "zh-Hans": "达到 80% 时通知", "ja": "80% 到達時に通知"],
    "秒": ["en": "sec", "zh-Hans": "秒", "ja": "秒"],
    "GB": ["en": "GB", "zh-Hans": "GB", "ja": "GB"],
    "MB/s": ["en": "MB/s", "zh-Hans": "MB/s", "ja": "MB/s"],
    "KB/s": ["en": "KB/s", "zh-Hans": "KB/s", "ja": "KB/s"],
    "B/s": ["en": "B/s", "zh-Hans": "B/s", "ja": "B/s"],
    "MB": ["en": "MB", "zh-Hans": "MB", "ja": "MB"],
    "KB": ["en": "KB", "zh-Hans": "KB", "ja": "KB"],
    "无网络连接": ["en": "No Network Connection", "zh-Hans": "无网络连接", "ja": "ネットワーク接続なし"],
    "未连接": ["en": "Not Connected", "zh-Hans": "未连接", "ja": "未接続"],
    "周一": ["en": "Mon", "zh-Hans": "周一", "ja": "月"],
    "周二": ["en": "Tue", "zh-Hans": "周二", "ja": "火"],
    "周三": ["en": "Wed", "zh-Hans": "周三", "ja": "水"],
    "周四": ["en": "Thu", "zh-Hans": "周四", "ja": "木"],
    "周五": ["en": "Fri", "zh-Hans": "周五", "ja": "金"],
    "周六": ["en": "Sat", "zh-Hans": "周六", "ja": "土"],
    "周日": ["en": "Sun", "zh-Hans": "周日", "ja": "日"],
    "进程": ["en": "Process", "zh-Hans": "进程", "ja": "プロセス"],
    "PID": ["en": "PID", "zh-Hans": "PID", "ja": "PID"],
    "查看详情": ["en": "Details", "zh-Hans": "查看详情", "ja": "詳細"],
    "复制 PID": ["en": "Copy PID", "zh-Hans": "复制 PID", "ja": "PID をコピー"],
    "已复制": ["en": "Copied", "zh-Hans": "已复制", "ja": "コピーしました"],
    "上传速度": ["en": "Upload Speed", "zh-Hans": "上传速度", "ja": "アップロード速度"],
    "下载速度": ["en": "Download Speed", "zh-Hans": "下载速度", "ja": "ダウンロード速度"],
    "总上传": ["en": "Total Upload", "zh-Hans": "总上传", "ja": "合計アップロード"],
    "总下载": ["en": "Total Download", "zh-Hans": "总下载", "ja": "合計ダウンロード"],
    "最近 60 秒": ["en": "Last 60s", "zh-Hans": "最近 60 秒", "ja": "過去 60 秒"],
    "今日流量": ["en": "Today's Traffic", "zh-Hans": "今日流量", "ja": "今日のトラフィック"],
    "本月已用": ["en": "This Month", "zh-Hans": "本月已用", "ja": "今月の使用量"],
    "无流量数据": ["en": "No Traffic Data", "zh-Hans": "无流量数据", "ja": "トラフィックデータなし"],
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
