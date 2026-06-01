# BrightFlow — 自适应屏幕亮度

## 参考通用要求

> 本提示词需要配合 `_shared-requirements.md` 一起使用。所有通用的架构、多语言、性能、关闭/退出机制、设计规范、原生 API 强制要求等均已在该文件中定义，此处不再赘述。

---

## 项目概述

macOS 菜单栏自适应屏幕亮度工具。根据时间自动调节屏幕亮度和色温（日出暖色/日落冷色）。比系统自动亮度调节更精细，支持自定义曲线、定时切换、快捷键。

- **定价**：$2.99 买断
- **目标用户**：长时间使用 Mac、对屏幕亮度/色温敏感的用户
- **SF Symbol**：`"sun.max"`

## 原生 API 强制实现

| 功能 | 强制使用的原生 API |
|------|------------------|
| 亮度控制 | `IOKit` / `IODisplaySetFloatParameter`（`kIODisplayBrightnessKey`） |
| 色温控制 | `CGSetDisplayTransferByTable`（Gamma Table） |
| 日出日落 | `CoreLocation` 获取位置 → `Solar` 算法计算 |
| 定时器 | `Timer.publish(every:tolerance:on:in:)` |
| 环境光传感器 | `IOKit`（`AMBERight` / `LMU`） |
| 快捷键 | `CGEvent` + `addGlobalMonitorForEvents` |

**亮度控制关键实现**：

```swift
import IOKit
import IOKit.graphics

func getDisplayBrightness() -> Float {
    var brightness: Float = 0
    var service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleBacklightDisplay"))
    if service == 0 {
        service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleCLCDDisplay"))
    }
    if service != 0 {
        IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &brightness)
        IOObjectRelease(service)
    }
    return brightness
}

func setDisplayBrightness(_ brightness: Float) {
    var service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleBacklightDisplay"))
    if service == 0 {
        service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleCLCDDisplay"))
    }
    if service != 0 {
        IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, brightness)
        IOObjectRelease(service)
    }
}
```

**色温控制（Gamma Table）**：

```swift
func setColorTemperature(_ temperature: Float) {
    let sampleCount = 256
    var red = [CGGammaValue](repeating: 0, count: sampleCount)
    var green = [CGGammaValue](repeating: 0, count: sampleCount)
    var blue = [CGGammaValue](repeating: 0, count: sampleCount)
    let warmFactor = max(0, min(1, (6500 - temperature) / 3500))
    for i in 0..<sampleCount {
        let v = CGGammaValue(i) / CGGammaValue(sampleCount - 1)
        red[i] = v
        green[i] = v * (1 - warmFactor * 0.15)
        blue[i] = v * (1 - warmFactor * 0.35)
    }
    CGSetDisplayTransferByTable(CGMainDisplayID(), sampleCount, red, green, blue)
}
```

## 核心功能与 UI 流程

### 主面板（点击菜单栏图标）

```
┌─────────────────────────────────────┐
│  BrightFlow                   自动 │ ⚙️
│  ─────────────────────────────────  │
│  当前状态: 🟢 自适应运行中            │
│  ─────────────────────────────────  │
│  当前亮度: ████████░░ 76%            │
│  当前色温: 🟠 4200K (暖色)           │
│  ─────────────────────────────────  │
│  模式: [● 自适应] [○ 锁定] [○ 关闭]  │
│  ─────────────────────────────────  │
│  手动调节:                           │
│  亮度: [⬤──────────] 76%            │
│  色温: [──⬤────────] 4200K          │
│  ─────────────────────────────────  │
│  日出: 06:32  日落: 18:45           │
│  当前: ☀️ 白天 (暖色模式)            │
│  ─────────────────────────────────  │
│  自定义曲线:                         │
│  ┌─ 色温变化曲线 ─────────────┐     │
│  │ 6500K ───────╮              │     │
│  │             ╰╮            ╭─│     │
│  │ 3000K        ╰───────────╯  │     │
│  │      06:00        18:00     │     │
│  └────────────────────────────┘     │
│  ─────────────────────────────────  │
│  退出应用                            │
└─────────────────────────────────────┘
```

### 所有按钮与交互路径

| 元素 | 位置 | 点击行为 |
|------|------|---------|
| 🟢 状态 | 顶部 | 自适应运行/暂停 |
| 当前亮度/色温 | 状态下方 | 实时显示当前值 |
| 模式切换 | 面板中部 | 自适应/锁定当前值/完全关闭 |
| 亮度滑块 | 手动调节区 | 手动调节亮度 |
| 色温滑块 | 手动调节区 | 手动调节色温（3000K-6500K） |
| 日出日落时间 | 面板底部 | 当天日出日落 |
| 曲线图 | 面板底部 | 24 小时色温变化曲线 |
| ⚙️ 齿轮 | 右上 | 设置 |
| 退出应用 | 底部 | `NSApplication.shared.terminate(nil)` |

### 设置窗口

```
┌──────────────────────────────┐
│  设置                         │
│  ───────────────────────────  │
│  亮度范围:                     │
│  最低: [20%]  最高: [100%]   │
│  ───────────────────────────  │
│  色温范围:                     │
│  白天: [6500K]  夜晚: [3400K] │
│  ───────────────────────────  │
│  过渡时长:                     │
│  [30分钟] [1小时] [2小时]    │
│  ───────────────────────────  │
│  Night Shift 集成:             │
│  [使用系统夜览] [覆盖系统设置] │
│  ───────────────────────────  │
│  开机自启: [开关]              │
│  外观: [跟随系统 ▼]           │
│  语言: [▼]                    │
│  ───────────────────────────  │
│  [完成]                       │
└──────────────────────────────┘
```

### 性能要求

- **亮度调节**：使用 `IOKit` API 直接读写硬件寄存器，延迟 < 5ms
- **色温调节**：使用 `CGSetDisplayTransferByTable` 原生 Gamma Table，无需额外进程
- **日出日落计算**：使用纯 Swift 天文算法（Solar 计算），零网络依赖
- **定时刷新**：每 5 分钟检查一次，每分钟平滑过渡 1/5 步长
- **传感器集成**：优先使用 IOKit 环境光传感器，不支持时回退到时间曲线
- **Gamma 恢复**：App 退出时自动恢复默认 Gamma Table（`CGDisplayRestoreColorSyncSettings`）
- **Night Shift 兼容**：检测系统 Night Shift 状态，自动互斥避免冲突
