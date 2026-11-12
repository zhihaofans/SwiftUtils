#!/bin/bash
# 三平台编译检查。
#
# `swift build` 只验 macOS；iOS / watchOS 必须显式指定 SDK 和 triple。
# 这里的三条命令在本机（Xcode 26, Swift 6.2）验证过，能真的把 watchOS
# 专属的 API 缺失编出来——AuthUtil 的 `biometryNotEnrolled` 就是这么发现的。
#
# 用法：
#   Scripts/check-platforms.sh          # macOS 构建 + iOS / watchOS 交叉编译
#   Scripts/check-platforms.sh macos    # 只跑其中一个
#
# 注意：交叉编译只验证「能编过」，不产出可运行产物；测试仍然只在 macOS 跑。

set -euo pipefail

cd "$(dirname "$0")/.."

# 受限沙箱里 SwiftPM 的默认缓存目录（~/Library/Caches、/var/folders）不可写，
# 全部指到仓库内，否则会报 ModuleCache / Invalid manifest。
export TMPDIR="$PWD/.build/tmp"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/modulecache"
export CLANG_MODULE_CACHE_PATH="$PWD/.build/modulecache"
mkdir -p "$TMPDIR" "$SWIFTPM_MODULECACHE_OVERRIDE"

COMMON=(--manifest-cache none --disable-sandbox)

build_macos() {
    echo "==> macOS"
    swift build "${COMMON[@]}"
}

# 交叉编译：SDK 名用 xcrun 的（iphoneos / watchos），triple 用部署目标版本。
build_ios() {
    echo "==> iOS"
    swift build --scratch-path .build/scratch-ios \
        --sdk "$(xcrun --sdk iphoneos --show-sdk-path)" \
        --triple arm64-apple-ios17.0 "${COMMON[@]}"
}

build_watchos() {
    echo "==> watchOS"
    swift build --scratch-path .build/scratch-watchos \
        --sdk "$(xcrun --sdk watchos --show-sdk-path)" \
        --triple arm64_32-apple-watchos26.0 "${COMMON[@]}"
}

target="${1:-all}"
case "$target" in
    macos) build_macos ;;
    ios) build_ios ;;
    watchos) build_watchos ;;
    all)
        build_macos
        build_ios
        build_watchos
        ;;
    *)
        echo "未知目标：$target（可选 macos / ios / watchos / all）" >&2
        exit 2
        ;;
esac

echo "全部通过"
