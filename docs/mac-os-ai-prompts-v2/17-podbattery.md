# PodBattery — 蓝牙设备电量监视器

## 参考通用要求

> 本提示词需要配合 `_shared-requirements.md` 一起使用。所有通用的架构、多语言、性能、关闭/退出机制、设计规范、原生 API 强制要求等均已在该文件中定义，此处不再赘述。

---

## 项目概述

macOS 菜单栏蓝牙设备电量监视器。在菜单栏显示 AirPods、Magic Mouse、Magic Keyboard 等蓝牙设备的电池电量。比系统自带的蓝牙菜单信息更丰富、更直观。

- **定价**：$1.99 买断（极低价走量，开发者工具赛道已验证）
- **目标用户**：使用 AirPods/蓝牙耳机的 Mac 用户
- **SF Symbol**：`"battery.100"`

## 原生 API 强制实现

| 功能 | 强制使用的原生 API |
|------|------------------|
| 蓝牙设备发现 | `IOBluetoothDevice` / `IOBluetoothDevicePaired` |
| 电量读取 | `IOKit` 注册表（`IOServiceGetMatchingServices` + `IORegistryEntryCreateCFProperty`） |
| 设备名称 | `IOBluetoothDevice.name` |
| 连接状态 | `IOBluetoothDevice.isConnected` |
| 通知 | `UNUserNotificationCenter` |
| 菜单栏渲染 | `NSStatusItem` + `NSAttributedString` |

**电量读取关键实现**（使用 IOKit 原生 API）：

```swift
import IOKit
import IOKit.bluetooth

func readBatteryLevel(for deviceAddress: String) -> Int? {
    var iterator: io_iterator_t = 0
    let matching = IOServiceMatching("AppleDeviceManagementHIDEventService")
    IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)

    var service: io_object_t = IOIteratorNext(iterator)
    while service != 0 {
        if let batteryProp = IORegistryEntryCreateCFProperty(
            service, "BatteryPercent" as CFString,
            kCFAllocatorDefault, 0
        )?.takeRetainedValue() as? Int {
            // 读取设备地址匹配
            return batteryProp
        }
        service = IOIteratorNext(iterator)
    }
    IOObjectRelease(iterator)
    return nil
}
```

## 核心功能与 UI 流程

### 菜单栏显示

- 有设备连接时：显示所有已连接设备的电量图标
- 仅图标模式：🟢 AirPods（80%）⌨️ KB（65%）
- 连接断开时：图标灰色

### 主面板（点击菜单栏图标）

```
┌─────────────────────────────────────┐
│  PodBattery                          │ ⚙️
│  ─────────────────────────────────  │
│  已连接设备:                          │
│  ┌─────────────────────────────┐    │
│  │ 🎧 AirPods Pro             │    │
│  │   左耳: 🟢████████░░ 78%   │    │
│  │   右耳: 🟢██████████ 92%   │    │
│  │   充电盒: 🟡██████░░░░ 55% │    │
│  │   型号: A2084               │    │
│  │   固件: 4E71               │    │
│  ├─────────────────────────────┤    │
│  │ ⌨️ Magic Keyboard          │    │
│  │   🟡███████░░░ 65%         │    │
│  │   型号: A2449              │    │
│  ├─────────────────────────────┤    │
│  │ 🖱 Magic Mouse             │    │
│  │   🔴███░░░░░░░ 28%  ⚠️     │    │
│  │   电量低！                   │    │
│  └─────────────────────────────┘    │
│  ─────────────────────────────────  │
│  未连接设备:                          │
│  │  Beats Studio Buds (已配对)     │
│  ─────────────────────────────────  │
│  电量低通知: [已启用]                │
│  ─────────────────────────────────  │
│  退出应用                            │
└─────────────────────────────────────┘
```

### 所有按钮与交互路径

| 元素 | 位置 | 点击行为 |
|------|------|---------|
| 已连接设备列表 | 中部 | 显示每个设备的详细电量信息 |
| 🟢/🟡/🔴 图标 | 设备行 | 绿色>60%、黄色30-60%、红色<30% |
| ⚠️ 警告 | 低电量设备 | 红色警告标识，提示充电 |
| 未连接设备 | 设备列表下方 | 已配对但未连接的设备列表（灰色） |
| ⚙️ 齿轮 | 右上 | 设置 |
| 退出应用 | 底部 | `NSApplication.shared.terminate(nil)` |

### 设置窗口

```
┌──────────────────────────────┐
│  设置                         │
│  ───────────────────────────  │
│  菜单栏显示:                   │
│  [仅显示电量最低的设备] [开关] │
│  [显示所有连接设备] [开关]    │
│  ───────────────────────────  │
│  电量低提醒:                   │
│  阈值: [20%] [30%] [40%]     │
│  [充电提醒] [开关]           │
│  ───────────────────────────  │
│  刷新频率:                     │
│  [1分钟] [5分钟] [10分钟]    │
│  ───────────────────────────  │
│  开机自启: [开关]              │
│  外观: [跟随系统 ▼]           │
│  语言: [▼]                    │
│  ───────────────────────────  │
│  [完成]                       │
└──────────────────────────────┘
```

### 性能要求

- **电量读取**：使用 `IOKit` 注册表直接读取（延迟 < 10ms），不启动蓝牙扫描
- **刷新策略**：默认 5 分钟轮询一次 IOKit 注册表，面板打开时立即刷新
- **菜单栏更新**：面板关闭时只更新电量数字（不刷新 UI，降低 CPU）
- **电池历史**：不存储历史数据（隐私优先），仅显示当前电量
- **通知**：使用 `UNUserNotificationCenter` 在电量低于阈值时推送
- **IOKit 资源释放**：每次查询后调用 `IOObjectRelease` 释放迭代器，避免内存泄漏
- **扫描周期**：面板关闭时降低扫描频率至 10 分钟，App 启动时立即扫描一次
