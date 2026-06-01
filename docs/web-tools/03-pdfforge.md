# PDFForge — PDF 合并/拆分/压缩

## 参考通用要求

> 配合 [_shared-requirements.md](./_shared-requirements.md) 使用。技术栈、设计规范、性能要求、页面结构等通用约束请直接引用共享文件，本文件仅定义本工具特有内容。

---

## 项目概述

PDFForge 是一个纯浏览器端的 PDF 处理工具，支持合并多个 PDF、拆分页面、压缩文件大小、页面旋转和提取图片。所有处理使用 PDF.js（Mozilla 开源项目）在浏览器端完成，不上传任何文件到服务器，充分保护用户隐私。

核心价值：**像 Adobe Acrobat 一样强大，但免费、无需安装、不上传服务器。**

## 目标用户

- 办公人员（需要合并/拆分 PDF 文档）
- 学生（需要合并课件、提取笔记页）
- 设计师/开发者（需要从 PDF 中提取素材图片）
- 任何不想安装 Adobe Acrobat 或担心上传 PDF 到不明网站隐私风险的人

## 定价

| 套餐 | 价格 | 额度 |
|------|------|------|
| Free | $0 | 处理 10 页以内 PDF |
| Pro | $4.99 | **买断制**，无限页数，全部功能 |

付费方式：Stripe / Lemon Squeezy 一次性支付买断。支付后通过邮箱或本地 localStorage 存储许可证。

## 核心功能与 UI 流程

### 首页 Landing

结构遵循共享文件中的价值主张布局：

1. **Hero 区**：标题「Merge, Split & Compress PDFs in Your Browser」+ 副标题「100% private. No upload. No installation. Powered by PDF.js.」+ CTA 按钮「Start Free →」
2. **痛点场景**：3 张卡片展示使用案例
   - 案例 1：需要合并 5 个 PDF 合同文件，不想花 $200 买 Adobe → PDFForge 拖拽上传即可合并
   - 案例 2：PDF 文件太大无法邮件发送 → 压缩功能删除空白页减小体积
   - 案例 3：需要提取 PDF 中的图片素材 → 一键提取所有嵌入图片
3. **定价卡片**：Free vs Pro 买断对比
4. **FAQ**：6-8 个常见问题（文件安全吗？支持多大文件？支持哪些浏览器？买断后永久使用吗？合并顺序怎么控制？页面旋转后能保存吗？提取的图片是什么格式？能否在手机端使用？）
5. **Footer**：隐私政策 + 联系

### 工具界面（/app）

单页应用，顶部功能区 + 底部页面预览区：

**顶部 — 功能区（Tab 切换）：**
- **合并（Merge）**：上传多个 PDF → 拖拽排序 → 点击合并
- **拆分（Split）**：上传 PDF → 选择分页范围 → 提取为单独 PDF
- **压缩（Compress）**：上传 PDF → 自动检测空白页 → 删除确认 → 导出
- **旋转（Rotate）**：上传 PDF → 选择需旋转的页面 → 点击旋转按钮
- **提取图片（Extract）**：上传 PDF → 扫描嵌入图片 → 预览 → 选择下载

**底部 — 页面预览区：**
- 当前 PDF 所有页面的缩略图列表
- 每页显示页码 + 选中状态
- 支持多选（Shift 连选 / Ctrl 点选）

## 所有按钮与交互路径

| 按钮 | 功能 Tab | 交互路径 |
|------|---------|---------|
| 上传 PDF | 全部 Tab | 拖拽上传 / 点击选择 → PDF.js 解析 → 页面预览 |
| 合并 | Merge | 点击 → PDF.js 合并页面 → 下载合并后 PDF |
| 拖动排序 | Merge | 拖拽缩略图调整顺序 → 位置互换 |
| 移除文件 | Merge | 点击缩略图 × 按钮 → 移除该 PDF |
| 拆分 | Split | 点击 → 弹窗选择页码范围 → 确认 → 下载拆分后 PDF |
| 压缩 | Compress | 点击 → 分析页面 → 标记空白页 → 确认删除 → 下载 |
| 旋转选中 | Rotate | 选择页面 → 点击旋转按钮（90°/180°/270°）→ 预览更新 |
| 提取图片 | Extract | 点击 → 扫描嵌入图片 → 图片缩略图列表 → 选择下载 |
| 全部选中 | 底部缩略图区 | 点击 → 选中所有页面 |
| 取消全选 | 底部缩略图区 | 点击 → 取消所有选中 |
| 下载 | 操作完成后 | 点击 → 浏览器下载处理后的 PDF/ZIP（图片） |

**快捷键：**
- `Ctrl+A` / `Cmd+A`：全选页面
- `Delete`：移除选中页面
- `Ctrl+Z` / `Cmd+Z`：撤销操作

## 定价页面

/pricing 页面独立展示：

- **Free**：$0，10 页以内，基础合并/拆分
- **Pro**：$4.99 **一次买断**，无限页数，全部功能（压缩、旋转、提取图片），无水印，先到先得的未来更新
- 对比表格：最大页数、合并 ✓、拆分 ✓、压缩、旋转、提取图片、批量导出、无水印
- 买断说明：支付后即可永久使用，通过 Stripe 支付，凭邮箱恢复许可证

## SEO 关键词

- merge PDF online free
- split PDF online
- compress PDF free
- PDF editor browser
- free PDF merger no upload
- extract images from PDF online
- PDF tool private secure
- rotate PDF pages free

## 性能要求

除共享文件中的通用性能要求外：

- PDF.js 加载 < 1s（使用 CDN）
- 100 页以内 PDF 合并 < 3s
- 拆分响应 < 1s
- 空白页检测 < 2s（50 页以内）
- 最大支持 200MB PDF 文件
- 页面缩略图加载 < 500ms（异步渲染）
- 所有处理在浏览器端完成，零服务器负载

## 部署方式

```json
{
  "name": "pdfforge",
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

后端职责仅限：Stripe 支付处理 + 许可证验证（可选），所有 PDF 处理通过 PDF.js + jsPDF 在客户端完成。核心逻辑在单个 HTML 文件中实现，后端只需提供静态文件服务和支付接口。
