# WebhookInspect — Webhook 调试接收器

## 参考通用要求

> 配合 [_shared-requirements.md](file:///c:/Users/Administrator/Desktop/111111/jia-ios/docs/web-tools/_shared-requirements.md) 使用。技术栈、设计规范、部署配置等通用要求不再重复。

---

## 项目概述

WebhookInspect 是一个 Webhook 调试接收器，为后端开发者和 SaaS 集成开发者提供一个唯一的 Webhook URL，收到的请求实时推送到浏览器面板，支持查看请求头、请求体、时间戳等详细信息。同时支持请求重放和自定义响应。免费版每月 100 条，$5/月升级到 1000 条 + 自定义响应。

## 目标用户

- 后端开发者 —— 调试第三方服务发送的 Webhook
- SaaS 集成开发者 —— 开发与 Stripe/GitHub/Slack 等服务的集成
- API 开发者 —— 测试自己服务的 Webhook 发送
- DevOps 工程师 —— 监控和调试 Webhook 投递

## 定价

| 版本 | 价格 | 功能 |
|------|------|------|
| Free | $0 | 1 个接收端点、每月 100 条请求、24 小时保留、基础请求查看 |
| Pro | $5/月 | 3 个接收端点、每月 1000 条请求、7 天保留、自定义响应状态码/体、重放请求、导出 JSON |

买断制不适用（持续使用工具，采用订阅模式）。

## 核心功能与 UI 流程

### 首页 Landing

```
/ → Landing Page
├── Hero: "Webhook 调试，两秒搞定" + CTA "创建你的接收 URL"
├── 痛点场景:
│   ├── "自己搭服务器太麻烦" → "WebhookInspect 一键生成 URL"
│   ├── "RequestBin 经常超时" → "WebhookInspect 实时 SSE 推送，不离线"
│   └── "看不到请求细节" → 展示面板截图（Headers/Body/Timestamp）
├── 实时演示: 页面上嵌入一个示例接收面板，展示实时请求流
├── 定价卡片: Free vs Pro 对比
├── FAQ: 6-8 个常见问题
└── Footer
```

### 工具界面

**接收面板 `/inspect/:id`**（核心界面）：
```
/inspect/xxxx → 实时接收面板
├── 顶部工具栏:
│   ├── Webhook URL 显示 + 一键复制按钮
│   ├── 端点状态指示灯（绿色等待中 / 黄色接收中）
│   └── 清空历史按钮
├── 请求列表（左侧/上方，按时间倒序）:
│   ├── 请求序号
│   ├── HTTP 方法（POST/GET/PUT 等，带颜色标签）
│   ├── 来源 IP
│   ├── 时间戳（相对时间，如 "2 秒前"）
│   └── 状态指示（新请求高亮闪烁）
├── 请求详情（右侧/下方，点击某个请求后展开）:
│   ├── 标签页: Headers / Body / 时间线
│   ├── Headers: 键值对表格展示
│   ├── Body: 自动格式化 JSON / 原始文本 / 表单数据
│   └── 时间线: 接收时间、处理耗时
├── 操作按钮:
│   ├── 重放此请求（发送相同请求到指定 URL，Pro 功能）
│   ├── 复制为 cURL
│   ├── 下载请求 JSON
│   └── 设置为默认响应（Pro 功能）
└── 设置按钮（Pro 功能）:
    ├── 自定义响应状态码（200/201/400/500 等）
    ├── 自定义响应 Headers
    └── 自定义响应 Body（JSON 编辑）
```

**后端架构**：
```
WebhookInspect 后端工作流
┌─────────────┐     POST /hook/xxxx     ┌──────────────┐
│  第三方服务  │ ──────────────────────→ │  接收端点    │
│ (Stripe/     │                         │ (express)    │
│  GitHub/     │                         └──────┬───────┘
│  Slack)      │                                │
└─────────────┘                                 │ 存储到 SQLite
                                                ▼
                                        ┌──────────────┐
                                        │   SSE 推送    │
                                        │  → 浏览器面板 │
                                        └──────────────┘
```

## 所有按钮与交互路径

| 按钮/交互 | 位置 | 触发动作 |
|-----------|------|---------|
| 「创建接收 URL」 | 首页 Hero | 生成唯一 ID，跳转 `/inspect/:id` |
| 「复制 URL」 | 接收面板顶部 | 复制当前 Endpoint URL 到剪贴板 |
| 「清空历史」 | 接收面板顶部 | 确认后清空所有请求记录 |
| 「点击请求条目」 | 请求列表 | 展开该请求的详细内容 |
| 「Headers 标签」 | 请求详情 | 显示请求头键值对 |
| 「Body 标签」 | 请求详情 | 显示请求体（格式化 JSON/原始/表单） |
| 「时间线标签」 | 请求详情 | 显示接收时间轴 |
| 「重放」 | 请求详情操作区 | 弹窗输入目标 URL，发送相同请求（Pro） |
| 「复制为 cURL」 | 请求详情操作区 | 生成 cURL 命令并复制 |
| 「下载 JSON」 | 请求详情操作区 | 下载当前请求的 JSON 文件 |
| 「设为默认响应」 | 请求详情操作区 | 将此请求的响应设为端点的默认响应（Pro） |
| 「响应设置」 | 接收面板设置 | 打开自定义响应编辑弹窗（Pro） |
| 「保存响应设置」 | 设置弹窗 | 保存自定义响应配置 |
| 「升级到 Pro」 | 首页/面板 | 跳转 Stripe 结账 |
| 「创建新端点」 | 接收面板 | 生成新的 Webhook URL（Pro 最多 3 个） |

## SEO 关键词

- webhook debugger
- webhook inspector
- webhook testing tool
- webhook receiver
- request bin alternative
- test webhooks online
- webhook endpoint tester
- debug webhook requests
- webhook viewer
- free webhook tester

## 性能要求

- 接收端点必须快速响应（< 500ms），返回 200 避免第三方服务重试
- SSE 推送延迟 < 200ms，请求到达 → 浏览器显示
- 请求列表虚拟滚动（超过 100 条时），不卡顿
- 大请求体（> 1MB）自动截断显示，只存储前 256KB
- 定期清理过期请求（Free 24h / Pro 7d），通过 cron 或定时任务实现
- SQLite WAL 模式启用，提高并发写入性能
