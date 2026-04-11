#!/usr/bin/env bash
#
# build-matrix-local.sh — Build taixin-fmac driver for all configured targets
#
# Usage:
#   ./scripts/build-matrix-local.sh              # build all targets
#   ./scripts/build-matrix-local.sh 6.1.141-arm64 # build one target by name
#   ./scripts/build-matrix-local.sh --list        # list configured targets
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRIVER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$DRIVER_DIR/logs"

# ─── Target definitions ──────────────────────────────────────────────────────
# Each target: NAME|KERNEL_PATH|ARCH|CROSS_COMPILE|BUILD_TARGET
#
# Fill in KERNEL_PATH and CROSS_COMPILE for your local environment.
# KERNEL_PATH must point to a prepared kernel tree (headers installed,
# modules_prepare done).
#
# BUILD_TARGET is the Makefile target: fmac, fmac_sdio, fmac_usb
#
# Target names use kernel-version+arch format so the same .ko works on any
# hardware running the matching kernel+arch, regardless of SoC vendor.
#
# Known platform associations (for reference, not build-relevant):
#   6.1.141-arm64  — RV1126B-P (Rockchip SDK / Debian), toolchain: aarch64-none-linux-gnu-
#   4.9.84-arm     — OpenIPC Infinity6/6B0/6E (SSC338Q, SSC337DE, GK7205V200/V210/V300, etc.)
#   5.10.61-arm    — OpenIPC Infinity6C (SSC378DE, etc.)
#
TARGETS=(
    "6.1.141-arm64|/EDIT/path/to/kernel-6.1.141|arm64|/EDIT/path/to/aarch64-none-linux-gnu-|fmac_sdio"
    "4.9.84-arm|/EDIT/path/to/kernel-4.9.84|arm|/EDIT/path/to/arm-openipc-linux-musleabi-|fmac_sdio"
    "5.10.61-arm|/EDIT/path/to/kernel-5.10.61|arm|/EDIT/path/to/arm-openipc-linux-musleabi-|fmac_sdio"
    # "6.6.x-arm64|/EDIT/path/to/linux-6.6.x|arm64|/EDIT/path/to/aarch64-linux-gnu-|fmac"
    # "6.12.x-arm64|/EDIT/path/to/linux-6.12.x|arm64|/EDIT/path/to/aarch64-linux-gnu-|fmac"
)

# ─── Helpers ──────────────────────────────────────────────────────────────────

usage() {
    echo "Usage: $0 [target-name | --list | --help]"
    echo ""
    echo "  (no args)     Build all enabled targets"
    echo "  target-name   Build only the named target"
    echo "  --list        List configured targets"
    echo "  --help        Show this help"
}

list_targets() {
    printf "%-14s %-8s %-12s %s\n" "NAME" "ARCH" "BUILD" "KERNEL_PATH"
    printf "%-14s %-8s %-12s %s\n" "----" "----" "-----" "-----------"
    for entry in "${TARGETS[@]}"; do
        IFS='|' read -r name kpath arch cc target <<< "$entry"
        printf "%-14s %-8s %-12s %s\n" "$name" "$arch" "$target" "$kpath"
    done
}

validate_target() {
    local name="$1" kpath="$2" arch="$3" cc="$4" target="$5"
    local errors=0

    if [[ "$kpath" == /EDIT/* ]]; then
        echo "  ERROR: KERNEL_PATH not configured (still has /EDIT/ placeholder)"
        errors=1
    elif [[ ! -d "$kpath" ]]; then
        echo "  ERROR: KERNEL_PATH does not exist: $kpath"
        errors=1
    fi

    if [[ "$cc" == /EDIT/* ]]; then
        echo "  ERROR: CROSS_COMPILE not configured (still has /EDIT/ placeholder)"
        errors=1
    elif ! command -v "${cc}gcc" &>/dev/null && [[ ! -x "${cc}gcc" ]]; then
        echo "  WARNING: ${cc}gcc not found in PATH or as absolute path"
    fi

    return $errors
}

build_target() {
    local name="$1" kpath="$2" arch="$3" cc="$4" target="$5"
    local logfile="$LOG_DIR/build-${name}.log"
    local rc=0

    echo "━━━ Building: $name (${target}, ${arch}, kernel: ${kpath}) ━━━"

    if ! validate_target "$name" "$kpath" "$arch" "$cc" "$target"; then
        echo "  SKIPPED — fix configuration errors above"
        echo "SKIPPED" > "$logfile"
        return 1
    fi

    (
        cd "$DRIVER_DIR"
        make clean 2>/dev/null || true
        make "$target" \
            LINUX_KERNEL_PATH="$kpath" \
            ARCH="$arch" \
            COMPILER="$cc" \
            2>&1
    ) | tee "$logfile"
    rc=${PIPESTATUS[0]}

    if [[ $rc -eq 0 ]] && [[ -f "$DRIVER_DIR/ko/hgicf.ko" ]]; then
        local dest="$LOG_DIR/hgicf-${name}.ko"
        cp "$DRIVER_DIR/ko/hgicf.ko" "$dest"
        echo "  ✓ Module copied to: $dest"
        file "$dest"
    fi

    return $rc
}

# ─── Main ─────────────────────────────────────────────────────────────────────

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

if [[ "${1:-}" == "--list" ]]; then
    list_targets
    exit 0
fi

mkdir -p "$LOG_DIR"

FILTER="${1:-}"
PASS=()
FAIL=()
SKIP=()

for entry in "${TARGETS[@]}"; do
    IFS='|' read -r name kpath arch cc target <<< "$entry"

    # If a filter was given, skip non-matching targets
    if [[ -n "$FILTER" && "$name" != "$FILTER" ]]; then
        continue
    fi

    if build_target "$name" "$kpath" "$arch" "$cc" "$target"; then
        PASS+=("$name")
    else
        if grep -q "^SKIPPED" "$LOG_DIR/build-${name}.log" 2>/dev/null; then
            SKIP+=("$name")
        else
            FAIL+=("$name")
        fi
    fi
    echo ""
done

# ─── Summary ──────────────────────────────────────────────────────────────────

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Build Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
[[ ${#PASS[@]} -gt 0 ]] && echo "  PASS: ${PASS[*]}"
[[ ${#FAIL[@]} -gt 0 ]] && echo "  FAIL: ${FAIL[*]}"
[[ ${#SKIP[@]} -gt 0 ]] && echo "  SKIP: ${SKIP[*]}"
echo ""
echo "  Logs: $LOG_DIR/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ ${#FAIL[@]} -gt 0 ]]; then
    exit 1
fi
