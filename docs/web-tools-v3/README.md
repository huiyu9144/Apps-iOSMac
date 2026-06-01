# Web 工具 v3 — 可部署公网工具合集

> 生成日期：2026-05-19  
> 用途：每个工具都是完整可运行的 HTML 页面，丢到 Vercel/Netlify/GitHub Pages 即可上线  
> 设计系统：纯黑背景 · 毛玻璃面板 · 紫色 #8b8bf8 主色调 · iOS 风格控件 · 零依赖

---

## 使用方式

1. 选择你要部署的工具，进入对应文件夹
2. 将整个文件夹部署到 Vercel / Netlify / GitHub Pages
3. 每个页面已内置 SEO meta + Privacy footer

## 工具列表

| # | 名称 | 文件夹 | 一句话描述 |
|---|------|--------|-----------|
| 1 | **QRFlow** | `qrflow/` | QR 码生成器 · 批量生成 · Logo嵌入 · 导出 PNG/SVG/ZIP |
| 2 | **TextDiff** | `textdiff/` | 文本对比工具 · 逐行/逐字 · 高亮增删改 · 导出 HTML |
| 3 | **MetaPreview** | `metapreview/` | OG 标签预览 · Twitter/FB/LinkedIn/Slack 模拟 · SEO 分析 |
| 4 | **RegexLab** | `regexlab/` | 正则测试器 · 实时高亮 · 模板库 · 多语言代码生成 |
| 5 | **CSVViewer** | `csvviewer/` | CSV/JSON 查看器 · 排序搜索 · 数据类型推断 · 导出 |
| 6 | **PricingPage** | `pricingpage/` | 定价表生成器 · 3 模板 · 套餐编辑 · 导出 HTML/React |
| 7 | **TimerFlow** | `timerflow/` | 在线计时器 · 番茄钟 · 秒表 · 全屏模式 · Web Audio |
| 8 | **Readability** | `readability/` | 文章提取器 · 阅读主题 · 4 级字体 · 导出 Markdown |
| 9 | **FormWizard** | `formwizard/` | 表单构建器 · 8 种字段 · 拖拽编辑 · 导出 HTML/React |
| 10 | **UnitConvert** | `unitconvert/` | 开发者单位转换 · 6 大类 · 双向换算 · 4 级精度 |

## 部署方式

```
┌─ 静态部署（推荐）─────────────────────────────────┐
│                                                    │
│  1. 将工具文件夹（如 qrflow/）上传到 GitHub         │
│  2. 在 Vercel 中导入该项目                         │
│  3. ✅ 自动部署，获得公网 URL                       │
│  4. 绑定自定义域名（如 qrflow.yourdomain.com）      │
│                                                    │
│  成本: 0 元（Vercel Free 计划）                     │
│  时间: 5 分钟                                      │
└────────────────────────────────────────────────────┘
```

## SEO 策略

每个工具页面已内置：
- 唯一 `<title>` + `<meta description>`（精准长尾词）
- Open Graph 标签（分享到社交平台时显示卡片）
- JSON-LD 结构化数据（`WebApplication` 类型）
- 每个工具都是独立子域名部署，SEO 隔离
