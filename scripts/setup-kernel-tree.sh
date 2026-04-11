#!/usr/bin/env bash
#
# setup-kernel-tree.sh — Download and prepare a vanilla kernel tree for
#                         out-of-tree module builds
#
# Usage:
#   ./scripts/setup-kernel-tree.sh <version> <arch> [cross_compile]
#   ./scripts/setup-kernel-tree.sh 6.1.141 arm64
#   ./scripts/setup-kernel-tree.sh 6.1.141 arm64 aarch64-none-linux-gnu-
#   ./scripts/setup-kernel-tree.sh 4.19.320 arm arm-linux-gnueabihf-
#   ./scripts/setup-kernel-tree.sh --info
#
# The prepared tree is placed under kernel-trees/<version>-<arch>/
# relative to the driver root. Use this path as LINUX_KERNEL_PATH in
# build-matrix-local.sh.
#
# This script handles vanilla kernel.org kernels. For vendor-patched kernels
# (OpenIPC, Rockchip SDK, etc.) see the --info output.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRIVER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TREES_DIR="$DRIVER_DIR/kernel-trees"

# ─── Vendor kernel reference info ────────────────────────────────────────────

print_info() {
    cat << 'INFO'
================================================================================
  Kernel Tree Setup — Vendor / Non-Vanilla References
================================================================================

This script auto-downloads and prepares VANILLA kernel.org trees. For vendor-
patched kernels, follow the manual steps below.

────────────────────────────────────────────────────────────────────────────────
 OpenIPC (4.9.84-arm, 5.10.61-arm)
────────────────────────────────────────────────────────────────────────────────
  OpenIPC uses vendor-patched kernels (from github.com/openipc/linux) with
  SoC-specific defconfigs. The module vermagic will only match if built
  against their exact kernel tree.

  Covered platforms:
    4.9.84-arm  — Infinity6/6B0/6E (SSC338Q, SSC337DE),
                  Goke (GK7205V200/V210/V300)
    5.10.61-arm — Infinity6C (SSC378DE)

  Setup:
    git clone https://github.com/OpenIPC/firmware.git openipc-firmware
    cd openipc-firmware
    sudo make deps
    BOARD=ssc338q_fpv make all    # or your target board

  After build completes:
    Kernel tree:  output/build/linux-<version>/
    Toolchain:    output/host/bin/arm-openipc-linux-musleabi-

────────────────────────────────────────────────────────────────────────────────
 Rockchip SDK (6.1.141-arm64)
────────────────────────────────────────────────────────────────────────────────
  If your device kernel has a vendor LOCALVERSION (e.g. 6.1.141-rockchip),
  you must use the SDK kernel tree for vermagic to match.

  If uname -r shows clean "6.1.141" (no suffix), a vanilla tree works.

  SDK setup:
    cd /path/to/rockchip-sdk/kernel
    make ARCH=arm64 rockchip_defconfig
    make ARCH=arm64 modules_prepare

  Toolchain: aarch64-none-linux-gnu- (ARM A-profile 10.3-2021.07)
  Download:  https://developer.arm.com/downloads/-/gnu-a

────────────────────────────────────────────────────────────────────────────────
 Verification (all trees)
────────────────────────────────────────────────────────────────────────────────
  After preparing any tree, verify:

    ls <tree>/Module.symvers        # should exist
    ls <tree>/scripts/basic/fixdep  # should exist
    make -C <tree> kernelversion    # should print expected version

================================================================================
INFO
}

# ─── Usage ────────────────────────────────────────────────────────────────────

usage() {
    echo "Usage: $0 <version> <arch> [cross_compile]"
    echo ""
    echo "  version        Kernel version (e.g. 6.1.141, 6.6.87, 5.15.180)"
    echo "  arch           Architecture (arm, arm64, mips, x86, etc.)"
    echo "  cross_compile  Cross-compiler prefix (optional, e.g. aarch64-none-linux-gnu-)"
    echo ""
    echo "  --info         Show vendor/OpenIPC kernel setup instructions"
    echo "  --list         List already-prepared kernel trees"
    echo "  --help         Show this help"
    echo ""
    echo "Output: kernel-trees/<version>-<arch>/ (use as LINUX_KERNEL_PATH)"
}

list_trees() {
    if [[ ! -d "$TREES_DIR" ]]; then
        echo "No kernel trees found. Run this script to create one."
        return
    fi
    echo "Prepared kernel trees in: $TREES_DIR/"
    echo ""
    for d in "$TREES_DIR"/*/; do
        [[ -d "$d" ]] || continue
        local name
        name="$(basename "$d")"
        local ver="unknown"
        if [[ -f "$d/Makefile" ]]; then
            ver=$(make -s -C "$d" kernelversion 2>/dev/null || echo "unknown")
        fi
        local ready="NOT READY"
        if [[ -f "$d/Module.symvers" ]] || [[ -f "$d/scripts/basic/fixdep" ]]; then
            ready="ready"
        fi
        printf "  %-24s  version=%-12s  %s\n" "$name" "$ver" "$ready"
    done
}

# ─── Main ─────────────────────────────────────────────────────────────────────

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || $# -eq 0 ]]; then
    usage
    exit 0
fi

if [[ "${1:-}" == "--info" ]]; then
    print_info
    exit 0
fi

if [[ "${1:-}" == "--list" ]]; then
    list_trees
    exit 0
fi

if [[ $# -lt 2 ]]; then
    echo "Error: need at least <version> and <arch>"
    usage
    exit 1
fi

VERSION="$1"
ARCH="$2"
CROSS_COMPILE="${3:-}"
TARGET_NAME="${VERSION}-${ARCH}"
TARGET_DIR="$TREES_DIR/$TARGET_NAME"
TARBALL_URL="https://cdn.kernel.org/pub/linux/kernel/v${VERSION%%.*}.x/linux-${VERSION}.tar.xz"

# ─── Preflight checks ────────────────────────────────────────────────────────

for cmd in curl tar make; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: '$cmd' is required but not found."
        exit 1
    fi
done

if [[ -n "$CROSS_COMPILE" ]]; then
    if ! command -v "${CROSS_COMPILE}gcc" &>/dev/null && [[ ! -x "${CROSS_COMPILE}gcc" ]]; then
        echo "Warning: ${CROSS_COMPILE}gcc not found. modules_prepare may fail."
        echo "         Install the toolchain or pass the correct prefix."
    fi
fi

# ─── Check if already prepared ────────────────────────────────────────────────

if [[ -d "$TARGET_DIR" ]]; then
    if [[ -f "$TARGET_DIR/scripts/basic/fixdep" ]] || [[ -f "$TARGET_DIR/Module.symvers" ]]; then
        echo "Kernel tree already prepared at: $TARGET_DIR"
        echo "  Use as LINUX_KERNEL_PATH in build-matrix-local.sh"
        echo ""
        echo "  To re-prepare, remove the directory first:"
        echo "    rm -rf $TARGET_DIR"
        exit 0
    else
        echo "Directory exists but tree not prepared. Continuing from where we left off..."
    fi
fi

mkdir -p "$TREES_DIR"

# ─── Download ─────────────────────────────────────────────────────────────────

TARBALL="$TREES_DIR/linux-${VERSION}.tar.xz"

if [[ -f "$TARBALL" ]]; then
    echo "━━━ Tarball already downloaded: $TARBALL"
else
    echo "━━━ Downloading kernel $VERSION from kernel.org..."
    echo "    URL: $TARBALL_URL"
    if ! curl -fL --progress-bar -o "$TARBALL.tmp" "$TARBALL_URL"; then
        rm -f "$TARBALL.tmp"
        echo ""
        echo "Error: Download failed. Check that version '$VERSION' exists at kernel.org."
        echo "       Browse: https://cdn.kernel.org/pub/linux/kernel/v${VERSION%%.*}.x/"
        exit 1
    fi
    mv "$TARBALL.tmp" "$TARBALL"
    echo "    Saved: $TARBALL"
fi

# ─── Extract ──────────────────────────────────────────────────────────────────

if [[ ! -f "$TARGET_DIR/Makefile" ]]; then
    echo "━━━ Extracting to $TARGET_DIR..."
    tar -xf "$TARBALL" -C "$TREES_DIR"
    if [[ -d "$TREES_DIR/linux-$VERSION" && "$TREES_DIR/linux-$VERSION" != "$TARGET_DIR" ]]; then
        mv "$TREES_DIR/linux-$VERSION" "$TARGET_DIR"
    fi
else
    echo "━━━ Source already extracted at $TARGET_DIR"
fi

# ─── Configure ────────────────────────────────────────────────────────────────

MAKE_ARGS=(ARCH="$ARCH")
if [[ -n "$CROSS_COMPILE" ]]; then
    MAKE_ARGS+=(CROSS_COMPILE="$CROSS_COMPILE")
fi

if [[ ! -f "$TARGET_DIR/.config" ]]; then
    echo "━━━ Running defconfig for ARCH=$ARCH..."
    make -C "$TARGET_DIR" "${MAKE_ARGS[@]}" defconfig
else
    echo "━━━ .config already exists, skipping defconfig"
fi

# ─── Prepare for out-of-tree module builds ────────────────────────────────────

echo "━━━ Running modules_prepare..."
make -C "$TARGET_DIR" "${MAKE_ARGS[@]}" modules_prepare

# ─── Verify ──────────────────────────────────────────────────────────────────

echo ""
echo "━━━ Verification:"
KVER=$(make -s -C "$TARGET_DIR" "${MAKE_ARGS[@]}" kernelversion 2>/dev/null || echo "unknown")
echo "    Kernel version: $KVER"
echo "    Architecture:   $ARCH"

if [[ -f "$TARGET_DIR/scripts/basic/fixdep" ]]; then
    echo "    scripts/basic/fixdep: OK"
else
    echo "    scripts/basic/fixdep: MISSING (build may fail)"
fi

if [[ -f "$TARGET_DIR/Module.symvers" ]]; then
    echo "    Module.symvers: OK"
else
    echo "    Module.symvers: missing (normal after modules_prepare, warnings possible)"
fi

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Kernel tree ready: $TARGET_DIR"
echo ""
echo " Use in build-matrix-local.sh:"
echo "   \"${TARGET_NAME}|${TARGET_DIR}|${ARCH}|${CROSS_COMPILE:-/EDIT/path/to/cross-compiler-}|fmac_sdio\""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"