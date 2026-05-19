
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "正在推送到 GitHub 仓库..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $PSScriptRoot

# 尝试不同的 Git 配置以解决网络问题
Write-Host "[1/4] 配置 Git 网络设置..." -ForegroundColor Yellow
&amp; "C:\Program Files\Git\bin\git.exe" config --local http.sslBackend schannel
&amp; "C:\Program Files\Git\bin\git.exe" config --local http.schannelUseSSLCAInfo false
&amp; "C:\Program Files\Git\bin\git.exe" config --local http.postBuffer 524288000
Write-Host ""

Write-Host "[2/4] 检查当前 Git 状态..." -ForegroundColor Yellow
&amp; "C:\Program Files\Git\bin\git.exe" status
Write-Host ""

Write-Host "[3/4] 开始推送到 GitHub..." -ForegroundColor Yellow
Write-Host "如果提示输入凭据，请输入您的 GitHub 用户名和个人访问令牌 (PAT)" -ForegroundColor Gray
Write-Host ""
&amp; "C:\Program Files\Git\bin\git.exe" push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✅ 推送成功！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "❌ 推送失败，请尝试以下方案：" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "方案 1：使用 GitHub Desktop 图形化客户端" -ForegroundColor White
    Write-Host "   - 下载地址：https://desktop.github.com/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "方案 2：使用个人访问令牌 (PAT) 并使用 HTTPS" -ForegroundColor White
    Write-Host "   - 创建 PAT：https://github.com/settings/tokens" -ForegroundColor Gray
    Write-Host ""
    Write-Host "方案 3：检查网络连接或配置代理" -ForegroundColor White
    Write-Host ""
    Write-Host "方案 4：使用 SSH 方式（需要配置 SSH 密钥）" -ForegroundColor White
}

Write-Host ""
Read-Host "按 Enter 键退出"
