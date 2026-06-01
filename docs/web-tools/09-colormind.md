# ColorMind — 从图片提取配色

## 参考通用要求

> 配合 [_shared-requirements.md](file:///c:/Users/Administrator/Desktop/111111/jia-ios/docs/web-tools/_shared-requirements.md) 使用。技术栈、设计规范、部署配置等通用要求不再重复。

---

## 项目概述

ColorMind 是一个从图片自动提取配色方案的工具。设计师和前端开发者上传一张图片，纯前端 Canvas 处理自动提取 5-8 种主色，生成调色板并支持一键导出为 CSS/Tailwind/Sass 变量。免费提取，$3.99 买断解锁导出和无限历史记录。

## 目标用户

- UI/UX 设计师 —— 从灵感图提取配色方案
- 前端开发者 —— 从设计稿或参考网站截图提取颜色变量
- 插画师/平面设计师 —— 从摄影作品提取色彩主题
- 产品经理 —— 快速获取竞品配色方案

## 定价

| 版本 | 价格 | 功能 |
|------|------|------|
| Free | $0 | 上传图片提取配色、查看色值（Hex）、5 条历史记录 |
| Pro | $3.99 买断 | 导出 JSON/CSS/Tailwind/Sass、色值格式 Hex/RGB/HSL/OKLCH、一键复制、无限历史记录 |

买断制适用（一次性使用工具，用户提取配色后不需要持续付费）。

## 核心功能与 UI 流程

### 首页 Landing + 工具

单页应用 `/app`，Landing 和工具界面合一：

```
/app → 单页应用
├── Hero 区域:
│   ├── 标题: "从图片发现配色，一秒搞定"
│   ├── 副标题: "上传图片，自动提取主色调，导出 CSS/Tailwind/Sass 变量"
│   └── 上传区域（拖拽上传 / 点击选择）
├── 上传 & 提取流程:
│   ├── 拖拽上传或点击选择图片
│   ├── Canvas 读取图片（纯前端，不上传服务器）
│   ├── 颜色聚类算法（K-Means 或中位切割）提取 5-8 种主色
│   └── 展示调色板
├── 调色板展示:
│   ├── 色块卡片（大块展示，每块占一行或网格排列）
│   ├── 每块显示色值（默认 Hex，可切换 RGB/HSL/OKLCH）
│   ├── 一键复制单个色值
│   └── 复制全部色值（以列表形式）
├── 导出按钮:
│   ├── 导出为 CSS 自定义属性（`--color-primary: #...`）
│   ├── 导出为 Tailwind 配置（`colors: { primary: '...' }`）
│   ├── 导出为 Sass 变量（`$color-primary: #...`）
│   ├── 导出为 JSON
│   └── 导出为 PNG 调色板预览图
├── 历史记录（Pro 功能）:
│   ├── 历史提取列表（缩略图 + 主色预览）
│   ├── 点击重新查看
│   └── 删除
├── FAQ: 6-8 个常见问题
└── Footer
```

**颜色提取算法流程**（纯前端，在 Canvas 中完成）：
```
用户上传图片
     ↓
Canvas 读取为 ImageData
     ↓
下采样至 200×200px（减少计算量）
     ↓
颜色聚类（中位切割 Median Cut 或 K-Means 迭代 5 次）
     ↓
提取主色并排序（按占比从高到低）
     ↓
生成色值（Hex/RGB/HSL/OKLCH）
     ↓
展示调色板
```

## 所有按钮与交互路径

| 按钮/交互 | 位置 | 触发动作 |
|-----------|------|---------|
| 「点击上传」 | 首页上传区域 | 打开文件选择器（支持 JPG/PNG/WebP/SVG） |
| 「拖拽图片」 | 首页上传区域 | 拖拽释放后自动触发提取 |
| 「色块点击」 | 调色板 | 复制单个色值到剪贴板，显示 "已复制" 提示 |
| 「切换色值格式」 | 调色板上方 | 循环切换 Hex → RGB → HSL → OKLCH |
| 「复制全部」 | 调色板 | 复制所有色值（当前格式，逗号分隔） |
| 「导出 CSS」 | 导出区域 | 下载 `.css` 文件（CSS 自定义属性格式） |
| 「导出 Tailwind」 | 导出区域 | 下载 `.js` 文件（Tailwind config 格式） |
| 「导出 Sass」 | 导出区域 | 下载 `.scss` 文件（Sass 变量格式） |
| 「导出 JSON」 | 导出区域 | 下载 `.json` 文件 |
| 「导出 PNG」 | 导出区域 | 下载调色板预览图 |
| 「历史记录」 | 页面侧边/底部 | 展开历史记录列表 |
| 「点击历史条目」 | 历史列表 | 重新加载该次提取的调色板 |
| 「删除历史」 | 历史列表 | 确认后删除该条记录 |
| 「买断 Pro」 | 导出区域 / 历史区域 | 跳转 Stripe / Lemon Squeezy 结账 |
| 「上传新图片」 | 调色板展示区 | 清空当前结果，返回上传状态 |

## SEO 关键词

- color palette from image
- extract colors from image
- image color picker
- color palette generator
- CSS color palette
- Tailwind color palette
- color scheme from photo
- extract color palette online
- color palette tool
- image to color palette

## 性能要求

- 全部处理在客户端 Canvas 完成，零服务器计算成本
- 下采样至 200×200px 后进行聚类，提取耗时 < 500ms（普通图片）
- 大图片（> 10MB）自动压缩后再处理，不超过内存限制
- 导出文件生成在客户端完成，无服务器写入
- 历史记录存储在 localStorage（Free 5 条 / Pro 无限），不上传到服务器
- 页面首屏 < 1.5s（无外部依赖，仅引用 Tailwind CDN）
