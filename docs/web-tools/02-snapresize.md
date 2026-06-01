# SnapResize — 社交媒体图片尺寸调整

## 参考通用要求

> 配合 [_shared-requirements.md](./_shared-requirements.md) 使用。技术栈、设计规范、性能要求、页面结构等通用约束请直接引用共享文件，本文件仅定义本工具特有内容。

---

## 项目概述

SnapResize 是一个专注社交媒体图片尺寸调整的在线工具。用户上传一张图片，选择目标社交平台，一键裁剪/调整到该平台的标准尺寸，然后下载。内置 20+ 主流社交平台的图片尺寸预设，支持自定义尺寸和批量处理。

核心价值：**不用记住每个平台的图片尺寸，不用手动裁剪，上传 + 选择 + 下载三步完成。**

## 目标用户

- 社交媒体运营人员
- 自媒体创作者（YouTuber、TikToker、Instagrammer）
- 营销 agency 员工
- 需要频繁发布多平台内容的内容创作者

## 定价

| 套餐 | 价格 | 额度 |
|------|------|------|
| Free | $0 | 每月 5 张图片 |
| Pro | $4/月 | 每月 50 张 + 批量处理 + 质量选择 |
| Unlimited | $9/月 | 无限张 + 全部功能 + 优先支持 |

付费方式：Stripe / Lemon Squeezy 月付订阅。

## 核心功能与 UI 流程

### 首页 Landing

结构遵循共享文件中的价值主张布局：

1. **Hero 区**：标题「Resize Images for Every Social Platform in One Click」+ 副标题「No more guessing dimensions. Upload once, export for all platforms.」+ CTA 按钮「Try Free →」
2. **痛点场景**：3 张卡片展示使用案例
   - 案例 1：运营人员要发 Twitter、LinkedIn、IG 三张不同尺寸的图片，每张手动裁剪 → SnapResize 一键生成三种尺寸
   - 案例 2：不知道 Twitter Header 尺寸是多少，每次要去查 → 内置预设，直接选平台
   - 案例 3：批量处理 20 张产品图，每张要调成 IG Square 和 IG Story 两种尺寸 → Pro 套餐批量处理
3. **定价卡片**：Free vs Pro vs Unlimited 对比
4. **FAQ**：6-8 个常见问题（支持哪些平台？图片会上传到服务器吗？支持批量处理吗？支持 RAW 格式吗？最大文件大小？裁剪模式有哪些？如何取消订阅？处理后的图片质量如何？）
5. **Footer**：隐私政策 + 联系

### 工具界面（/app）

上传 + 裁剪双区域布局：

**上传区：**
- 拖拽上传区域（Drag & Drop）
- 点击选择文件按钮
- 支持格式：JPG、PNG、WebP、GIF
- 文件大小限制显示

**裁剪/调整区：**
- 左侧：图片预览 + 裁剪框（可拖拽调整）
- 右侧：平台选择列表（分组展示）
  - Twitter（Post、Header、Profile）
  - Instagram（Square、Portrait、Landscape、Story、Reels）
  - LinkedIn（Banner、Post、Profile）
  - Facebook（Post、Cover、Profile）
  - TikTok（Video、Profile）
  - Pinterest（Pin）
  - YouTube（Thumbnail、Banner）
  - 自定义尺寸输入（宽 × 高）
- 裁剪模式选择：Cover / Contain / Stretch
- 质量选择：低 / 中 / 高 / 原图

**下载区：**
- 当前尺寸预览缩略图
- 下载按钮（单张）
- 批量下载 ZIP（Pro+）

## 所有按钮与交互路径

| 按钮 | 位置 | 交互路径 |
|------|------|---------|
| Try Free | Hero CTA | 滚动到定价卡片 or 跳转 /app |
| 选择文件 | 上传区 | 点击 → 系统文件选择器 → 加载图片 |
| 拖拽上传 | 上传区 | 拖入文件 → 验证格式和大小 → 加载图片 |
| 平台选择 | 右侧列表 | 点击某个平台尺寸 → 自动裁剪框适配该尺寸比例 |
| 自定义尺寸 | 右侧底部 | 输入宽高 → 裁剪框按比例调整 |
| 裁剪模式切换 | 右侧模式区 | Cover / Contain / Stretch 单选切换 |
| 质量选择 | 右侧质量区 | 下拉选择低/中/高/原图 |
| 重置裁剪 | 图片上方 | 点击 → 恢复原始裁剪框 |
| 旋转 | 图片上方 | 点击 → 图片顺时针旋转 90° |
| 下载 | 下载区 | 点击 → canvas 导出图片 → 浏览器下载 |
| 批量下载 | 下载区 | 点击 → 生成 ZIP（付费检测）→ 浏览器下载 ZIP |
| 添加更多 | 下载区旁 | 点击 → 返回上传区继续添加图片（Pro+） |
| Subscribe / Upgrade | 定价卡片/功能锁 | 点击 → Stripe Checkout → 订阅成功 → 解锁 |

**键盘快捷键：**
- `Ctrl+O` / `Cmd+O`：打开文件
- `R`：旋转图片
- `Ctrl+S` / `Cmd+S`：下载当前图片

## 定价页面

/pricing 页面独立展示：

- **Free**：$0/月，5 张/月，20+ 预设尺寸，基本裁剪
- **Pro**：$4/月，50 张/月，批量处理，质量选择，自定义尺寸
- **Unlimited**：$9/月，无限张，全部功能，优先支持
- 对比表格：预设尺寸 ✓、自定义尺寸、批量处理、质量选择、文件格式、无水印

## SEO 关键词

- image resizer for social media
- social media image size converter
- resize image for instagram
- twitter image size tool
- linkedin banner size converter
- free image resizer online
- batch image resizer

## 性能要求

除共享文件中的通用性能要求外：

- 图片加载时间 < 1s（前端 Canvas 加载，不上传服务器）
- 裁剪/缩放操作 < 50ms 响应
- 导出时间 < 2s（2048px 以内图片）
- 最大支持 20MB 图片文件
- 批量处理 10 张图片导出 ZIP < 5s
- 所有处理在浏览器端完成，零服务器负载

## 部署方式

```json
{
  "name": "snapresize",
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

后端职责仅限：Stripe 订阅管理 + 用户额度追踪，图片处理全部在客户端通过 Canvas API 完成。批量下载 ZIP 可通过 JSZip 在浏览器端生成，无需后端参与。
