# EventBar — 日历事件倒计时器

## 参考通用要求

> 本提示词需要配合 `_shared-requirements.md` 一起使用。所有通用的架构、多语言、性能、关闭/退出机制、设计规范、原生 API 强制要求等均已在该文件中定义，此处不再赘述。

---

## 项目概述

macOS 菜单栏日历事件倒计时工具。在菜单栏显示下一个日程的倒计时（"下次会议: 34 分钟"）。点击展开查看全天日程。比系统日历菜单更直观。

- **定价**：$2.99 买断
- **目标用户**：日程密集的 Mac 用户、会议狂人、Freelancer
- **SF Symbol**：`"calendar.day.timeline.left"`

## 原生 API 强制实现

| 功能 | 强制使用的原生 API |
|------|------------------|
| 日历读取 | `EventKit` / `EKEventStore` |
| 事件查询 | `EKEventStore.enumerateEvents(matching:)` |
| 通知 | `UNUserNotificationCenter` |
| 倒计时 | `Timer.publish(every:tolerance:on:in:)` |
| 时区处理 | `TimeZone` / `DateFormatter` |
| 菜单栏渲染 | `NSStatusItem` + `NSAttributedString` |
| 地点 | `MKLocalSearch`（地址格式化） |

## 核心功能与 UI 流程

### 菜单栏显示

- 空闲时：仅显示图标
- 有日程时：`📅 下次: 站会 (14:30)` 或 `🟢 会议中 (还剩 23 分钟)`
- 多日历时：各日历颜色不同

### 主面板（点击菜单栏图标）

```
┌─────────────────────────────────────┐
│  EventBar                    日历x3  │ ⚙️
│  ─────────────────────────────────  │
│  现在: 12:45                        │
│  ┌ 下一个日程 ───────────────────┐  │
│  │ 🟢 团队站会                    │  │
│  │  13:00 - 13:15 (15 分钟)      │  │
│  │   还剩 15 分钟                  │  │
│  │   周期: 每天 · 工作日           │  │
│  └──────────────────────────────┘  │
│  ─────────────────────────────────  │
│  今日日程:                           │
│  ┌─────────────────────────────┐    │
│  │ ⬜ 09:00 设计评审      ✅    │    │
│  │ 🟪 10:30 客户会议       ✅   │    │
│  │ 🟩 13:00 站会          ◉    │    │
│  │ 🟦 14:30 代码审查            │    │
│  │ 🟧 16:00 周报提交            │    │
│  └─────────────────────────────┘    │
│  ─────────────────────────────────  │
│  明日预览:                           │
│  │ 09:30 面试  14:00 项目同步会    │
│  ─────────────────────────────────  │
│  [📅 打开日历]                      │
│  ─────────────────────────────────  │
│  退出应用                            │
└─────────────────────────────────────┘
```

### 所有按钮与交互路径

| 元素 | 位置 | 点击行为 |
|------|------|---------|
| 下一个日程卡片 | 顶部 | 显示最近的下一个日程倒计时 |
| 🟢 日历颜色 | 日程项 | 根据 EKCalendar.color 显示不同颜色 |
| ✅ 已完成 | 日程项 | 标记为已完成 |
| ◉ 当前 | 日程项 | 当前正在进行的日程 |
| 明日预览 | 底部 | 显示明日最早 3 个日程 |
| 📅 打开日历 | 面板底部 | 调用 `NSWorkspace.shared.open(URL: "ical://")` 打开系统日历 |
| ⚙️ 齿轮 | 右上 | 设置 |
| 退出应用 | 底部 | `NSApplication.shared.terminate(nil)` |

### 设置窗口

```
┌──────────────────────────────┐
│  设置                         │
│  ───────────────────────────  │
│  日历选择:                     │
│  [✓] iCloud                   │
│  [✓] 工作                      │
│  [  ] 生日                     │
│  ───────────────────────────  │
│  菜单栏显示:                   │
│  [显示下一个日程标题] [开关]  │
│  [显示倒计时] [开关]          │
│  ───────────────────────────  │
│  提前提醒:                     │
│  [会议前 5 分钟通知] [开关]   │
│  [会议前 15 分钟通知] [开关]  │
│  ───────────────────────────  │
│  开机自启: [开关]              │
│  外观: [跟随系统 ▼]           │
│  语言: [▼]                    │
│  ───────────────────────────  │
│  [完成]                       │
└──────────────────────────────┘
```

### 性能要求

- **日历读取**：首次启动请求 `EKEventStore` 权限，使用 `enumerateEvents(matching:)` 查询当天+明天
- **刷新策略**：使用 `EKEventStore` 通知（`EKEventStoreChanged`）监听日历变更，不轮询
- **倒计时精度**：菜单栏每 30 秒更新一次，面板内每 1 秒更新（面板关闭时暂停）
- **内存缓存**：缓存当天日程在内存，日历变更时刷新
- **通知**：使用 `UNUserNotificationCenter` 本地通知
- **权限处理**：未授权时显示引导弹窗 + 系统偏好设置路径
- **多日历支持**：勾选要显示的日历后，只查询这些日历的事件

### 关键实现

```swift
import EventKit

@Observable
final class EventBarViewModel {
    private let eventStore = EKEventStore()
    var nextEvent: EKEvent?
    var todayEvents: [EKEvent] = []

    func requestAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            eventStore.requestAccess(to: .event) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    func refreshEvents() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start)!

        let predicate = eventStore.predicateForEvents(
            withStart: start, end: end,
            calendars: selectedCalendars
        )
        let events = eventStore.events(matching: predicate)
        todayEvents = events.sorted { $0.startDate < $1.startDate }
        nextEvent = todayEvents.first { $0.startDate > Date() }
    }
}
```
