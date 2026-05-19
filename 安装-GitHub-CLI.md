
# 安装 GitHub CLI (gh) 指南

由于网络连接问题，请按以下步骤手动安装 GitHub CLI：

## 方法 1：直接下载安装（推荐）

1. 访问 GitHub CLI 发布页面：
   https://github.com/cli/cli/releases/latest

2. 下载 Windows 安装包：
   - 文件名：`GitHubCLI.msi`
   - 或：`gh_*_windows_amd64.msi`

3. 双击运行下载的 `.msi` 安装程序

4. 按照安装向导完成安装

5. **重要！** 安装完成后，**关闭并重新打开**所有终端窗口

## 方法 2：使用包管理器（如果已安装）

### 如果有 Chocolatey：
```powershell
choco install gh
```

### 如果有 Scoop：
```powershell
scoop install gh
```

### 如果有 winget (Windows 10/11 自带)：
```powershell
winget install --id GitHub.cli
```

## 验证安装

重新打开终端后，运行：

```powershell
gh --version
```

如果看到版本信息，说明安装成功！

## 登录 GitHub

安装完成后，运行以下命令登录：

```powershell
gh auth login
```

按照提示选择：
- 账户类型：`GitHub.com`
- 认证方式：`Login with a web browser` 或 `Paste an authentication token`

## 更多信息

- GitHub CLI 官方文档：https://cli.github.com/
- GitHub 个人访问令牌：https://github.com/settings/tokens
