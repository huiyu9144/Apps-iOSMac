# InvoiceFlow — 极简发票生成器

## 参考通用要求

> 配合 [_shared-requirements.md](./_shared-requirements.md) 使用。技术栈、设计规范、性能要求、页面结构等通用约束请直接引用共享文件，本文件仅定义本工具特有内容。

---

## 项目概述

InvoiceFlow 是一个面向自由职业者和 Freelancer 的极简在线发票生成器。用户在线填写发票信息，点击即可生成专业 PDF 发票，支持下载或通过邮件发送。所有 PDF 生成由 jsPDF 在浏览器端完成，不上传任何数据到服务器。

核心价值：**比 Word/Excel 快 10 倍，比 Wave 简单 10 倍，3 分钟完成一张专业发票。**

## 目标用户

- 自由职业者（设计师、开发者、写手、咨询师）
- 小型 Freelancer 团队
- 兼职副业人员
- 需要快速开票的非财务人员

## 定价

| 套餐 | 价格 | 额度 |
|------|------|------|
| Free | $0 | 每月 3 张发票 |
| Unlimited | $5/月 | 无限发票 + 客户管理 + 多币种 + 邮件发送 |

付费方式：Stripe / Lemon Squeezy 月付订阅。

## 核心功能与 UI 流程

### 首页 Landing

结构遵循共享文件中的价值主张布局：

1. **Hero 区**：标题「Professional Invoices in 3 Minutes」+ 副标题「No Excel. No Wave. Just fill and download.」+ CTA 按钮「Start Free →」
2. **痛点场景**：3 张卡片展示使用案例
   - 案例 1：Freelancer 每次开票要打开 Word 调整格式 → InvoiceFlow 在线填写即生成
   - 案例 2：用 Wave 功能太多找不到入口 → InvoiceFlow 只有一个页面
   - 案例 3：客户要 PDF 格式，每次手动导出 → 自动生成，一键下载
3. **定价卡片**：Free vs Unlimited 对比
4. **FAQ**：6-8 个常见问题（如何保存公司信息？支持多币种吗？数据安全吗？能否用我的 Logo？支持哪些货币？如何取消订阅？）
5. **Footer**：隐私政策 + 联系

### 工具界面（/app）

单页面发票编辑器，分为三个区域：

**左侧 — 表单区：**
- 发件人信息（公司名称、地址、邮箱、电话）
- 收件人信息（客户名称、客户地址、客户邮箱）
- 发票信息（发票号码、发票日期、到期日、币种选择）
- 行项目表格（描述、数量、单价、税率、金额）
- 备注/附加说明

**右侧 — 预览区：**
- 实时 PDF 预览（使用 jsPDF + canvas 渲染缩略图）
- 每次表单变化自动刷新预览

**底部操作栏：**
- 下载 PDF
- 发送邮件（通过 mailto: 链接或后端 SMTP）
- 保存为草稿（localStorage）
- 清空表单

## 所有按钮与交互路径

| 按钮 | 位置 | 交互路径 |
|------|------|---------|
| Start Free | Hero CTA | 滚动到定价卡片 or 跳转 /app |
| 下载 PDF | 底部操作栏 | 点击 → jsPDF 生成 PDF → 浏览器下载 |
| 发送邮件 | 底部操作栏 | 点击 → 弹窗输入收件人邮箱 → 后端发送（付费用户） |
| 保存草稿 | 底部操作栏 | 点击 → 保存到 localStorage → Toast 提示 |
| 清空表单 | 底部操作栏 | 点击 → 确认弹窗 → 清空所有字段 |
| 添加行项目 | 行项目表格底部 | 点击 → 新增一行（描述/数量/单价/税率） |
| 删除行项目 | 行项目行尾 | 点击删除按钮 → 移除该行 |
| 选择客户 | 收件人区域 | 下拉选择已保存客户（付费）/ 手动输入 |
| 切换币种 | 发票信息区 | 下拉选择 CNY/USD/EUR/GBP/JPY 等 |
| Upgrade / Subscribe | 定价卡片 | 点击 → Stripe Checkout → 订阅成功 → 解锁无限 |
| 保存公司信息 | 发件人区域 | 点击 → 存入 localStorage → 下次自动填充 |

## 定价页面

/pricing 页面独立展示：

- **Free**：$0/月，3 张发票，基础模板，PDF 下载
- **Unlimited**：$5/月，无限发票，客户管理，多币种支持，邮件发送，自定义 Logo，高级模板
- 对比表格清晰列出每个功能的可用性
- CTA：「Get Started Free」/「Subscribe Now」

## SEO 关键词

- free invoice generator
- invoice generator for freelancers
- create invoice online free
- pdf invoice creator
- invoice maker no signup
- freelance invoice template
- invoice generator no upload

## 性能要求

除共享文件中的通用性能要求外：

- PDF 生成时间 < 2 秒（50 行项目以内）
- 预览更新 < 200ms（debounce 表单输入）
- localStorage 保存 < 10ms
- 页面体积 < 100KB（不含 PDF 预览缩略图）
- 纯前端 PDF 生成，零服务器负载

## 部署方式

```json
{
  "name": "invoiceflow",
  "scripts": {
    "start": "node server.js",
    "dev": "node --watch server.js"
  },
  "dependencies": {
    "express": "^4.18",
    "better-sqlite3": "^11.0",
    "stripe": "^15.0",
    "nodemailer": "^6.9"
  }
}
```

部署平台：Vercel / Railway / Fly.io

后端职责仅限：Stripe 订阅管理 + 邮件发送（可选），PDF 生成全部在客户端完成。
