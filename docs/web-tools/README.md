# Web 工具 — AI 提示词合集

> 生成日期：2026-05-19  
> 用途：将这些提示词发给 AI（Claude/GPT），即可生成完整可部署的 Web 应用  
> 哲学：纯 Vanilla JS、SSR、零第三方追踪、1-2 周 MVP 上线收美金

---

## 使用方式

1. 先阅读 [通用要求 `_shared-requirements.md`](./_shared-requirements.md) — 所有工具共享的技术栈/定价/设计规范
2. 选择你想做的工具，打开对应 md 文件
3. 将该文件 + 通用要求一起发给 AI

## 工具列表

| # | 名称 | 定价 | 开发时间 | 验证赛道 | 核心卖点 |
|---|------|------|---------|---------|---------|
| 1 | [InvoiceFlow](./01-invoiceflow.md) | $5/月 | 1周 | Freelancer 开票 | 纯前端 PDF 生成，不上传服务器 |
| 2 | [SnapResize](./02-snapresize.md) | $4-9/月 | 1周 | 社媒运营 | 20+ 平台预设尺寸，批量处理 |
| 3 | [PDFForge](./03-pdfforge.md) | $4.99 买断 | 1周 | 办公文档 | PDF.js 浏览器端处理，隐私安全 |
| 4 | [FakeAPI](./04-fakeapi.md) | $9-29/月 | 1周 | 开发者工具 | 假数据 API，Alex 月入 $40K 验证 |
| 5 | [SigCraft](./05-sigcraft.md) | $3.99 买断 | 3-5天 | 职场工具 | 邮件签名 HTML 生成，多种模板 |
| 6 | [LinkDash](./06-linkdash.md) | $4/月 | 1周 | 创作者经济 | Linktree 平替 + 点击分析 |
| 7 | [PrivacyGen](./07-privacygen.md) | $4.99 买断 | 1周 | App 开发者 | 多法规合规文档自动生成 |
| 8 | [WebhookInspect](./08-webhookinspect.md) | $5/月 | 1周 | 开发者工具 | Webhook 实时接收 + SSE 推送 |
| 9 | [ColorMind](./09-colormind.md) | $3.99 买断 | 3-5天 | 设计师 | 图片自动配色提取 + CSS 导出 |
| 10 | [FlashPage](./10-flashpage.md) | $5/月 | 1周 | 营销 | Coming Soon 倒计时页生成器 |

## 定价模式分布

| 模式 | 工具 | 特点 |
|------|------|------|
| **$3.99-$4.99 买断**（5个） | PDFForge、SigCraft、PrivacyGen、ColorMind | 一次性使用，零续费焦虑 |
| **$4-$9/月 订阅**（5个） | InvoiceFlow、SnapResize、FakeAPI、LinkDash、WebhookInspect、FlashPage | 持续使用，复利效应 |

## 为什么选这些工具

| 验证逻辑 | 对应工具 | 数据支撑 |
|---------|---------|---------|
| **大公司竞品太贵** | InvoiceFlow vs FreshBooks($15/月)、PDFForge vs Adobe($25/月) | 你的价格是竞品 1/3 到 1/5 |
| **免费工具功能太少** | LinkDash vs Linktree、SnapResize vs Canva | 免费用户 → 付费转化 |
| **已验证的 OPC 赛道** | FakeAPI → Alex $40K/月、WebhookInspect → RequestBin $5K/月 | 有人做成功了 |
| **高频刚需** | SigCraft（每个职场人都需要）、PrivacyGen（每个 App 都需要） | 搜索量稳定，转化率高 |
| **情绪驱动购买** | FlashPage（产品上线焦虑 → 立即购买）、ColorMind（看到好图立刻想配色） | 冲动消费，高价转化 |

## 技术亮点

| 工具 | 技术亮点 |
|------|---------|
| InvoiceFlow | `jsPDF` 浏览器端生成 PDF，零服务器负载 |
| SnapResize | `Canvas` API 纯前端裁剪，批量用 `OffscreenCanvas`（Web Worker） |
| PDFForge | `pdf.js`（Mozilla 开源）浏览器端操作 PDF |
| FakeAPI | Node.js 纯内存数据生成，`faker.js` 无数据库 |
| SigCraft | 纯 DOM 操作生成 HTML 签名，即时预览 |
| LinkDash | SQLite 存储 + 点击事件异步写入（不阻塞页面渲染） |
| PrivacyGen | 规则引擎根据用户回答动态生成法律文档 |
| WebhookInspect | `Server-Sent Events` 实时推送，请求体存储在内存环形缓冲区 |
| ColorMind | `Canvas.getImageData` 颜色量化算法（中位切割/ K-Means） |
| FlashPage | 纯 CSS 倒计时动画，`localStorage` 持久化配置 |
