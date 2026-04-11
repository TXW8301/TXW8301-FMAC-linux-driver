# HUGE-IC Driver - Multi-Kernel Support and Release Plan

## Objective
Build, validate, and release `taixin-fmac` for multiple kernel families:
- Linux 4.9.84 (OpenIPC targets: SSC338Q / likely SSC378DE family)
- Linux 6.1.141 (RV1126B-P with Debian / Rockchip SDK baseline)
- Optional expansion: Linux 6.6.x and 6.12.x

Keep one source tree with compatibility guards, and produce reproducible build artifacts per kernel target.

## High-Level Checklist
- [ ] Define supported target matrix (kernel + arch + toolchain + bus + interface + SDK profile)
- [ ] Prepare local kernel build trees and toolchains
- [ ] Build locally for each target and collect logs
- [ ] Apply compatibility fixes in small patches
- [ ] Validate firmware-loader prerequisites on each target kernel/rootfs
- [ ] Runtime smoke-test on real hardware per platform
- [ ] Define reproducible build environment (native + containerized)
- [ ] Add GitHub Actions matrix build jobs
- [ ] Publish release artifacts per target kernel

---

## 1) Target Matrix (Source of Truth)

Track this matrix in the repo and use it for both local and CI builds.

| Target | Kernel | Platform | Arch | Toolchain | Interface | SDK/FW Profile | Status |
|---|---:|---|---|---|---|---|---|
| RV1126B-P | 6.1.141 | Debian / Rockchip SDK | arm64 (or arm) | Rockchip cross-gcc | SDIO (primary), USB (optional) | FMAC fw v2.x.x.5 | planned |
| SSC338Q | 4.9.84 | OpenIPC Infinity6E | arm | OpenIPC SDK gcc | SDIO (primary) | confirm 1.x/2.x | planned |
| SSC378DE | 4.9.x | OpenIPC Infinity6C (likely) | arm | OpenIPC SDK gcc | SDIO (primary) | confirm 1.x/2.x | planned |
| Generic LTS | 6.6.x | optional | arm64/arm | distro or cross | SDIO and/or USB | FMAC fw v2.x.x.5 | optional |
| Generic LTS | 6.12.x | optional | arm64/arm | distro or cross | SDIO and/or USB | FMAC fw v2.x.x.5 | optional |

Notes:
- Confirm exact kernel subversion for SSC378DE from running device (`uname -r`) and matching OpenIPC SDK branch.
- Keep architecture and cross-compiler explicit per target.
- Record which interface is actually used in product deployment (SDIO vs USB) and always test that path first.
- Track SDK generation explicitly because several command semantics differ between 1.x and 2.x.

---

## 2) Local Build Workflow (Per Target)

From driver root (`taixin-fmac-linux-driver-v2.2.1-41305`):

```bash
make clean
make fmac \
  LINUX_KERNEL_PATH=/abs/path/to/kernel-tree-or-build-dir \
  ARCH=<arm|arm64> \
  COMPILER=<cross-prefix>
```

Interface-specific builds (recommended for matrix completeness):

```bash
make clean
make fmac_sdio LINUX_KERNEL_PATH=/abs/path/to/kernel ARCH=<arm|arm64> COMPILER=<cross-prefix>

make clean
make fmac_usb  LINUX_KERNEL_PATH=/abs/path/to/kernel ARCH=<arm|arm64> COMPILER=<cross-prefix>
```

Alternative direct kernel-style build:

```bash
make -C /abs/path/to/kernel M=$PWD/hgic_fmac \
  ARCH=<arm|arm64> CROSS_COMPILE=<cross-prefix> \
  CONFIG_HGICF=m CONFIG_HGIC_USB=y CONFIG_HGIC_SDIO=y modules
```

Log each build separately:

```bash
... 2>&1 | tee logs/build-<target>-<kernel>.log
```

---

## 3) Compile Compatibility Review (Verified Against Current Tree)

Already in place and useful for 4.9 -> 6.x span:
- `proc_ops` compatibility (`hgic_def.h`)
- `PDE_DATA` compatibility (`hgic_def.h`)
- `_KERNEL_READ` compatibility (`hgic_def.h`)
- `setup_timer` / `timer_setup` compatibility (`hgic_def.h`)
- `access_ok` and `dev_open` compatibility (`hgic_def.h`)
- `priv_destructor` guard (`hgic_fmac/core.c`)
- `dev_addr_mod` guard (`hgic_fmac/core.c`)
- `netif_rx_ni` fallback guard (`hgic_fmac/core.c`)

Must-fix for 5.15+ kernels (affects 6.1/6.6/6.12):
- `hgic_fmac/core.c` currently uses `.ndo_do_ioctl`, removed from modern `net_device_ops`.
- Replace with a conditional:

```c
#if LINUX_VERSION_CODE >= KERNEL_VERSION(5,15,0)
static int hgicf_netif_siocdevprivate(struct net_device *dev,
                                      struct ifreq *ifr,
                                      void __user *data, int cmd)
{
    return hgicf_ioctl(dev, ifr, cmd);
}
#endif

static const struct net_device_ops hgicf_netif_ops = {
    ...
#if LINUX_VERSION_CODE >= KERNEL_VERSION(5,15,0)
    .ndo_siocdevprivate = hgicf_netif_siocdevprivate,
#else
    .ndo_do_ioctl       = hgicf_netif_ioctl,
#endif
    ...
};
```

Important correction:
- `.ndo_siocdevprivate` uses the 4-argument signature shown above (no extra bool parameter).

Namespace import note:
- `MODULE_IMPORT_NS(...)` is present in `hgic_fmac/core.c` and `utils/fwdl.c` for >= 5.10.
- Re-check formatting if you later add 6.2+ specific guards.

---

## 4) Runtime Smoke Test Plan (Per Hardware Target)

1. Firmware-loader preflight on target kernel/rootfs:
  - Ensure kernel enables `CONFIG_FW_LOADER`.
  - Verify firmware search path for the target kernel/rootfs (older kernels may differ).
  - Verify userspace helper path and hotplug handler when applicable (`/proc/sys/kernel/hotplug`, mdev/udev setup).
2. Install firmware (`/lib/firmware/hgicf.bin` or module parameter `fw_file`).
  - `fw_file` should be a filename (not a path).
3. Load module:
   - `insmod ./hgicf.ko` (or `modprobe hgicf` if installed).
4. Verify logs:
   - `dmesg | tail -n 200`
5. Verify interface + wireless stack:
   - `ip link`
   - `iw dev`
   - `iwlist scan` (or target-specific scan command)
6. Optional sanity with test utilities:
   - `tools/test_app/*`

Firmware-download failure branch (execute only when needed):
- USB path: try enabling `CONFIG_USB_ZERO_PACKET` for hosts that fail on zero-length packet handling.
- SDIO path: if transfer succeeds but command phase fails (for example cmd4 timeout/fail), tune `bootdl_pktlen` in `utils/if_sdio.c`.

Record pass/fail in a simple matrix table in this document.

---

## 4.1) SDK-Specific Validation Notes

- Some features/commands differ between SDK 1.x and 2.x. Validate according to target SDK profile.
- Roaming standard-protocol behavior has documented limitations on SDK V2.x.
- Relay/group parameter semantics differ between SDK 1.x and 2.x; verify command expectations before marking failures.

---

## 5) GitHub CI Strategy (Build and Release)

## 5.0) Build Environment Strategy (Native vs Docker)

- Local bring-up phase: Docker is optional. Prefer native/local builds first for faster debug iterations.
- Stabilization/release phase: Docker (or equivalent containerized build image) is recommended to guarantee reproducibility.
- CI/release requirement: use pinned toolchain/container versions for deterministic artifacts across reruns.
- OpenIPC practical constraint: if required SDK/toolchains are not available on GitHub-hosted runners, use self-hosted runners (optionally with Docker preloaded).

Suggested progression:
1. First green builds on required targets using native/local environment.
2. Mirror the exact toolchain into a Docker image and validate binary/module reproducibility.
3. Use that image in CI for build matrix and tagged releases.

---

### Phase A - CI Build Validation
- Add `.github/workflows/build-kernel-matrix.yml`.
- Use matrix entries with explicit fields:
  - kernel_version
  - arch
  - cross_prefix
  - kernel_source_method (headers/tarball/prebuilt image)
- Steps:
  - checkout
  - install toolchain deps
  - fetch/prepare kernel tree (`make defconfig && make modules_prepare` when needed)
  - build module
  - upload artifact: `hgicf-<target>-<kernel>.ko` + build log

### Phase B - Release Publishing
- Trigger on tag (for example `vX.Y.Z`).
- Re-run matrix build or download verified artifacts from prior workflow.
- Publish GitHub Release assets:
  - module `.ko`
  - `sha256sum.txt`
  - per-target build log
  - compatibility notes

### Practical note for OpenIPC targets
- OpenIPC toolchains and kernel trees may not be available by default in GitHub-hosted runners.
- If licensing/network constraints exist, use self-hosted runner or a container image with SDK preinstalled.

---

## 6) Acceptance Criteria

Build:
- `hgicf.ko` builds without compile errors for each matrix target and intended interface variant (SDIO/USB).

Runtime:
- Module loads on each target device and requests firmware successfully.
- Firmware-loader preflight checks pass (or are documented with target-specific workaround).
- Basic interface bring-up and scan path work.
- Observed behavior matches the declared SDK profile (1.x or 2.x) for tested commands/features.

Release:
- GitHub release contains one artifact set per supported kernel target.
- Build metadata is traceable (commit SHA, kernel version, toolchain version).

---

## 7) Immediate Next Actions

1. Apply the `ndo_do_ioctl` -> `ndo_siocdevprivate` compatibility patch.
2. Add a local script (`scripts/build-matrix-local.sh`) to run all target builds and log outputs.
3. Add initial GitHub Actions workflow with 2 required targets first:
   - 4.9.84 OpenIPC
   - 6.1.141 Rockchip
4. Add troubleshooting playbook entries for USB zero-packet and SDIO `bootdl_pktlen` tuning.
5. Expand matrix to 6.6/6.12 after first two are green.

_Updated:_ 2026-04-11
