#!/usr/bin/env bash
#
# setup-kernel-tree.sh — Reference script for preparing kernel build trees
#
# This script documents the steps needed to set up each target kernel tree
# so that out-of-tree module builds work. Run the relevant section manually
# or uncomment and adapt paths for your environment.
#
set -euo pipefail

cat << 'INSTRUCTIONS'
================================================================================
  Kernel Tree Setup Guide for taixin-fmac Out-of-Tree Module Build
================================================================================

Each target kernel tree must be "prepared" before you can build out-of-tree
modules against it. At minimum this means:

  1. Extracting or cloning the kernel source
  2. Generating a .config (defconfig or vendor-provided)
  3. Running: make modules_prepare

After that, point LINUX_KERNEL_PATH in build-matrix-local.sh to the tree root.

────────────────────────────────────────────────────────────────────────────────
 Target: 6.1.141-arm64 (e.g. RV1126B-P / Rockchip SDK / Debian)
────────────────────────────────────────────────────────────────────────────────

  Confirmed from device:
    uname -r:        6.1.141
    Architecture:    arm64 (aarch64)
    Toolchain:       aarch64-none-linux-gnu-gcc 10.3 (ARM A-profile 2021.07)

Option A — From Rockchip SDK:
  # Extract kernel source from the SDK package
  cd /path/to/rockchip-sdk/kernel
  # Use the vendor defconfig for RV1126
  make ARCH=arm64 rockchip_defconfig
  make ARCH=arm64 modules_prepare

Option B — From kernel.org (vanilla, vermagic must match):
  git clone --depth 1 --branch v6.1.141 \
    https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git \
    linux-6.1.141
  cd linux-6.1.141
  make ARCH=arm64 defconfig
  make ARCH=arm64 modules_prepare

Cross-compiler:
  # ARM A-profile toolchain (same version as the kernel was built with)
  # Download: https://developer.arm.com/downloads/-/gnu-a
  # Prefix: aarch64-none-linux-gnu-
  # Verify:  aarch64-none-linux-gnu-gcc --version

────────────────────────────────────────────────────────────────────────────────
 Target: 4.9.84-arm (OpenIPC Infinity6/6B0/6E, Goke GK7205Vxxx)
────────────────────────────────────────────────────────────────────────────────
  Covers: SSC338Q, SSC337DE, GK7205V200, GK7205V210, GK7205V300, and any
  other OpenIPC board running kernel 4.9.84 on arm (Cortex-A7).

  OpenIPC SoC families on this kernel: Infinity6, Infinity6B0, Infinity6E, Goke
  Architecture: arm (Cortex-A7)

Option A — From OpenIPC build system:
  git clone https://github.com/OpenIPC/firmware.git openipc-firmware
  cd openipc-firmware
  # Follow OpenIPC build instructions for sigmastar-infinity6e
  # The kernel tree will be at:
  #   output/build/linux-4.9.84/
  # After the full build, modules_prepare is already done.

Option B — Standalone kernel source:
  # SigmaStar/MStar kernel 4.9.84 sources (vendor-specific)
  # Check OpenIPC GitHub for the exact kernel fork and branch
  cd /path/to/sigmastar-kernel-4.9.84
  make ARCH=arm infinity6e_defconfig
  make ARCH=arm modules_prepare

Cross-compiler:
  # From the OpenIPC SDK toolchain, typically:
  #   arm-openipc-linux-musleabi-gcc
  # Or from the SigmaStar SDK:
  #   arm-linux-gnueabihf-gcc
  # Verify:  arm-openipc-linux-musleabi-gcc --version

────────────────────────────────────────────────────────────────────────────────
 Target: 5.10.61-arm (e.g. OpenIPC Infinity6C — SSC378DE)
────────────────────────────────────────────────────────────────────────────────

  OpenIPC Infinity6C uses kernel 5.10.61 (NOT 4.9.84).
  Architecture: arm (Cortex-A7)

  # Follow the same OpenIPC build process as 4.9.84-arm but using the
  # infinity6c defconfig and matching OpenIPC branch.
  # The kernel tree will be at: output/build/linux-5.10.61/
  # Toolchain: same arm-openipc-linux-musleabi- from output/host/bin/

────────────────────────────────────────────────────────────────────────────────
 Optional: Generic LTS Kernels (6.6.x / 6.12.x)
────────────────────────────────────────────────────────────────────────────────

  git clone --depth 1 --branch linux-6.6.y \
    https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git \
    linux-6.6.x
  cd linux-6.6.x
  make ARCH=arm64 defconfig
  make ARCH=arm64 modules_prepare

  # Repeat for 6.12.x with --branch linux-6.12.y

────────────────────────────────────────────────────────────────────────────────
 Verification
────────────────────────────────────────────────────────────────────────────────

After preparing a tree, verify it's ready for out-of-tree builds:

  ls <kernel-tree>/Module.symvers   # should exist
  ls <kernel-tree>/scripts/basic/   # should contain fixdep

If Module.symvers is missing, you may need: make modules
(but modules_prepare is usually sufficient for out-of-tree builds)

================================================================================
INSTRUCTIONS
