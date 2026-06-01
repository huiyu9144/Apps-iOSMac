# macOS 菜单栏工具 — AI 提示词合集（第二辑）

> 生成日期：2026-05-19  
> 设计哲学：极简、原生（零第三方依赖）、高性能、多语言、买断制  
> ⚠️ 本辑特别强调：所有功能强制使用 **macOS 原生 API** 和 **Swift 原生能力**，禁用所有第三方库

---

## 使用方式

1. 先阅读 [通用要求 `_shared-requirements.md`](./_shared-requirements.md) — 所有 App 共享架构/多语言/原生 API 映射/性能规范
2. 选择你想做的 App，打开对应 md 文件
3. 将该 App 的完整内容 + 通用要求一起发给 AI

## App 列表

| # | 名称 | 定价 | 开发时间 | 描述 | 核心原生 API |
|---|------|------|---------|------|------------|
| 1 | [PasteSync](./11-pastesync.md) | $3.99 买断 | 1-2周 | 通用剪贴板历史 + iCloud 同步 | `NSPasteboard` / `NSUbiquitousKeyValueStore` / `CloudKit` |
| 2 | [ScratchPad](./12-scratchpad.md) | $2.99 买断 | 1周 | 浮动速记板（Markdown + 标签） | `NSTextView` / `JSONEncoder` / `FileManager` |
| 3 | [FocusBlock](./13-focusblock.md) | $3.99 买断 | 1周 | 应用拦截专注器 | `NSWorkspace` / `CGEvent` / `AuthorizationExec` |
| 4 | [QuickDict](./14-quickdict.md) | $3.99 买断 | 1-2周 | 快捷词典 & 翻译 | `DCSCopyTextDefinition` / `NSSpeechSynthesizer` / `AXUIElement` |
| 5 | [FolderPeek](./15-folderpeek.md) | $2.99 买断 | 1周 | 菜单栏文件夹快捷访问 | `FileManager` / `QLPreviewPanel` / `DispatchSourceFileSystemObject` |
| 6 | [KeyCastr](./16-keycastr.md) | $3.99 买断 | 1-2周 | 按键可视化显示器 | `CGEventTap` / `NSPanel` / `CATextLayer` / `CoreAnimation` |
| 7 | [PodBattery](./17-podbattery.md) | $1.99 买断 | 3-5天 | 蓝牙设备电量监视器 | `IOKit` / `IOBluetooth` / `IORegistryEntryCreateCFProperty` |
| 8 | [TextPilot](./18-textpilot.md) | $4.99 买断 | 1-2周 | 文本片段/模板扩展器 | `CGEvent` / `Trie` / `JSONEncoder` |
| 9 | [EventBar](./19-eventbar.md) | $2.99 买断 | 1周 | 日历事件倒计时器 | `EventKit` / `EKEventStore` / `UNUserNotificationCenter` |
| 10 | [BrightFlow](./20-brightflow.md) | $2.99 买断 | 1-2周 | 自适应屏幕亮度/色温 | `IOKit` / `CGSetDisplayTransferByTable` / `CoreLocation` |
| 11 | [PureCanvas](./21-purecanvas.md) | $1.99 买断 | 3-5天 | 纯色背景板（截图/绿幕） | `NSWindow` / `NSPanel` / `NSColorPanel` / `NSScreen` |

## 原生 API 使用亮点（本辑特色）

| App | 最具亮点的原生 API 实现 |
|-----|----------------------|
| PodBattery | 通过 `IOKit` 注册表直接读取蓝牙设备电量，无需蓝牙扫描 |
| BrightFlow | 通过 `IODisplaySetFloatParameter` 控制硬件亮度，`CGSetDisplayTransferByTable` 控制色温 |
| KeyCastr | 通过 `CGEventTap` 低延迟捕获按键事件，`CATextLayer` 实时渲染 |
| QuickDict | 通过 `DCSCopyTextDefinition` 读取系统词典，`NSSpeechSynthesizer` 发音 |
| TextPilot | 通过 `CGEvent.post` 模拟键盘输入，`Trie` 树加速缩写匹配 |
| FocusBlock | 通过 `NSWorkspace.didLaunchApplicationNotification` 事件驱动拦截 |
| PureCanvas | 通过 `NSWindow.backgroundColor` 毫秒级切换纯色，`NSScreen.screens` 多显示器覆盖 |
