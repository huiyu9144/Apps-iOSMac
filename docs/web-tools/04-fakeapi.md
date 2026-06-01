# FakeAPI — 假数据生成 API

## 参考通用要求

> 配合 [_shared-requirements.md](./_shared-requirements.md) 使用。技术栈、设计规范、性能要求、页面结构等通用约束请直接引用共享文件，本文件仅定义本工具特有内容。

---

## 项目概述

FakeAPI 是一个面向开发者的 REST API 服务，用于生成假测试数据。开发者只需调用 HTTP 端点即可获取用户、文章、评论、产品、地址等结构的模拟数据。支持自定义字段、分页、延迟模拟和多种响应格式。

核心价值：**不用手动造数据，不用复制粘贴 JSON，一个 URL 就拿到结构化假数据。**

## 目标用户

- 前端开发者（需要 mock 数据进行 UI 开发）
- 后端开发者（需要测试 API 集成）
- 全栈开发者（在前后端分离开发中需要独立数据源）
- 学生/教学场景（学习 API 调用）

## 定价

| 套餐 | 价格 | 额度 |
|------|------|------|
| Free | $0 | 1000 次请求/天 |
| Pro | $9/月 | 5 万次/月 + 自定义字段 + XML 格式 |
| Enterprise | $29/月 | 50 万次/月 + 全部功能 + 自定义端点 + 专属支持 |

付费方式：Stripe / Lemon Squeezy 月付订阅。API 密钥验证。

## 核心功能与 UI 流程

### 首页 Landing

结构遵循共享文件中的价值主张布局：

1. **Hero 区**：标题「Fake Data API for Developers」+ 副标题「Generate realistic test data with a single HTTP request. Users, posts, comments, products — just pick your endpoint.」+ CTA 按钮「Try Free →」
2. **痛点场景**：3 张卡片展示使用案例
   - 案例 1：前端开发一个用户列表页面，没有真实接口 → 调 `/api/users` 拿 20 条假用户数据
   - 案例 2：测试分页组件，需要造 100 条文章数据 → 加 `?_limit=100&_page=2` 参数
   - 案例 3：需要特定字段结构的假数据 → Pro 套餐自定义字段
3. **定价卡片**：Free vs Pro vs Enterprise 对比
4. **FAQ**：6-8 个常见问题（数据是随机的吗？支持哪些响应格式？请求次数怎么计算？可以自定义字段吗？延迟模拟有什么用？是否需要注册？API 密钥在哪里获取？如何取消订阅？）
5. **Footer**：隐私政策 + 联系

### API 文档页面（/docs）

交互式 API 文档，分为几个区域：

**顶部导航：** 端点列表 + API 密钥输入框（认证状态）

**端点区域（每个端点一个卡片）：**
- `GET /api/users` — 生成假用户数据
- `GET /api/posts` — 生成假文章数据
- `GET /api/comments` — 生成假评论数据
- `GET /api/products` — 生成假产品数据
- `GET /api/addresses` — 生成假地址数据
- `GET /api/custom` — 自定义字段（Pro+）

**每个端点卡片包含：**
- 请求示例 URL
- 响应 JSON 示例（可折叠）
- 参数表格（_limit / _page / _delay / _format 等）
- 在线试用按钮（发请求看实时响应）

**右侧工具栏：**
- 响应格式切换：JSON / XML（Pro+）
- 延迟模拟滑块：0ms / 200ms / 500ms / 1000ms / 2000ms
- 结果数量滑块：1-100
- 语言选择：en / zh / ja / es（返回对应语言的假数据）

**底部代码示例区：**
- 多 Tab 展示不同语言的调用示例
- JavaScript（fetch）
- Python（requests）
- curl
- PHP
- Go

## 所有按钮与交互路径

| 按钮/交互 | 位置 | 交互路径 |
|-----------|------|---------|
| Try Free | Hero CTA | 跳转 /docs（自动分配免费 API Key） |
| 端点卡片 | /docs | 点击展开 → 显示详细参数和示例 |
| 在线试用 | 端点卡片内 | 点击 → fetch 调用该端点 → 显示响应面板 |
| 响应格式切换 | 右侧工具栏 | 下拉选择 JSON/XML（Pro+）→ 试用时使用该格式 |
| 延迟模拟 | 右侧工具栏 | 拖动滑块 → 试用时服务端延迟响应 |
| 结果数量 | 右侧工具栏 | 拖动滑块 1-100 → 试用时返回对应数量 |
| 语言选择 | 右侧工具栏 | 下拉选择 → 试用时返回对应语言的假数据 |
| 复制代码 | 代码示例区 | 点击复制按钮 → 复制代码到剪贴板 |
| 复制 URL | 端点卡片 | 点击复制 → 复制 API URL 到剪贴板 |
| API Key 管理 | 顶部导航 | 显示/隐藏 API Key → 点击 regenerate 生成新 Key |
| Subscribe / Upgrade | 定价卡片 | 点击 → Stripe Checkout → 订阅成功 → 解锁额度 |

## 定价页面

/pricing 页面独立展示：

- **Free**：$0/月，1000 次/天，6 个端点，JSON 格式
- **Pro**：$9/月，5 万次/月，自定义字段，XML 格式，延迟模拟，语言选择
- **Enterprise**：$29/月，50 万次/月，自定义端点，专属支持，优先路由
- 对比表格：请求额度、端点数量、响应格式、自定义字段、延迟模拟、语言支持、自定义端点、专属支持

## SEO 关键词

- fake API for development
- mock data API
- REST API fake data generator
- test data API free
- JSON placeholder alternative
- fake user API
- mock API for frontend development
- generate fake data REST

## 性能要求

除共享文件中的通用性能要求外：

- API 响应时间 < 100ms（无延迟模拟时）
- 支持 1000+ 并发请求
- 单次请求最多返回 100 条记录
- 99.9% 可用性（基于 Node.js + SQLite）
- 请求计数使用内存缓存 + 定期持久化，避免频繁写库
- 响应体 < 50KB（100 条记录以内）
- 限流：免费 1000 次/天，超限返回 429 + Retry-After header

## 部署方式

```json
{
  "name": "fakeapi",
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

部署平台：Vercel / Railway / Fly.io

后端职责：所有 API 端点的假数据生成 + 请求计数 + Stripe 订阅管理。假数据生成使用内置的随机数据池（名字、地址、产品名等硬编码数据池），不依赖外部 Faker 库以减少依赖体积。API 密钥认证通过请求头 `X-API-Key` 传递。
