# LinkDash — Link-in-Bio + 分析

## 参考通用要求

> 配合 [_shared-requirements.md](file:///c:/Users/Administrator/Desktop/111111/jia-ios/docs/web-tools/_shared-requirements.md) 使用。技术栈、设计规范、部署配置等通用要求不再重复。

---

## 项目概述

LinkDash 是一个 Link-in-Bio 工具，帮助创作者、网红和小企业主在 Instagram/TikTok/Twitter 等平台的个人简介中放置一个聚合链接页。用户在 LinkDash 创建一个页面，集中展示所有社交链接、商店链接和博客链接，并实时查看点击分析数据。免费版 1 个页面，付费版 $4/月解锁 3 页面 + 完整分析。

## 目标用户

- 创作者（YouTuber、TikToker、主播）—— 在个人简介放聚合链接页
- 网红/KOL —— 需要分析粉丝点了哪些链接
- 小企业主 —— 集中展示官网、商店、预约、社交账号
- 自由职业者 —— 作品集 + 约稿链接 + 社交账号

## 定价

| 版本 | 价格 | 功能 |
|------|------|------|
| Free | $0 | 1 个页面、基础主题色、5 个按钮、基本点击计数 |
| Pro | $4/月 | 3 个页面、自定义主题/头像/按钮样式、完整分析（PV/UV/设备/来源）、CSV 导出、优先支持 |

买断制不适用（持续使用工具，采用订阅模式）。

## 核心功能与 UI 流程

### 首页 Landing

```
/ → Landing Page
├── Hero: "你的链接，一个页面，全部搞定" + CTA "免费创建页面"
├── 痛点场景:
│   ├── "Linktree 免费版只有 1 个主题" → 展示 LinkDash 自定义主题对比
│   ├── "每月 $5 太贵，还没分析" → "LinkDash $4/月 带完整分析"
│   └── "想看哪个链接被点得最多" → 展示分析仪表盘截图
├── 示例展示: 实时预览一个示例 LinkDash 页面
├── 定价卡片: Free vs Pro 对比
├── FAQ: 6-8 个常见问题
└── Footer
```

### 工具界面

**编辑后台 `/app`**（需登录）：
```
/app → 用户仪表盘
├── 页面列表（展示已有页面，支持切换）
├── 页面编辑器:
│   ├── 头像上传（裁剪、圆角）
│   ├── 用户名 / 显示名
│   ├── 个人简介文字
│   ├── 主题色选择器（预设色 + 自定义 Hex）
│   ├── 按钮样式（圆角/方形/带边框）
│   └── 链接列表（拖拽排序）
├── 添加链接弹窗:
│   ├── 标题
│   ├── URL
│   ├── 图标（自动从 URL 识别 favicon，或手动选 emoji）
│   └── 启用/禁用
└── 分享链接: 一键复制 `/u/username`
```

**分析页面 `/app/analytics`**（Pro 功能）：
```
/app/analytics → 分析仪表盘
├── 概览卡片: 总 PV、总 UV、今日 PV、今日 UV
├── 折线图: 7 天/30 天趋势
├── 设备分布: 移动端 vs 桌面端饼图
├── 来源分析: direct/social/search/referral
├── 单个链接点击排名
└── 导出 CSV 按钮
```

**公开展示页 `/u/:username`**：
```
/u/username → 公开展示页
├── 头像（圆形）
├── 显示名
├── 个人简介
├── 链接按钮列表（纵排，可设定顺序）
└── Footer: "由 LinkDash 提供"（小字）
```

## 所有按钮与交互路径

| 按钮/交互 | 位置 | 触发动作 |
|-----------|------|---------|
| 「免费创建页面」 | 首页 Hero | 跳转 `/app` 注册 |
| 「查看示例」 | 首页 | 弹出示例页面预览 |
| 「开始免费使用」 | 首页定价卡片 Free | 跳转 `/app` |
| 「升级到 Pro」 | 首页定价卡片 Pro | 跳转 Stripe 结账 |
| 「+ 添加链接」 | `/app` 编辑后台 | 弹出添加链接弹窗 |
| 「保存」 | 编辑后台 | 保存当前页面配置 |
| 「预览」 | 编辑后台 | 新窗口打开 `/u/username?preview` |
| 「复制链接」 | 编辑后台 | 复制公开页 URL 到剪贴板 |
| 「分析」 | 编辑后台 | 跳转 `/app/analytics` |
| 「导出 CSV」 | `/app/analytics` | 下载分析数据 CSV 文件 |
| 「删除链接」 | 编辑后台（拖拽右侧） | 确认后删除该链接 |
| 「拖拽排序」 | 编辑后台链接列表 | 拖拽改变链接顺序 |
| 「主题色选择」 | 编辑后台主题设置 | 点击色块/输入 Hex 实时预览 |
| 「头像上传」 | 编辑后台 | 打开文件选择器，裁剪后上传 |

## SEO 关键词

- link in bio tool
- free link in bio
- linktree alternative
- link analytics
- best link in bio for creators
- Instagram bio link tool
- TikTok bio link tool
- click tracking for links

## 性能要求

- 公开展示页 `/u/:username` 必须是静态直出，首屏 < 1s
- 编辑后台 `/app` 页面加载 < 2s
- 分析图表使用 Canvas 绘制（不引入 Chart.js 等重型库），渲染 < 200ms
- 头像图片自动压缩为 WebP 格式，最大宽度 200px
- 链接点击跳转先经过 `/click/:id` 记录后再 302 跳转目标 URL
- 分析数据缓存 5 分钟，避免频繁查库
