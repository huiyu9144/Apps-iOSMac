# FocusBlock — 应用拦截专注器

## 参考通用要求

> 本提示词需要配合 `_shared-requirements.md` 一起使用。所有通用的架构、多语言、性能、关闭/退出机制、设计规范、原生 API 强制要求等均已在该文件中定义，此处不再赘述。

---

## 项目概述

macOS 菜单栏应用拦截工具。设定专注时段 → 自动拦截干扰 App（无法打开或弹窗提醒）。比 SelfControl 更灵活，支持白名单、定时启停、统计报告。

- **定价**：$3.99 买断
- **目标用户**：需要专注工作的 Mac 用户、易被社交媒体分心者
- **SF Symbol**：`"hand.raised.app"`

## 原生 API 强制实现

| 功能 | 强制使用的原生 API |
|------|------------------|
| 进程监控 | `NSWorkspace.shared.runningApplications` + `NSWorkspace.didLaunchApplicationNotification` |
| 应用拦截 | `LSSharedFileList` / `LaunchServices` + `Kernel` 级（通过 `sandbox` 或 `AuthorizationExecuteWithPrivileges`） |
| 定时器 | `Timer.publish(every:tolerance:on:in:)` |
| 规则存储 | `JSONEncoder` + `UserDefaults` |
| 通知 | `UNUserNotificationCenter` |
| 开机自启 | `SMAppService`（macOS 13+）或 `LoginItemsService` |

**拦截实现方案**（使用 `AuthorizationExecuteWithPrivileges` 执行 `pkill` 或 `sandbox-exec`，无需第三方）：

```swift
// 应用拦截核心逻辑（简化）
func blockApp(bundleID: String) {
    // 方案1：强制退出（轻量）
    NSWorkspace.shared.runningApplications
        .filter { $0.bundleIdentifier == bundleID }
        .forEach { $0.forceTerminate() }

    // 方案2：监听启动事件并立即关闭
    NotificationCenter.default.addObserver(
        forName: NSWorkspace.didLaunchApplicationNotification,
        object: nil,
        queue: .main
    ) { notification in
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == bundleID,
              self.isFocusActive else { return }
        app.forceTerminate()
    }
}
```

## 核心功能与 UI 流程

### 主面板（点击菜单栏图标）

```
┌─────────────────────────────────────┐
│  FocusBlock                   聚焦中 │ ⚙️
│  ─────────────────────────────────  │
│  状态: 🟢 专注中 · 剩余 45 分钟      │
│  [⏹ 停止专注]                       │
│  ─────────────────────────────────  │
│  今日专注: 3 小时 20 分钟             │
│  ─────────────────────────────────  │
│  规则: [工作专注 ▼]                  │
│  ┌─────────────────────────────┐    │
│  │ 🚫 Twitter.com             │    │
│  │ 🚫 抖音/TikTok             │    │
│  │ 🚫 Instagram               │    │
│  │ 🚫 游戏 (Steam/*.app)      │    │
│  │ ✅ VS Code                 │    │
│  │ ✅ Safari                  │    │
│  └─────────────────────────────┘    │
│  ─────────────────────────────────  │
│  快速专注:                           │
│  [25分钟] [45分钟] [60分钟] [自定义] │
│  ─────────────────────────────────  │
│  退出应用                            │
└─────────────────────────────────────┘
```

### 所有按钮与交互路径

| 元素 | 位置 | 点击行为 |
|------|------|---------|
| 🟢 状态指示 | 顶部 | 绿色=专注中/灰色=已暂停 |
| ⏹ 停止专注 | 状态旁 | 提前结束专注时段 |
| 专注时长统计 | 状态下方 | 显示今日累计专注时间 |
| 规则下拉 | 规则区 | 切换预设规则组（工作/学习/休闲/自定义） |
| 规则列表 | 规则区 | 🚫=被拦截 ✅=白名单 |
| 快速专注按钮 | 底部 | 25/45/60 分钟快速开始专注（按当前选中规则执行） |
| 自定义 | 快速专注 | 弹出时间选择器，1-180 分钟 |
| ⚙️ 齿轮 | 右上 | 设置窗口 |
| 退出应用 | 底部 | `NSApplication.shared.terminate(nil)` |

### 设置窗口

```
┌──────────────────────────────────────┐
│  设置                                 │
│  ───────────────────────────────────  │
│  规则管理:                             │
│  ┌──────────────────────────────┐    │
│  │ [工作专注] [学习模式] [+新建] │    │
│  ├──────────────────────────────┤    │
│  │ 白名单 (专注期间可用):       │    │
│  │ [VS Code] [Xcode] [Safari]  │    │
│  │ [+ 添加应用]                  │    │
│  ├──────────────────────────────┤    │
│  │ 黑名单 (专注期间拦截):       │    │
│  │ [Twitter] [抖音] [游戏]     │    │
│  │ [+ 添加应用 / 网站域名]      │    │
│  └──────────────────────────────┘    │
│  ───────────────────────────────────  │
│  自动规则:                             │
│  [工作日 9:00-12:00 自动专注] [开关] │
│  ───────────────────────────────────  │
│  拦截强度:                             │
│  [温和：弹窗提醒] [严格：自动关闭]     │
│  ───────────────────────────────────  │
│  开机自启: [开关]                     │
│  外观: [跟随系统 ▼]                   │
│  语言: [▼]                            │
│  ───────────────────────────────────  │
│  [完成]                                │
└──────────────────────────────────────┘
```

### 焦点弹窗（尝试打开被拦截 App 时）

```
╔═══════════════════════════════════════╗
║         🚫 专注模式进行中              ║
║                                       ║
║     你正在 45 分钟专注时段内            ║
║     还剩 32 分钟                       ║
║                                       ║
║     这个 App 已被拦截                  ║
║     专注结束后才能打开                  ║
║                                       ║
║  [放弃 — 停止专注]  [我再忍忍]         ║
║  放弃次数: 1/3 (今日)                  ║
╚═══════════════════════════════════════╝
```

### 性能要求

- **进程监控**：纯事件驱动（`NSWorkspace.didLaunchApplicationNotification`），不轮询
- **拦截逻辑**：使用 `AuthorizationExecuteWithPrivileges` + `pkill`，不安装任何内核扩展
- **定时器**：使用 `DispatchSourceTimer`（系统级精确，不受 UI 暂停影响）
- **统计存储**：每日数据写入 `UserDefaults`，每周清理一次旧数据
- **规则持久化**：JSON 文件存入 `~/Library/Application Support/FocusBlock/`
- **无后台进程**：拦截逻辑仅在前台活跃时运行，不常驻后台
- **权限请求**：仅需 Accessibility 权限（用于检测窗口），首次启动时引导
