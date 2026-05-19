
@echo off
echo ========================================
echo 正在推送到 GitHub 仓库...
echo ========================================
echo.

cd /d "%~dp0"

REM 尝试不同的 Git 配置以解决网络问题
echo [1/4] 配置 Git 网络设置...
"C:\Program Files\Git\bin\git.exe" config --local http.sslBackend schannel
"C:\Program Files\Git\bin\git.exe" config --local http.schannelUseSSLCAInfo false
"C:\Program Files\Git\bin\git.exe" config --local http.postBuffer 524288000
echo.

echo [2/4] 检查当前 Git 状态...
"C:\Program Files\Git\bin\git.exe" status
echo.

echo [3/4] 开始推送到 GitHub...
echo 如果提示输入凭据，请输入您的 GitHub 用户名和个人访问令牌 (PAT)
echo.
"C:\Program Files\Git\bin\git.exe" push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo ✅ 推送成功！
    echo ========================================
) else (
    echo.
    echo ========================================
    echo ❌ 推送失败，请尝试以下方案：
    echo ========================================
    echo.
    echo 方案 1：使用 GitHub Desktop 图形化客户端
    echo    - 下载地址：https://desktop.github.com/
    echo.
    echo 方案 2：使用个人访问令牌 (PAT) 并使用 HTTPS
    echo    - 创建 PAT：https://github.com/settings/tokens
    echo.
    echo 方案 3：检查网络连接或配置代理
    echo.
    echo 方案 4：使用 SSH 方式（需要配置 SSH 密钥）
)

echo.
pause
