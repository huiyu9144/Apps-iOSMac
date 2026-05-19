#!/bin/bash
# JiaRemote Mac 被控端编译脚本
# 使用方法: chmod +x build.sh && ./build.sh
# 前提条件: Xcode Command Line Tools 已安装

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="JiaRemoteMac"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "=== JiaRemote Mac 被控端 构建 ==="
echo "项目目录: $PROJECT_DIR"

rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

echo ""
echo "[1/3] 编译 Swift 源码..."

SWIFT_FILES=(
    "$PROJECT_DIR/Sources/Protocol/JiaProtocol.swift"
    "$PROJECT_DIR/Sources/Capture/CaptureEngine.swift"
    "$PROJECT_DIR/Sources/Input/InputController.swift"
    "$PROJECT_DIR/Sources/Config/ConfigManager.swift"
    "$PROJECT_DIR/Sources/Network/BonjourService.swift"
    "$PROJECT_DIR/Sources/Network/TCPServer.swift"
    "$PROJECT_DIR/Sources/Network/UDPScanner.swift"
    "$PROJECT_DIR/Sources/Utils/DebugLogger.swift"
    "$PROJECT_DIR/Sources/AppDelegate.swift"
    "$PROJECT_DIR/Sources/main.swift"
)

swiftc \
    -target arm64-apple-macos12.3 \
    -O -whole-module-optimization \
    -framework Cocoa \
    -framework SwiftUI \
    -framework Combine \
    -framework Network \
    -framework ScreenCaptureKit \
    -framework CoreGraphics \
    -framework CoreVideo \
    -framework IOSurface \
    -framework ApplicationServices \
    -framework IOKit \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    "${SWIFT_FILES[@]}"

echo "  编译完成 → $APP_BUNDLE/Contents/MacOS/$APP_NAME"

echo ""
echo "[2/3] 复制资源文件..."
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

echo ""
echo "[3/3] 签名 (ad-hoc)..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || echo "  跳过签名（开发模式无需签名）"

echo ""
echo "============================================"
echo "  ✅ 构建完成!"
echo "  📦 $APP_BUNDLE"
echo "  🚀 双击运行或: open $APP_BUNDLE"
echo "============================================"
echo ""
echo "首次运行前请确保已授予权限:"
echo "  系统设置 → 隐私与安全性 → 屏幕录制 → 启用 JiaRemote"
echo "  系统设置 → 隐私与安全性 → 辅助功能 → 启用 JiaRemote"
