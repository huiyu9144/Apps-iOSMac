# Apple App Store Review 修复计划：Support URL 全局整改

## 现状分析

### 审核拒绝原因
Apple 审核拒绝了 FormatQuick，理由是：
- **Support URL**（设为 `https://huiyu9144.github.io/Apps-iOSMac/format-quick/about.html`）指向的页面没有提供用户**提问和请求支持**的功能
- `about.html` 只是一份产品功能说明书，不是支持/联系页面
- Apple 要求 Support URL 必须是一个**可以获取技术支持和联系开发者的功能性网页**

### 全局发现的 5 个问题

| # | 问题 | 严重程度 | 范围 |
|---|------|---------|------|
| 1 | **Support URL 配置错误** — 所有 About 页面均不含联系方式和支持入口 | 🔴 当前拒审原因 | 全部 13 个产品 |
| 2 | **GitHub Pages 无法访问** — 仓库为 private 状态，Pages 未生效 | 🔴 影响所有 URL | 全局 |
| 3 | **PrivacyInfo.xcprivacy 缺失** — 仅 PicShrink 有隐私清单文件 | 🟡 潜在拒审风险 | 12 个产品 |
| 4 | **FormatQuick 缺少网络权限** — Entitlements 中无 `network.client` | 🟡 无法在应用内打开支持链接 | FormatQuick 及类似产品 |
| 5 | **应用内无支持入口** — 无菜单项或按钮跳转到支持页面 | 🟢 用户体验改进 | 全部 10 个 macOS 应用 |

---

## 整改方案

### 第一步：创建每个产品的独立支持页面

为每个产品创建 `docs/{product}/support.html`，包含：
- 产品名称和支持标题
- **联系邮箱**（醒目位置）
- **GitHub Issues 链接**（用于提交 bug/建议）
- **FAQ**（针对该产品的常见问题）
- 版本信息和系统要求

每个 About 页面增加「Support」链接指向 support.html。

### 第二步：About 页面增加支持入口

在每个产品的 `about.html` 底部链接区添加：
```html
<a href="support.html">Support</a>
```

### 第三步：修复 GitHub Pages 可访问性

将仓库改为 Public，确保 GitHub Pages 可以正常对外提供服务。

### 第四步：补充 PrivacyInfo.xcprivacy

为 **CleanShot、ClipFlow、FindDup、FormatQuick、HueSnap、MenuTimer、QuickOCR、NetMeter、MenuMeter、JiaRemoteMac** 添加隐私清单文件，声明其使用的 API 类型和原因。

### 第五步：修复 FormatQuick Entitlements

在 FormatQuick.entitlements 中添加 `com.apple.security.network.client` 权限，使应用内可以打开外部 URL。

### 第六步：应用内添加支持入口（可选增强）

在菜单栏应用（CleanShot、ClipFlow、FormatQuick 等）的 Settings/About 页面或菜单中添加「Contact Support」按钮，调用 `NSWorkspace.shared.open(supportURL)` 打开支持页面。

---

## 涉及的文件清单

### 新增文件（13 个 support 页面）
```
docs/clean-shot/support.html
docs/paste-lite/support.html
docs/find-dup/support.html
docs/dash-timer/support.html
docs/quick-ocr/support.html
docs/menu-meter/support.html
docs/format-quick/support.html
docs/hue-snap/support.html
docs/net-meter/support.html
docs/pic-shrink/support.html
docs/jia-remote-mac/support.html
docs/jia-remote-win/support.html
docs/net-bar/support.html
```

### 修改文件（13 个 about 页面 + index.html + support.html）
```
docs/clean-shot/about.html          ← 增加 Support 链接
docs/paste-lite/about.html          ← 增加 Support 链接
...（同上，所有约 13 个 about.html）
docs/index.html                     ← 增加各产品的 Support 链接
docs/support.html                   ← 增强为统一支持中心
```

### 新增文件（12 个 PrivacyInfo.xcprivacy）
```
CleanShot/CleanShot/PrivacyInfo.xcprivacy
ClipFlow/ClipFlow/PrivacyInfo.xcprivacy
FindDup/FindDup/PrivacyInfo.xcprivacy
FormatQuick/FormatQuick/PrivacyInfo.xcprivacy  ← 已有 entitlements 但无隐私清单
HueSnap/HueSnap/PrivacyInfo.xcprivacy
MenuTimer/MenuTimer/PrivacyInfo.xcprivacy
QuickOCR/QuickOCR/PrivacyInfo.xcprivacy
NetMeter/Sources/NetMeter/PrivacyInfo.xcprivacy
menu meter/MenuMeter/Resources/PrivacyInfo.xcprivacy
JiaRemoteMac/Resources/PrivacyInfo.xcprivacy
```

### 修改文件（entitlements）
```
FormatQuick/FormatQuick.entitlements  ← 追加 network.client
```

---

## 支持的邮箱地址

默认使用现有的 `support@apps-iosmac.com`。如需修改再更新。

## 验证步骤

1. 所有 support 页面可以正常在浏览器打开
2. 所有 about 页面底部显示正确的 Support 链接
3. GitHub Pages 可以访问：`https://huiyu9144.github.io/Apps-iOSMac/`
4. 每个 Support URL 包含邮箱和 GitHub Issues 两种联系途径
5. 所有 PrivacyInfo.xcprivacy 配置正确
6. 仓库改为 Public 后验证外网访问

---

## App Store Connect 操作（需用户手动完成）

1. 将仓库设为 Public
2. 每个产品提交 App Store Connect 时，Support URL 填写：
   `https://huiyu9144.github.io/Apps-iOSMac/{product-folder}/support.html`
3. 例如 FormatQuick 的 Support URL 改为：
   `https://huiyu9144.github.io/Apps-iOSMac/format-quick/support.html`
4. 重新提交审核
