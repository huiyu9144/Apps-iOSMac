# 通用要求（所有 Web 工具共享）

> 以下要求适用于本目录中每一个工具的提示词，除非特别注明。AI 生成代码时必须遵循。

---

## 技术栈

| 层级 | 强制使用 |
|------|---------|
| **前端框架** | 纯 HTML + CSS + JavaScript（Vanilla JS），**禁止** React/Vue/Angular/Svelte |
| **后端** | Node.js + 原生 `http` 模块 或 Express（仅路由，禁用 ORM/重型框架） |
| **数据库** | SQLite（通过 `better-sqlite3` npm 包）或 JSON 文件 |
| **样式** | Tailwind CSS（CDN 引用，`https://cdn.tailwindcss.com`） |
| **部署** | 单文件部署或简单 Node.js 服务，适合 Vercel/Railway/Fly.io |
| **支付** | Stripe / Lemon Squeezy 直接集成 |
| **模板引擎** | 服务端渲染（SSR），前端用 `fetch` + DOM 操作，不构建 SPA |

## 产品哲学

- **单一功能**：一个工具只解决一个核心问题。不做功能合集。
- **1-2 周 MVP**：从构思到上线不超过 2 周。
- **付费优先**：免费额度仅用于用户验证，核心功能必须付费。
- **零运营成本**：所有计算在客户端完成，或后端成本极低。
- **自带 SEO**：页面标题/描述/结构化数据内置，自然获客。

## 定价模式

| 模式 | 适用场景 |
|------|---------|
| **$4.99-$9.99 买断** | 一次性使用工具（发票生成、隐私政策生成、配色方案导出） |
| **$3-$9/月 订阅** | 持续使用工具（API 调用、分析、存储） |
| **免费 + 付费解锁** | 免费基础功能，付费解锁数量/质量/导出 |

## 页面结构规范

```
/ → Landing Page（SEO 首页）
├── /app         → 核心工具界面
├── /pricing     → 定价页面
├── /login       → 登录（可选，买断制可省略）
└── /privacy     → 隐私政策
```

每个页面必须包含：
1. `<title>` 和 `<meta description>`（SEO 关键）
2. Open Graph 标签（分享时显示卡片）
3. 结构化数据（JSON-LD）
4. 页面底部「隐私政策」+「关于」链接

## 性能要求

- **Lighthouse 分数**：Performance > 90，SEO > 95
- **首屏加载**：< 1.5 秒（JS/CSS 压缩 + 延迟加载非关键资源）
- **核心交互**：< 100ms 响应
- **可离线使用**：核心功能通过 Service Worker 缓存（可选）
- **无追踪器**：不引入 Google Analytics 等第三方追踪（仅用 Plausible/Umami 自建分析，或不加分析）

## 设计规范

- **极简风格**：白底 + 一种品牌色 + 灰色文字层次
- **响应式**：从 320px 到 1920px 完美适配
- **字体**：系统字体栈 `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto`
- **加载状态**：所有操作必须有 loading 态（骨架屏或 spinner）
- **错误处理**：友好错误页面 + 重试按钮
- **多语言**：默认仅英文，但代码结构支持 i18n（用对象字典，不引入 i18n 库）

## 价值主张（Landing Page 必须包含）

```
├── Hero（大标题 + 一句话价值 + CTA 按钮）
├── 痛点场景（2-3 个使用案例，带截图/动图）
├── 定价卡片（清晰对比免费 vs 付费）
├── FAQ（5-8 个常见问题，用于 SEO 长尾词）
└── Footer（隐私政策 + 联系）
```

## 通用的关键功能

每个工具必须实现以下能力：

| 功能 | 要求 |
|------|------|
| **数据隐私** | 用户数据不上传到服务器（或上传后立即删除） |
| **导出/下载** | 支持导出为常见格式（PDF/PNG/JSON/CSV） |
| **分享链接** | 生成永久分享链接（可选） |
| **快捷键** | 常用操作支持键盘快捷键 |
| **黑暗模式** | 通过 CSS `prefers-color-scheme` 自动适配 |
| **无注册可用** | 核心功能可免注册试用，付费仅解锁数量/质量 |

## 部署配置

```json
// package.json
{
  "name": "tool-name",
  "scripts": {
    "start": "node server.js",
    "dev": "node --watch server.js"
  },
  "dependencies": {
    "express": "^4.18",
    "better-sqlite3": "^11.0",
    "stripe": "^15.0"
  }
}
```

```yaml
# vercel.json（Vercel 部署）
{
  "builds": [{ "src": "server.js", "use": "@vercel/node" }],
  "routes": [{ "src": "/(.*)", "dest": "server.js" }]
}
```

> **使用方法**：每个工具的独立 md 文件 + 本共享文件一起发给 AI，即可生成完整可部署的 Web 应用。
