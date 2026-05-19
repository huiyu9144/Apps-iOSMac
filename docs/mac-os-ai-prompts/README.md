# macOS 菜单栏工具 — AI 提示词合集

> 生成日期：2026-05-19  
> 用途：将这些提示词发给 AI（Claude/GPT），即可生成完整可编译的 macOS SwiftUI 菜单栏应用  
> 设计哲学：极简、原生、高性能、多语言、买断制

---

## 使用方式

1. 首先阅读 [通用要求 `_shared-requirements.md`](./_shared-requirements.md) — 所有 App 共享的架构/多语言/性能规范
2. 选择你想做的 App，打开对应的 md 文件
3. 将该 App 的完整内容 + 通用要求一起发给 AI

## App 列表

| # | 名称 | 定价 | 开发时间 | 描述 |
|---|------|------|---------|------|
| 1 | [PicShrink](./01-picshrink.md) | $3.99 | 1周 | 批量图片压缩 |
| 2 | [SplitView](./02-splitview.md) | $2.99 | 1周 | 窗口分屏管理 |
| 3 | [HashCalc](./03-hashcalc.md) | $1.99 | 3-5天 | 文件哈希校验 |
| 4 | [FormatQuick](./04-formatquick.md) | $4.99 | 1周 | 批量格式转换 |
| 5 | [ClarityMate](./05-claritymate.md) | $4.99/月 | 2-3周 | AI写作助手 |
| 6 | [NetMeter](./06-netmeter.md) | $4.99 | 1-2周 | 网络流量监控 |
| 7 | [ScreenBreak](./07-screenbreak.md) | $2.99 | 1周 | 强制休息提醒 |
| 8 | [MuteMate](./08-mutemate.md) | $3.99 | 1周 | 智能麦克风管理 |
| 9 | [HueSnap](./09-huesnap.md) | $4.99 | 1周 | 屏幕取色器 |
| 10 | [MockFlow](./10-mockflow.md) | $5.99 | 1-2周 | Mock Server GUI |
| 11 | [EnvLens](./11-envlens.md) | $3.99 | 1周 | 环境变量管理 |
| 12 | [IconDock](./12-icondock.md) | $4.99 | 1周 | 图标美化工具 |

## 名称变更说明

| 原用名 | 现用名 | 原因 |
|-------|-------|------|
| FavConvert | **FormatQuick** | 避免与现有 App 冲突 |
| NetGuard | **NetMeter** | 与命名统一（MenuMeter 风格） |
| ColorSnap | **HueSnap** | App Store 已有同名 |
| MockAPI Studio | **MockFlow** | 统一命名风格（ClipFlow 呼应） |
