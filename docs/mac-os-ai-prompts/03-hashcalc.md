# HashCalc — 文件哈希校验

## 参考通用要求

> 本提示词需要配合 `_shared-requirements.md` 一起使用。所有通用的架构、多语言、性能、关闭/退出机制、设计规范等要求均已在该文件中定义，此处不再赘述。

---

## 项目概述

macOS 菜单栏极简哈希校验工具。拖拽文件 → 自动计算 MD5/SHA-1/SHA-256 → 粘贴期望值对比。开发者必备。

- **定价**：$1.99 买断
- **目标用户**：开发者、系统管理员、安全敏感用户
- **SF Symbol**：`"checkmark.shield"`

## 核心功能与 UI 流程

### 主面板（点击菜单栏图标）

```
┌─────────────────────────────────────┐
│  HashCalc                            │ ⚙️
│  ─────────────────────────────────  │
│  📂 拖拽文件到此处                    │
│  ─────────────────────────────────  │
│  文件: macOS14.0_Install.pkg         │
│  大小: 12.8 GB                       │
│  ─────────────────────────────────  │
│  算法: [MD5 ▼] [SHA-1 ▼] [SHA-256]  │
│  ─────────────────────────────────  │
│  计算结果:                           │
│  e3b0c44298fc1c149afbf4c8996fb924   │
│  ─────────────────────────────────  │
│  期望值:                             │
│  [________________________]          │
│  匹配: ✅ 哈希一致                    │
│  ─────────────────────────────────  │
│  [📋 复制]                          │
│  ─────────────────────────────────  │
│  退出应用                            │
└─────────────────────────────────────┘
```

### 所有按钮与交互路径

| 元素 | 位置 | 点击行为 |
|------|------|---------|
| 拖拽区域 | 顶部 | 接受文件拖拽（`onDrop`），支持多文件 |
| 算法选择 | 中部 | 多选 Tag 按钮（MD5/SHA-1/SHA-256/SHA-512），至少选一个 |
| 计算结果 | 中部 | 实时显示，长文本自动换行，等宽字体 |
| 期望值输入框 | 下方 | 粘贴期望哈希值，自动去除空格和换行 |
| 匹配状态 | 期望值下方 | 自动对比：绿色 ✅ 或红色 ❌ |
| 📋 复制 | 底部 | 复制当前计算结果到剪贴板 |
| ⚙️ 齿轮 | 右上 | 设置窗口 |
| 退出应用 | 底部 | `NSApplication.shared.terminate(nil)` |

### 拖拽 Finder 扩展（额外功能）

- 在 Finder 中右键文件 → 快速菜单显示「HashCalc - 查看哈希」
- 使用 `FinderSync` 扩展或 `Services` 菜单
- 直接在小弹窗中显示结果，无需打开主面板

### 性能要求

- 小于 100MB 的文件同步计算，即时显示
- 大于 100MB 的文件使用后台 `DispatchIO` 流式读取，显示进度
- 使用系统原生 `CommonCrypto` 框架（`CC_MD5`、`CC_SHA1`、`CC_SHA256`）
- 大文件计算时面板显示进度条 + 耗时，不阻塞 UI
- 多算法同时计算时使用 `TaskGroup` 并发

```swift
import CommonCrypto

func hashFile(url: URL, algorithm: HashAlgorithm) async throws -> String {
    let fileHandle = try FileHandle(forReadingFrom: url)
    defer { try? fileHandle.close() }

    var ctx: HashContext
    switch algorithm {
    case .md5: ctx = HashContext(CC_MD5_CTX.self)
    case .sha256: ctx = HashContext(CC_SHA256_CTX.self)
    }

    while try autoreleasepool({
        let data = fileHandle.readData(ofLength: 1024 * 1024)
        guard !data.isEmpty else { return false }
        data.withUnsafeBytes { buffer in
            ctx.update(buffer, count: buffer.count)
        }
        return true
    }) {}
    return ctx.finalize().map { String(format: "%02x", $0) }.joined()
}
```
