# SigCraft — 邮箱签名生成器

## 参考通用要求

> 配合 [_shared-requirements.md](./_shared-requirements.md) 使用。技术栈、设计规范、性能要求、页面结构等通用约束请直接引用共享文件，本文件仅定义本工具特有内容。

---

## 项目概述

SigCraft 是一个在线邮箱签名生成器。用户通过表单填写姓名、职位、电话、社交媒体链接等信息，上传公司 Logo，实时预览签名效果，最后生成可直接复制到 Gmail / Apple Mail / Outlook 中的 HTML 签名代码。

核心价值：**不用手写 HTML 表格代码，5 分钟生成专业邮箱签名。**

## 目标用户

- 职场人士（需要给企业邮箱配置签名）
- 企业员工（公司统一签名格式要求）
- HR / 行政人员（为团队批量生成签名）
- 创业者（需要给公司邮箱做品牌展示）

## 定价

| 套餐 | 价格 | 额度 |
|------|------|------|
| Free | $0 | 1 个签名，基础模板 |
| Pro | $3.99 | **买断制**，无限签名，全部模板，Logo 上传，法律声明，多客户端适配 |

付费方式：Stripe / Lemon Squeezy 一次性支付买断。通过 localStorage 或邮箱存储许可证。

## 核心功能与 UI 流程

### 首页 Landing

结构遵循共享文件中的价值主张布局：

1. **Hero 区**：标题「Create a Professional Email Signature in 5 Minutes」+ 副标题「No HTML skills needed. Fill the form, preview live, copy the code.」+ CTA 按钮「Start Free →」
2. **痛点场景**：3 张卡片展示使用案例
   - 案例 1：公司要求邮箱签名包含 Logo 和社交媒体链接，HR 不会写 HTML → SigCraft 表单填写自动生成
   - 案例 2：换了工作要在 Apple Mail 和 Gmail 上配置签名 → 一键复制代码，粘贴到对应客户端
   - 案例 3：团队 20 人需要统一签名格式 → Pro 模板保存，分享给团队成员
3. **定价卡片**：Free vs Pro 买断对比
4. **FAQ**：6-8 个常见问题（支持哪些邮箱客户端？签名可以在 Outlook 中使用吗？能上传自己的 Logo 吗？支持多少种模板？法律声明可以自定义吗？买断后能生成多少个签名？生成的代码可以二次修改吗？如何在 Gmail 中粘贴 HTML 签名？）
5. **Footer**：隐私政策 + 联系

### 工具界面（/app）

左右分栏布局，左侧表单 + 右侧实时预览：

**左侧 — 表单区（分组排列）：**

*个人信息组：*
- 姓名（必填）
- 职位/头衔
- 公司名称
- 邮箱地址（必填）
- 电话号码
- 手机号码
- 个人头像（Pro，上传圆形裁剪）

*品牌信息组：*
- 公司 Logo 上传（Pro，控制最大高度）
- 品牌色选择（颜色选择器）
- 签名分隔线样式（实线/虚线/无）

*社交链接组：*
- LinkedIn URL
- Twitter/X URL
- GitHub URL
- 个人网站 URL
- Instagram URL
- YouTube URL
- 可自定义添加更多链接

*法律声明组（Pro）：*
- 保密声明文本
- 法律免责声明
- 公司注册号
- 增值税号

*配置组：*
- 模板选择（3 种 Free / 8 种 Pro）
- 字体大小（小/中/大）
- 布局样式（左对齐/居中）
- 客户端预设（Gmail / Apple Mail / Outlook）

**右侧 — 预览区：**
- 实时渲染签名预览（iframe 隔离样式）
- 预览区域背景模拟邮箱客户端底色

**底部操作栏：**
- 生成/复制 HTML 代码
- 下载为 .html 文件
- 分享模板链接（Pro）

## 所有按钮与交互路径

| 按钮 | 位置 | 交互路径 |
|------|------|---------|
| Start Free | Hero CTA | 跳转 /app |
| 上传 Logo | 品牌信息组 | 点击 → 文件选择器 → 上传 → 预览更新（Pro） |
| 上传头像 | 个人信息组 | 点击 → 文件选择器 → 上传 → 裁剪 → 预览更新（Pro） |
| 选择模板 | 配置组 | 点击模板缩略图 → 预览实时切换样式 |
| 字体大小 | 配置组 | 下拉选择小/中/大 → 预览实时更新 |
| 布局样式 | 配置组 | 单选左对齐/居中 → 预览实时更新 |
| 客户端预设 | 配置组 | 下拉选择 Gmail/Apple Mail/Outlook → 代码格式适配该客户端 |
| 品牌色 | 品牌信息组 | 点击颜色选择器 → 选择颜色 → 签名配色更新 |
| 添加社交链接 | 社交链接组 | 点击 + 按钮 → 新增一行输入框 → 输入 URL |
| 删除社交链接 | 社交链接组 | 点击行尾 × 按钮 → 移除该链接 |
| 复制 HTML | 底部操作栏 | 点击 → 复制签名 HTML 到剪贴板 → Toast 提示 |
| 下载 .html | 底部操作栏 | 点击 → 生成 .html 文件 → 浏览器下载 |
| 分享模板 | 底部操作栏 | 点击 → 生成分享 URL（Pro）→ 复制链接 |
| 预览刷新 | 预览区 | 表单任何变化 → 自动 debounce 刷新预览 |
| Subscribe / Buy Pro | 定价卡片/功能锁 | 点击 → Stripe Checkout → 支付成功 → 解锁 |

**快捷键：**
- `Ctrl+C` / `Cmd+C`：复制 HTML（聚焦在预览区时）
- `Ctrl+S` / `Cmd+S`：下载 .html 文件

## 定价页面

/pricing 页面独立展示：

- **Free**：$0，1 个签名，3 种模板，无 Logo，无法律声明，无分享
- **Pro**：$3.99 **一次买断**，无限签名，8 种模板，Logo 上传，法律声明，头像，社交链接，分享模板，多客户端适配
- 对比表格：签名数量、模板数量、Logo 上传、头像、社交链接、法律声明、品牌色自定义、分享模板、客户端预设、无水印
- 买断说明：$3.99 支付一次永久使用，通过 Stripe 支付

## SEO 关键词

- email signature generator
- free email signature template
- outlook email signature creator
- gmail signature generator
- apple mail signature maker
- professional email signature
- HTML email signature generator
- company email signature template

## 性能要求

除共享文件中的通用性能要求外：

- 表单输入响应 < 50ms
- 预览渲染 < 200ms（实时 debounce 更新）
- Logo/头像上传 < 1s（纯前端 FileReader，不上传服务器）
- 复制 HTML < 10ms
- 页面体积 < 80KB（不含用户上传的图片）
- iOS Safari / Android Chrome 完美支持
- 所有处理在浏览器端完成，零服务器负载

## 部署方式

```json
{
  "name": "sigcraft",
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

后端职责仅限：Stripe 支付处理 + 许可证验证（可选）。所有签名生成逻辑在浏览器端通过 DOM 操作完成，生成标准 HTML table 格式的邮箱签名代码。模板存储为预置的 HTML 片段，在客户端渲染。
