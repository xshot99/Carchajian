#!/bin/bash
# ============================================================
#  CarPlayVideoEnabler - macOS 独立编译脚本
#  输出纯 ObjC 运行时 dylib，不依赖 Substrate/ellekit
#  适用于 TrollFools / E-Sign / Feather 注入
#
#  前置条件:
#    macOS + Xcode 或 Xcode Command Line Tools
#    brew install ldid (可选, 用于签名)
# ============================================================

set -e

DYLIB_NAME="CarPlayVideoEnabler"
OUTPUT_DIR="./build"
SOURCE_FILE="CarPlayVideoEnabler_standalone.m"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "============================================"
echo "  CarPlayVideoEnabler 独立 dylib 编译"
echo "============================================"
echo ""

# ---- 检查源文件 ----
if [ ! -f "$SOURCE_FILE" ]; then
    echo -e "${RED}[错误] 找不到 $SOURCE_FILE, 请确认在项目根目录运行此脚本${NC}"
    exit 1
fi

# ---- 获取 SDK 路径 (先查 iphoneos, 不行查 appletvos 再不行提示用户) ----
SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null || echo "")"

if [ -z "$SDK_PATH" ]; then
    echo -e "${RED}[错误] 未找到 iPhoneOS SDK${NC}"
    echo ""
    echo "请先安装 Xcode Command Line Tools:"
    echo "  xcode-select --install"
    echo ""
    echo "如果已安装 Xcode, 请确认 Xcode 路径:"
    echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    exit 1
fi

echo -e "${GREEN}[信息] SDK: $SDK_PATH${NC}"

# ---- 检测可用架构 ----
ARCH_LIST=()
echo "[检测] 可用架构:"

clang -arch arm64 -isysroot "$SDK_PATH" -c /dev/null -o /dev/null 2>/dev/null && {
    ARCH_LIST+=("arm64")
    echo "  arm64    - 可用"
} || echo "  arm64    - 不可用"

clang -arch arm64e -isysroot "$SDK_PATH" -c /dev/null -o /dev/null 2>/dev/null && {
    ARCH_LIST+=("arm64e")
    echo "  arm64e   - 可用"
} || echo "  arm64e   - 不可用 (Xcode 11+ 才支持)"

if [ ${#ARCH_LIST[@]} -eq 0 ]; then
    echo -e "${RED}[错误] 无可用的编译架构${NC}"
    exit 1
fi

echo ""

# ---- 创建输出目录 ----
mkdir -p "$OUTPUT_DIR"

# ---- 编译每个架构 ----
TEMP_FILES=()
for ARCH in "${ARCH_LIST[@]}"; do
    OUTPUT_TEMP="$OUTPUT_DIR/${DYLIB_NAME}_${ARCH}.dylib"
    TEMP_FILES+=("$OUTPUT_TEMP")

    echo "[编译] $ARCH ..."
    clang -arch "$ARCH" \
        -isysroot "$SDK_PATH" \
        -miphoneos-version-min=14.0 \
        -dynamiclib \
        -fobjc-arc \
        -framework Foundation \
        -framework UIKit \
        -framework CoreLocation \
        -o "$OUTPUT_TEMP" \
        "$SOURCE_FILE"

    echo -e "${GREEN}  $ARCH 编译完成${NC}"
done

# ---- 合并架构 (多架构时) ----
FINAL_OUTPUT="$OUTPUT_DIR/${DYLIB_NAME}.dylib"

if [ ${#ARCH_LIST[@]} -gt 1 ]; then
    echo ""
    echo "[合并] 合并为通用 dylib (${ARCH_LIST[*]})..."
    lipo -create "${TEMP_FILES[@]}" -output "$FINAL_OUTPUT"
    rm -f "${TEMP_FILES[@]}"
else
    mv "${TEMP_FILES[0]}" "$FINAL_OUTPUT"
fi

# ---- 签名 ----
echo ""
if command -v ldid &>/dev/null; then
    echo "[签名] 使用 ldid 签名..."
    ldid -S "$FINAL_OUTPUT"
    echo -e "${GREEN}  签名完成${NC}"
elif [ -f "/usr/local/bin/ldid" ]; then
    echo "[签名] 使用 ldid 签名..."
    /usr/local/bin/ldid -S "$FINAL_OUTPUT"
    echo -e "${GREEN}  签名完成${NC}"
elif [ -f "/opt/homebrew/bin/ldid" ]; then
    echo "[签名] 使用 ldid 签名..."
    /opt/homebrew/bin/ldid -S "$FINAL_OUTPUT"
    echo -e "${GREEN}  签名完成${NC}"
else
    echo -e "${YELLOW}[跳过] ldid 未安装, 跳过签名${NC}"
    echo "  TrollFools 注入不需要签名, 可直接使用"
    echo "  如需签名注入, 请先 brew install ldid 再重新编译"
fi

# ---- 输出信息 ----
echo ""
echo "============================================"
echo -e "${GREEN}  构建成功${NC}"
echo "============================================"
echo "输出: $FINAL_OUTPUT"
echo ""
echo "架构: ${ARCH_LIST[*]}"
SIZE=$(stat -f%z "$FINAL_OUTPUT" 2>/dev/null || stat -c%s "$FINAL_OUTPUT" 2>/dev/null || echo "?")
echo "大小: $SIZE 字节"
echo ""
echo "--- 注入使用方式 ---"
echo ""
echo "方式1 - TrollFools (最简单, 无需越狱):"
echo "  1. AirDrop/微信/QQ 发送 $DYLIB_NAME.dylib 到手机"
echo "  2. 打开 TrollFools App"
echo "  3. 选择目标 App → 注入"
echo "  4. 推荐目标: YouTube, Netflix, Safari, B站, 优酷"
echo ""
echo "方式2 - 签名注入 (E-Sign/Feather/AltStore):"
echo "  1. 下载目标 App 的脱壳 IPA"
echo "  2. 用签名工具打开 IPA, 注入 $DYLIB_NAME.dylib"
echo "  3. 签名 → 安装到手机"
echo ""
echo "============================================"
