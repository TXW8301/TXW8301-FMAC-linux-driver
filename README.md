# TXW8301 FMAC Linux Driver

Linux FMAC/SMAC driver package for Taixin TXW8301 (HaLow) with SDIO and USB transport support, plus userspace test and control tools.

This repository is maintained as:
- a vendor baseline mirror on `main` for each official drop
- custom development on feature branches

## Version and Scope

- Current vendor baseline tag: `vendor-v2.2.1-43002`
- Typical kernel module output:
  - FMAC: `ko/hgicf.ko`
  - SMAC: `ko/hgics.ko`

Recent vendor note highlights (v2.2.1-43002):
- Added interfaces related to `rmesh`.
- Added manual guidance: bring `hg0` down before setting connection parameters.
- Added an English guide under `doc/`.

## Repository Layout

- `hgic_fmac/`: FMAC kernel module source
- `hgic_smac/`: SMAC kernel module source (if included by vendor package)
- `utils/`: bus and firmware helpers
- `tools/test_app/`: userspace tools (`hgpriv`, `hgicf`, `hgota`, `libnetat`, `libnetat_cli`)
- `doc/`: vendor and project documents
- `scripts/`:
  - `setup-userspace-toolchain.sh`: musl toolchain setup for OpenIPC-style targets
  - `vendor-sync-from-zip.sh`: one-command vendor drop sync helper

## Build Prerequisites

- Linux build host
- `make`, `gcc`, `git`, `rsync`, `unzip`
- Cross toolchain compatible with target kernel/userspace
- Correct target kernel source tree for module ABI compatibility

Important:
- Build against the exact kernel tree used by your target image.
- Matching `vermagic` alone is not always sufficient if internal struct layouts differ.

## Build Kernel Modules

The root `Makefile` provides these targets:

- `make fmac` (USB + SDIO)
- `make fmac_usb`
- `make fmac_sdio`
- `make smac` (USB + SDIO)
- `make smac_usb`
- `make smac_sdio`
- `make clean`

Example (FMAC SDIO cross-build):

```bash
make fmac_sdio \
  ARCH=arm \
  COMPILER=arm-linux-gnueabihf- \
  LINUX_KERNEL_PATH=/path/to/linux-kernel \
  CONFIG_HGIC_AH=y
```

Example (FMAC USB):

```bash
make fmac_usb \
  ARCH=arm \
  COMPILER=arm-linux-gnueabihf- \
  LINUX_KERNEL_PATH=/path/to/linux-kernel \
  CONFIG_HGIC_AH=y
```

Verify output:

```bash
ls -l ko/hgicf.ko
modinfo ko/hgicf.ko | grep vermagic
```

## Build Userspace Tools (`tools/test_app`)

`tools/test_app/GNUmakefile` is the primary build entry for userspace tools.

OpenIPC-style musl workflow:

```bash
./scripts/setup-userspace-toolchain.sh --download
source toolchains/env.sh
make -C tools/test_app CC=arm-openipc-linux-musleabi-gcc
```

Artifacts are stored by compiler name, for example:

- `tools/test_app/bin/arm-openipc-linux-musleabi-gcc/hgpriv`
- `tools/test_app/bin/arm-openipc-linux-musleabi-gcc/hgicf`
- `tools/test_app/bin/arm-openipc-linux-musleabi-gcc/hgota`
- `tools/test_app/bin/arm-openipc-linux-musleabi-gcc/libnetat`
- `tools/test_app/bin/arm-openipc-linux-musleabi-gcc/libnetat_cli`

Helpful target:

```bash
make -C tools/test_app help
```

## Runtime Essentials on Target

Typical FMAC deployment requires:

- kernel module: `hgicf.ko`
- firmware image in `/lib/firmware/` (commonly `hgicf.bin`)
- runtime config file: `/etc/hgicf.conf`

Bring interface up after load:

```bash
ip link set hg0 up
```

Vendor guidance:
- Before updating connection parameters, bring interface down first:

```bash
ip link set hg0 down
# apply parameters
ip link set hg0 up
```

## Vendor Drop Sync Workflow

Use `main` as vendor mirror and perform custom work on feature branches.

One-command helper:

```bash
./scripts/vendor-sync-from-zip.sh \
  --zip /path/to/taixin-fmac-linux-driver-vX.Y.Z-BBBBB.zip \
  --vendor-dir taixin-fmac-linux-driver-vX.Y.Z-BBBBB \
  --pre-tag vendor-vOLD \
  --post-tag vendor-vNEW \
  --commit "vendor: sync taixin-fmac-linux-driver vX.Y.Z-BBBBB" \
  --push --yes
```

Behavior summary:
- requires clean working tree
- fast-forwards `main`
- mirrors vendor content via `rsync --delete` (excluding `.git`)
- supports optional tags, commit, and push

## Recommended Git Policy

- Keep `main` vendor-only when importing new packages.
- Put local/custom changes on feature branches.
- Rebase custom branches onto updated vendor `main` after each vendor drop.
- Use Jira key in commit titles for custom changes.

## Troubleshooting Quick Notes

- `insmod` panic after successful insert often indicates kernel ABI mismatch.
- If unresolved symbol errors appear, re-check compiler flags and target kernel exports.
- If userspace tools fail to run on target, verify libc/toolchain ABI (`musl` vs `glibc`).
- If no network behavior is observed, ensure firmware/config are present and `hg0` is configured as expected.

## Documentation

Primary references are under `doc/`.

When CN and EN documents differ, use the newest revision as the source of truth, and validate behavior against current implementation.
