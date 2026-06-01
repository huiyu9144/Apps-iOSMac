# 通用要求（所有 Web 工具 v3 共享）

> 所有工具必须参考 `docs/web-tools/invoiceflow/index.html` 的设计系统  
> 纯黑背景 | 毛玻璃面板 | 紫色 #8b8bf8 主色调 | 全部浏览器端运行 | 可直接部署到 Vercel/Netlify

---

## 强制设计系统（必须100%遵循）

| 元素 | 值 |
|------|----|
| 背景色 | `#000000` |
| 面板 | `background: rgba(255,255,255,0.06); border-radius: 14px; padding: 20px; backdrop-filter: blur(10px);` |
| 主色调 | `#8b8bf8`（渐变 `linear-gradient(135deg, #8b8bf8, #c084fc)`） |
| 字体 | `-apple-system, BlinkMacSystemFont, '.SFNSDisplay', sans-serif` |
| 标题 | `30px; font-weight: 700; 渐变色` |
| 分段选择器 | iOS 风格带滑动指示器 `.mode-selector` + `.mode-slider` |
| 数字输入 | 带 +/- 旋钮按钮 |
| toggle 开关 | 42×24px `.toggle-switch` |
| 拖拽上传 | 虚线边框 + hover 紫色发光 |
| 按钮 | `btn-primary` / `btn-success` / `btn-secondary` / `btn-outline` / `btn-sm` |
| 进度条 | 渐变 `linear-gradient(90deg, #8b8bf8, #c084fc)` |
| toast | 固定底部居中，毛玻璃 |
| 动画 | `fadeSlideUp 0.35s cubic-bezier(0.25,0.46,0.45,0.94)` |

## 技术栈

- **纯 Vanilla JS**，禁止 React/Vue/Angular
- **Tailwind CDN** 仅辅助排版
- **零后端依赖** — 所有逻辑浏览器端完成
- **可部署** — 纯静态 HTML，可放 Vercel/Netlify/GitHub Pages

## SEO 要求（每个页面必须）

- `<title>` + `<meta name="description">`
- Open Graph 标签（`og:title`, `og:description`, `og:type`）
- JSON-LD 结构化数据（`WebApplication`）
- 页面底部 Footer：隐私政策链接 + © 版权

## 通用 UI 布局

```
Header → 产品名 + 一句话描述
Main Layout（左右或上下两栏）:
  左侧/上方: Controls 面板（毛玻璃）
  右侧/下方: 结果预览/输出面板（毛玻璃）
Actions: 核心操作按钮
Footer
```
