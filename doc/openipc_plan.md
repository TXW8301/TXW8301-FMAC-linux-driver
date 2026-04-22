# OpenIPC Driver Build Plan

## Goal
Build `hgicf.ko` for OpenIPC targets while keeping this repository as the primary driver source.

## Key Constraint
OpenIPC uses vendor-patched kernels and toolchains. For deployable OpenIPC modules, build against the matching OpenIPC kernel tree and toolchain, not vanilla kernel.org trees.

## What We Validated
- Compile compatibility is green for:
  - `6.1.141-arm64`
  - `4.9.84-arm`
  - `5.10.61-arm`
- Vanilla trees are useful for compile checks.
- Runtime/loading on OpenIPC still requires matching vendor kernel+toolchain (vermagic match).

## Recommended OpenIPC Workflow (Now)
1. Build OpenIPC firmware once for each target board.
2. Reuse generated artifacts:
   - Kernel tree: `output/build/linux-<version>/`
   - Toolchain: `output/host/bin/arm-openipc-linux-musleabi-`
3. Build this driver using those paths:

```bash
make fmac_sdio \
  LINUX_KERNEL_PATH=/path/to/openipc-firmware/output/build/linux-4.9.84 \
  ARCH=arm \
  COMPILER=/path/to/openipc-firmware/output/host/bin/arm-openipc-linux-musleabi-
```

## Optional Later Path
If firmware images should include this driver by default, integrate as a Buildroot package in an OpenIPC firmware fork (package `.mk` + defconfig wiring).

## References
- `https://github.com/libc0607/hgic_ah_fmac`
- `https://github.com/libc0607/openipc-firmware`
