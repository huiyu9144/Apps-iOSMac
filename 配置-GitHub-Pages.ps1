
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "配置 GitHub Pages 脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查是否已安装 GitHub CLI
$ghPath = "C:\Program Files\GitHub CLI\gh.exe"
if (-not (Test-Path $ghPath)) {
    Write-Host "❌ GitHub CLI 未安装" -ForegroundColor Red
    Write-Host "请先安装 GitHub CLI: https://github.com/cli/cli/releases/latest" -ForegroundColor Yellow
    Read-Host "按 Enter 键退出"
    exit 1
}

# 检查是否已登录
Write-Host "[1/4] 检查 GitHub CLI 登录状态..." -ForegroundColor Yellow
try {
    $ghStatus = & $ghPath auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ 未登录 GitHub" -ForegroundColor Red
        Write-Host ""
        Write-Host "请运行以下命令登录：" -ForegroundColor Yellow
        Write-Host "  gh auth login" -ForegroundColor White
        Write-Host ""
        Read-Host "按 Enter 键退出"
        exit 1
    }
    Write-Host "✅ GitHub CLI 已登录" -ForegroundColor Green
} catch {
    Write-Host "❌ 检查登录状态失败" -ForegroundColor Red
    Read-Host "按 Enter 键退出"
    exit 1
}

Write-Host ""

# 修改仓库可见性为公开
Write-Host "[2/4] 将仓库改为公开..." -ForegroundColor Yellow
try {
    & $ghPath repo edit huiyu9144/Apps-iOSMac --visibility public
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 仓库已改为公开" -ForegroundColor Green
    } else {
        Write-Host "❌ 修改仓库可见性失败" -ForegroundColor Red
        Read-Host "按 Enter 键退出"
        exit 1
    }
} catch {
    Write-Host "❌ 修改仓库可见性失败: $_" -ForegroundColor Red
    Read-Host "按 Enter 键退出"
    exit 1
}

Write-Host ""

# 启用 GitHub Pages
Write-Host "[3/4] 启用 GitHub Pages (Source: /docs)..." -ForegroundColor Yellow
try {
    & $ghPath api repos/huiyu9144/Apps-iOSMac/pages -X POST -f build_type=workflow -f source[branch]=main -f source[path]=/docs
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ GitHub Pages 已启用" -ForegroundColor Green
    } else {
        Write-Host "⚠️ GitHub Pages API 调用失败，请手动在网页上启用" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ GitHub Pages API 调用失败，请手动在网页上启用" -ForegroundColor Yellow
}

Write-Host ""

# 显示结果
Write-Host "[4/4] 配置完成！" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ 请访问以下链接完成配置：" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. 访问 GitHub Pages 设置：" -ForegroundColor White
Write-Host "   https://github.com/huiyu9144/Apps-iOSMac/settings/pages" -ForegroundColor Gray
Write-Host ""
Write-Host "2. 确保设置如下：" -ForegroundColor White
Write-Host "   - Branch: main" -ForegroundColor Gray
Write-Host "   - Folder: /docs" -ForegroundColor Gray
Write-Host "   - 点击 Save" -ForegroundColor Gray
Write-Host ""
Write-Host "3. 等待几分钟后访问：" -ForegroundColor White
Write-Host "   https://huiyu9144.github.io/Apps-iOSMac/" -ForegroundColor Gray
Write-Host ""

Read-Host "按 Enter 键退出"
