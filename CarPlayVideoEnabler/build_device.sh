#!/bin/bash
# ============================================================
#  CarPlayVideoEnabler - iOS 设备端编译脚本
#  在已越狱的 iPhone/iPad 上直接编译
#
#  前置条件:
#    - 已越狱的 iOS 14.0+ 设备
#    - 已安装 Theos (推荐) 或 clang
#
#  安装 Theos (iOS):
#    依赖: bash curl git make perl rsync
#    bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"
#    (或通过 Sileo/Cydia 安装 theos 包)
# ============================================================

set -e

DYLIB_NAME="CarPlayVideoEnabler"
SOURCE_FILE="CarPlayVideoEnabler_standalone.m"

echo "=========================================="
echo " CarPlayVideoEnabler 设备端编译"
echo "=========================================="

# ---- 检查源文件 ----
if [ ! -f "$SOURCE_FILE" ]; then
    echo "[错误] 找不到 $SOURCE_FILE"
    exit 1
fi

# ---- 检测编译环境 ----
THEOS_PATH=""
for p in /var/theos /opt/theos /usr/local/theos ~/theos; do
    if [ -d "$p" ] && [ -f "$p/makefiles/common.mk" ]; then
        THEOS_PATH="$p"
        break
    fi
done

HAS_THEOS=false
HAS_CLANG=false

if [ -n "$THEOS_PATH" ]; then
    HAS_THEOS=true
    echo "[检测] Theos: $THEOS_PATH"
fi

if command -v clang &>/dev/null; then
    HAS_CLANG=true
    CLANG_VER=$(clang --version 2>/dev/null | head -1)
    echo "[检测] clang: $CLANG_VER"
fi

if ! $HAS_THEOS && ! $HAS_CLANG; then
    echo ""
    echo "[错误] 未检测到编译工具"
    echo ""
    echo "请安装以下任一工具链:"
    echo ""
    echo "方案1 - 安装 Theos (推荐):"
    echo "  Sileo/Cydia 中搜索安装 'theos'"
    echo "  或手动安装:"
    echo "  bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)\""
    echo ""
    echo "方案2 - 安装 clang:"
    echo "  Sileo/Cydia 中搜索安装 'clang'"
    exit 1
fi

# ---- 选择编译方式 ----
if $HAS_THEOS; then
    echo ""
    echo "使用 Theos 编译 .deb 包..."
    echo ""

    export THEOS="$THEOS_PATH"

    if ! make package; then
        echo ""
        echo "[错误] Theos 编译失败"
        echo "请检查是否缺少依赖: make, perl, dpkg"
        exit 1
    fi

    echo ""
    echo "=========================================="
    echo " 编译完成"
    echo "=========================================="
    echo ""
    echo ".deb 在 packages/ 目录中"
    echo ""
    echo "安装方式:"
    echo "  1. 用 Filza 打开 .deb → 安装"
    echo "  2. 或用 dpkg -i packages/*.deb"
    echo ""
    echo "提取 dylib 用于 TrollFools:"
    echo "  cd .theos/obj/debug"
    echo "  找到 CarPlayVideoEnabler.dylib 即可注入"
    echo ""

elif $HAS_CLANG; then
    echo ""
    echo "使用 clang 编译纯 dylib..."
    echo ""

    SYSROOT=""
    for sdk in /var/sdks/*.sdk /usr/share/sdks/*.sdk /var/theos/sdks/*.sdk; do
        if [ -d "$sdk" ]; then
            SYSROOT="$sdk"
            break
        fi
    done

    if [ -z "$SYSROOT" ]; then
        echo "[警告] 未找到 iOS SDK, 尝试不带 -isysroot 编译..."
        CLANG_FLAGS="-arch arm64 -dynamiclib -fobjc-arc -framework Foundation -framework UIKit -framework CoreLocation"
    else
        echo "[信息] SDK: $SYSROOT"
        CLANG_FLAGS="-arch arm64 -isysroot $SYSROOT -miphoneos-version-min=14.0 -dynamiclib -fobjc-arc -framework Foundation -framework UIKit -framework CoreLocation"
    fi

    mkdir -p ./build

    clang $CLANG_FLAGS \
        -o "./build/${DYLIB_NAME}.dylib" \
        "$SOURCE_FILE"

    if command -v ldid &>/dev/null; then
        ldid -S "./build/${DYLIB_NAME}.dylib"
    fi

    echo ""
    echo "=========================================="
    echo " 编译完成"
    echo "=========================================="
    echo "输出: ./build/${DYLIB_NAME}.dylib"
    echo ""
    echo "注入方式:"
    echo "  TrollFools → 选择目标 App → 注入"
    echo ""
fi
