# FindDup — macOS 重复文件查找清理工具 · 设计文档

> 设计日期：2026-05-18

## 一、产品定位

Mac 上最简单好用的重复文件查找器，帮助用户找回磁盘空间。$5.99 买断制，对标 Gemini 2（$29.99），定位"便宜又好用"的市场空白。

## 二、技术方案

| 项目 | 方案 |
|------|------|
| 框架 | SwiftUI + AppKit（macOS 14+） |
| 架构 | MVVM + Actors |
| 文件扫描 | FileManager + DirectoryEnumerator |
| 哈希比对 | CommonCrypto（MD5 + SHA256 双确认） |
| 项目类型 | Xcode Project (.xcodeproj) |
| 最低支持 | macOS 14 Sonoma |
| 包体积目标 | < 3MB |
| 安全 | App Sandbox（用户选择文件夹） |

## 三、项目结构

```
FindDup.xcodeproj
└── FindDup/
    ├── App/
    │   ├── FindDupApp.swift          # @main 入口
    │   └── ContentView.swift         # 主界面 HSplitView
    ├── Core/
    │   ├── FileInfo.swift            # 文件信息模型
    │   ├── FileScanner.swift         # 文件遍历扫描 (Actor)
    │   ├── HashCalculator.swift      # MD5/SHA256 (Actor)
    │   ├── DuplicateFinder.swift     # 三级递进去重 (Actor)
    │   ├── DuplicateGroup.swift      # 重复组模型
    │   └── FileDeleter.swift         # 文件删除 (Actor)
    ├── ViewModel/
    │   ├── ScanViewModel.swift       # 扫描状态管理
    │   ├── ResultViewModel.swift     # 结果选中/删除管理
    │   └── SettingsViewModel.swift   # 设置选项管理
    └── View/
        ├── ScanPanelView.swift       # 空闲/扫描中界面
        ├── ResultPanelView.swift     # 结果列表 + 工具栏
        ├── DuplicateGroupRow.swift   # 重复组行（可展开）
        ├── FileRowView.swift         # 文件行（勾选 + 详情）
        └── SettingsView.swift        # 设置面板
```

## 四、架构分层

```
┌──────────────────────────────────┐
│  View 层 (SwiftUI)               │
│  @ObservedObject → ViewModel     │
├──────────────────────────────────┤
│  ViewModel (@MainActor)          │
│  ScanVM / ResultVM / SettingsVM  │
├──────────────────────────────────┤
│  Core 层 (Actor)                 │
│  FileScanner / HashCalculator    │
│  DuplicateFinder / FileDeleter   │
├──────────────────────────────────┤
│  模型层                           │
│  FileInfo / DuplicateGroup       │
└──────────────────────────────────┘
```

## 五、主界面布局

```
┌────────────────────────────────────────────────────────┐
│ ┌─────────────┐ ┌────────────────────────────────────┐ │
│ │  FindDup     │ │                                    │ │
│ │  📁 选择文件夹 │ │  ScanPanelView / ResultPanelView   │ │
│ │  🔄 新建扫描  │ │  空闲: 图标 + 选择按钮 + 拖拽区    │ │
│ │  ⚙️ 设置     │ │  扫描中: 进度条 + 文件数 + 取消    │ │
│ └─────────────┘ │  完成: 结果列表 + 工具栏             │ │
│                  └────────────────────────────────────┘ │
└────────────────────────────────────────────────────────┘
```

## 六、核心数据流

1. 用户选择文件夹 → `ScanViewModel.startScan()`
2. `FileScanner.scanDirectory()` 递归遍历，回调进度
3. `DuplicateFinder.findDuplicates()` 三级去重：大小分组 → MD5 分组 → SHA256 确认
4. 结果按可释放空间降序排列
5. `ResultPanelView` 展示 → 用户勾选 → `FileDeleter.moveToTrash()`

## 七、交互细节

| 状态 | 视图 | 交互 |
|------|------|------|
| idle | ScanPanelView（大图标+选择按钮+拖拽虚线框） | 点击按钮/拖拽文件夹 |
| scanning | ScanPanelView（旋转动画+进度条+文件数+取消） | 取消按钮中止扫描 |
| completed | ResultPanelView（结果头部+工具栏+分组列表） | 展开/折叠/勾选/全选/删除 |

## 八、设置面板

- **通用**：最小文件大小（1KB/10KB/100KB/1MB/10MB）、删除方式（废纸篓/直接删除）
- **筛选**：文件类型过滤（全部/图片/文档/视频/音乐）

## 九、安全设计

| 安全项 | 实现 |
|--------|------|
| App Sandbox | ✅ |
| 用户选择文件夹 | NSOpenPanel |
| 文件删除 | 默认移到废纸篓 |
| 哈希安全 | 流式读取 1MB buffer |
| 线程安全 | Core Actors + @MainActor ViewModel |
| 取消安全 | isCancelled 标志位 |

## 十、V1.0 刻意不做

- ❌ 全盘扫描
- ❌ 相似图片检测
- ❌ 自动清理
- ❌ 缩略图预览
