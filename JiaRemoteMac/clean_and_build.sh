#!/bin/bash
# JiaRemote Mac 端清理 + 重编脚本

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="JiaRemoteMac"

echo "============================================"
echo "  🧹 JiaRemote Mac 端缓存清理工具"
echo "============================================"
echo ""

echo "[1/4] 清理 build.sh 构建产物..."
rm -rf "$PROJECT_DIR/build" 2>/dev/null && echo "  ✅ build/ 已删除" || echo "  ℹ️  无 build/ 目录"

echo ""
echo "[2/4] 清理 Xcode DerivedData..."
DERIVED_DATA=~/Library/Developer/Xcode/DerivedData
if [ -d "$DERIVED_DATA" ]; then
    # 查找并删除 JiaRemote 相关的 DerivedData
    FOUND=$(find "$DERIVED_DATA" -maxdepth 1 -name "*JiaRemote*" -o -name "*jiaremote*" 2>/dev/null | head -5)
    if [ -n "$FOUND" ]; then
        echo "$FOUND" | while read dir; do
            rm -rf "$dir"
            echo "  ✅ 已删除: $(basename $dir)"
        done
    else
        echo "  ℹ️  未找到 JiaRemote 相关缓存"
        echo "  💡 提示: 可手动清理全部 DerivedData:"
        echo "     rm -rf ~/Library/Developer/Xcode/DerivedData"
    fi
else
    echo "  ℹ️  无 DerivedData 目录"
fi

echo ""
echo "[3/4] 清理 Swift 模块缓存..."
rm -rf "$PROJECT_DIR/.build" 2>/dev/null && echo "  ✅ .build/ 已删除" || true
rm -rf "$PROJECT_DIR/*.o" 2>/dev/null && echo "  ✅ .o 文件已删除" || true
find "$PROJECT_DIR" -name "*.swp" -delete 2>/dev/null && echo "  ✅ Vim 临时文件已删除" || true
find "$PROJECT_DIR" -name "*~" -delete 2>/dev/null && echo "  ✅ 备份文件已删除" || true
find "$PROJECT_DIR" -name ".DS_Store" -delete 2>/dev/null && echo "  ✅ .DS_Store 已删除" || true

echo ""
echo "[4/4] 开始重新编译..."
if [ -f "$PROJECT_DIR/build.sh" ]; then
    chmod +x "$PROJECT_DIR/build.sh"
    "$PROJECT_DIR/build.sh"
else
    echo "  ❌ 未找到 build.sh"
    echo ""
    echo "请手动执行:"
    echo "  cd $PROJECT_DIR"
    echo "  ./build.sh"
    exit 1
fi

echo ""
echo "============================================"
echo "  ✅ 清理和重编完成！"
echo "  🚀 运行: open $PROJECT_DIR/build/$APP_NAME.app"
echo "============================================"