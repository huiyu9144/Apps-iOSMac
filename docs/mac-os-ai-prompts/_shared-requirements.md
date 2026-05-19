# 通用要求（所有 App 共享）

> 以下要求适用于本目录中每一个 App 的提示词，除非特别注明。AI 生成代码时必须遵循。

---

## 技术栈

- **语言**：纯 Swift
- **框架**：SwiftUI + AppKit（`NSStatusItem` + `NSPopover` 模式）
- **最低版本**：macOS 14.0+
- **架构**：MVVM（`@Observable` 或 `@ObservableObject`）
- **第三方依赖**：零依赖。仅使用苹果原生框架（AppKit、SwiftUI、Foundation、Combine、Vision、NaturalLanguage、CommonCrypto 等）

## 项目结构

```
{AppName}/
├── App/
│   ├── {AppName}App.swift        # @main，@NSApplicationDelegateAdaptor
│   └── AppDelegate.swift         # NSStatusItem + NSPopover 生命周期
├── MenuBar/
│   └── MenuBarPopoverView.swift   # 主面板视图（菜单栏下拉内容）
├── Views/
│   ├── SettingsView.swift         # 设置窗口
│   └── {其他子视图}
├── ViewModels/
│   └── {AppName}ViewModel.swift   # 核心业务逻辑
├── Services/
│   └── {各功能服务}.swift
├── Utils/
│   ├── Localized.swift            # 多语言翻译表
│   └── KeyboardShortcutManager.swift
├── Assets.xcassets/
│   ├── Contents.json
│   └── AppIcon.appiconset/
└── Info.plist
```

## 菜单栏模式（所有 App 相同）

```swift
// AppDelegate 核心骨架
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var viewModel: {AppName}ViewModel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        viewModel = {AppName}ViewModel()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.target = self
        statusItem.button?.image = NSImage(systemSymbolName: "{sfSymbol}", accessibilityDescription: "{AppName}")

        let hostingView = NSHostingView(rootView: AnyView(MenuBarPopoverView(viewModel: viewModel)))
        popover = NSPopover()
        popover.contentSize = NSSize(width: {width}, height: {height})
        popover.behavior = .transient
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = hostingView
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            rebuildPopoverContent()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func rebuildPopoverContent() {
        let hostingView = NSHostingView(rootView: AnyView(MenuBarPopoverView(viewModel: viewModel)))
        popover.contentViewController?.view = hostingView
    }
}
```

## 多语言实现

- 使用字典翻译表（`Localized.swift` 模式）
- 默认支持：**简体中文**、**英文（美国）**、**日文**
- 通过 `@AppStorage("appLanguage")` 存储用户选择
- 语言选项：跟随系统 / 中文 / English / 日本語
- 所有用户可见文本必须通过 `locStr("key")` 函数引用
- Settings 页面必须有「语言 Language 言語」下拉选择器

```swift
// Localized.swift
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
    // 格式: "中文键": ["en": "English", "zh-Hans": "中文", "ja": "日本語"],
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
```

## 性能铁律

- **空闲 CPU < 0.1%**：不轮询，用系统回调/通知/Combine 驱动
- **内存 < 30MB**：不缓存大对象，及时释放资源
- **启动 < 1 秒**：懒加载所有非关键资源
- **菜单栏关闭时彻底停止**：`popover.performClose(nil)` + 暂停所有定时器
- **所有 I/O/计算在后台线程**：`Task.detached(priority: .utility)` 或 `DispatchQueue.global(qos: .utility)`
- **UI 更新切回主线程**：`@MainActor` 或 `await MainActor.run`

## 关闭/退出机制（所有 App 必须包含）

1. **点击菜单栏外部区域**：`popover.behavior = .transient` 自动关闭面板
2. **面板底部「退出应用」按钮**：调用 `NSApplication.shared.terminate(nil)`
3. **菜单栏图标右键菜单**：添加 `NSMenu`，包含「设置…」和「退出」两个选项
4. **快捷键 Cmd+Q**：系统默认，无需额外处理

```swift
// 在 statusItem 上添加右键菜单
let menu = NSMenu()
menu.addItem(NSMenuItem(title: locStr("设置…"), action: #selector(openSettings), keyEquivalent: ","))
menu.addItem(NSMenuItem.separator())
menu.addItem(NSMenuItem(title: locStr("退出"), action: #selector(terminateApp), keyEquivalent: "q"))
statusItem.menu = menu

// 左键点击弹出面板
statusItem.button?.action = #selector(togglePopover)
statusItem.button?.target = self

// 处理左键/右键分离
statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
```

## 设计规范

- **极简风格**：只有必要的 UI 元素，没有装饰性冗余
- **原生控件**：使用 `Color(.controlBackgroundColor)`、`Color(.separatorColor)`、`.ultraThinMaterial` 等系统材质
- **深色/浅色**：通过 `@AppStorage("appearance")` 支持 system/light/dark 三种模式
- **圆角**：统一使用 `RoundedRectangle(cornerRadius: 10-16, style: .continuous)`
- **字体**：`.system(size:weight:design: .rounded)` 统一风格
- **SF Symbols**：所有图标使用内置 SF Symbols，不引入自定义图标
- **阴影**：面板阴影 `.shadow(color: .black.opacity(0.1), radius: 24, y: 10)`
- **按钮反馈**：点击时 `.scaleEffect(0.92-0.97)` + `.opacity` 动画

## 多语言翻译表参考

每个 App 都需要在自己的 `Localized.swift` 中定义以下翻译：

```swift
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
]
```

## Xcode 项目配置

```xml
<!-- Info.plist -->
<key>LSUIElement</key>
<true/>  <!-- 菜单栏 App，不出现在 Dock 和 App Switcher -->
```

```xml
<!-- {AppName}.entitlements -->
<key>com.apple.security.app-sandbox</key>
<false/>  <!-- 目标 App Store 以外分发，不需要 Sandbox -->
```

---

> **使用方法**：每个独立 App 的 md 文件 + 本共享文件一起发给 AI，即可生成完整 Xcode 项目。
> **命名规范**：所有 App 名称为英文驼峰，统一不带空格，后缀风格统一（Meter/Flow/Snap/Quick/Clean/Lens 等）。
> **价格参考**：$2.99-$5.99 买断，对标市面上 $7.99-$49 的竞品，用 1/3 到 1/5 的价格吃中间市场。
