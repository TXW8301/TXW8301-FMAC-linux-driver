# TXW8301 FMAC Driver — OpenIPC GK7205V300 SDIO Bringup

**Driver package:** `taixin-fmac-linux-driver-v2.2.1-41305` (SVN 41305)  
**Target board:** Goke GK7205V300 IP camera running OpenIPC  
**Interface:** SDIO (TF-card slot → AH module dev board v1.6)  
**Date completed:** 2026-04-21

---

## 1. Target Platform

| Item | Value |
|------|-------|
| SoC | Goke GK7205V300 |
| CPU | ARMv7 Cortex-A7 (ARMv7 rev 5) |
| Kernel version | 4.9.37 |
| Kernel config | non-SMP, non-PREEMPT, ARMv7, p2v8 |
| Vermagic string | `4.9.37 mod_unload ARMv7 p2v8` |
| OS | OpenIPC (Buildroot 2024.02.10-g763d9f3) |
| AH module | TXW8301 (TX-AH-Rx00P) on dev board v1.6 |
| SDIO bus | `mmc0` / `10010000.sdhci` |
| SDIO device ID | `vendor=0xa012, device=0x4002, class=0x07` |
| SDIO modalias | `sdio:c07vA012d4002` |

---

## 2. Build Environment (Host)

| Item | Value |
|------|-------|
| Host OS | Linux x86_64 |
| Cross-compiler | `arm-linux-gnueabihf-gcc` |
| Compiler prefix | `arm-linux-gnueabihf-` |
| Kernel source | `~/openipc/openipc-firmware/output/build/linux-custom/` |
| Kernel version in source | 4.9.37 (matches camera exactly) |

The kernel source at `~/openipc/openipc-firmware/output/build/linux-custom/` is the actual
Linux tree that OpenIPC was built from. It is **the only correct tree to use** for building
modules targeting this camera. Do not use vanilla kernel.org tarballs or the patched
`kernel-trees/4.9.84-arm/` tree — struct layouts differ and will cause kernel panics.

### Why other kernel trees fail

Three kernel trees were investigated:

| Tree | Outcome |
|------|---------|
| `kernel-trees/4.9.84-arm` (patched to report 4.9.37) | **Kernel panic on insmod** — struct layout mismatch in `mmc_host`/`mmc_card`; `if_sdio.c` accesses fields directly by offset. Patching `SUBLEVEL` and disabling SMP in `.config` makes vermagic match but does not fix ABI. |
| `kernel-trees/5.10.61-arm` | Builds cleanly; produces `logs/hgicf-5.10.61-arm.ko` — but vermagic mismatch on 4.9.37 camera |
| `kernel-trees/6.1.141-arm64` | Builds cleanly; arm64 — wrong arch for camera |
| `~/openipc/openipc-firmware/output/build/linux-custom/` | **Works.** Vermagic matches. No kernel panic. |

---

## 3. Build Command

```bash
cd ~/TXW8301/Driver/taixin-fmac-linux-driver-v2.2.1-41305

make fmac_sdio \
  ARCH=arm \
  COMPILER=arm-linux-gnueabihf- \
  LINUX_KERNEL_PATH=$HOME/openipc/openipc-firmware/output/build/linux-custom \
  CONFIG_HGIC_AH=y \
  CFLAGS_MODULE="-march=armv7-a"
```

**Why `CONFIG_HGIC_AH=y`:**  
Enables 802.11ah (sub-1 GHz) operating mode. Without this the driver compiles in 2.4/5 GHz
mode which will not work with the TXW8301.

**Why `CFLAGS_MODULE="-march=armv7-a"`:**  
The Makefile defaults to a generic ARM target. The GK7205V300 is Cortex-A7 (ARMv7-A). Without
this flag, the compiler may emit ARMv4/5 code that uses unavailable instructions (e.g., `isb`
in barrier code), causing a build error at link time.

### Output

```
ko/hgicf.ko
```

Verify vermagic matches camera:

```bash
modinfo ko/hgicf.ko | grep vermagic
# vermagic: 4.9.37 mod_unload ARMv7 p2v8
```

---

## 4. Firmware File

The SDIO-SLEEP firmware is used (module enters sleep when idle):

| Item | Value |
|------|-------|
| Source file | `Firmware and Utilities/AH-EVB-firmware/txw8301_v2.4.1.5-40938_2026.3.5_default-SDIO-SLEEP.bin` |
| Deploy path on camera | `/lib/firmware/hgicf.bin` |
| Firmware version | `2.4.1.5`, SVN `38247` |
| Build date | 2026-03-05 |

The driver's firmware loader searches the platform firmware path (`/lib/firmware/`) and loads
the file named by the `fw_file` module parameter (default: `hgicf.bin`). The filename on disk
must match exactly.

---

## 5. Configuration File

Deploy `/etc/hgicf.conf` on the camera. The driver reads this at load time via
`hgicf_load_config()` in `hgic_fmac/core.c`. Without it, the driver logs:

```
hgicf_load_config:138::can not open /etc/hgicf.conf
```

and the event queue fills rapidly with `hgicf_rx_fw_event: event list is full (max 16)` spam
until userspace drains it.

Default config (from `hgicf.conf` in driver root):

```ini
bss_bw=8
tx_mcs=255
chan_list=
key_mgmt=NONE
wpa_psk=
ssid=hgic_ah_test
mode=ap
```

This configures the module as an AP on `ssid=hgic_ah_test`, 8 MHz BW, all MCS, open (no PSK).
Adjust `ssid`, `key_mgmt`, `wpa_psk`, `chan_list`, and `mode` for your use case.

**Config key load order matters.** Apply in this order:
1. Frequency/channel/bandwidth (`freq_range`, `bss_bw`, `chan_list`)
2. Security (`key_mgmt`, `wpa_psk`)
3. Mode last (`mode`)

---

## 6. Deploy and Load Procedure

The following steps assume the camera has already booted and the SDIO card is enumerated.
The module `/tmp/hgicf.ko` is not persistent across reboots; repeat copy+insmod each time until
persistent loading is set up.

### 6.1 Physical power-up order

1. Power on the AH module dev board first (via USB connector, 5V@500mA).
2. Wait for AH module UART to print `SDIO bus init done, ret = 0`.
3. Then power on (or reboot) the camera.

This ensures the TXW8301 is in a known ready state when the camera's mmc controller scans
for SDIO devices. Reversing the order (camera first) can leave the SDIO bus in a bad state
after a previous panic or unexpected reset.

Verify the card enumerated on the camera (dmesg):
```
mmc0: new high speed SDIO card at address 0001
```

### 6.2 Copy files to camera

```bash
# Copy kernel module
cat ko/hgicf.ko | ssh root@<camera_ip> "cat > /tmp/hgicf.ko"

# Copy firmware (only needed if not already present)
cat "../Firmware and Utilities/AH-EVB-firmware/txw8301_v2.4.1.5-40938_2026.3.5_default-SDIO-SLEEP.bin" \
  | ssh root@<camera_ip> "cat > /lib/firmware/hgicf.bin"

# Copy config (only needed once)
cat hgicf.conf | ssh root@<camera_ip> "cat > /etc/hgicf.conf"
```

### 6.3 Load the module

```bash
ssh root@<camera_ip> "insmod /tmp/hgicf.ko"
```

Expected exit code: `0`

### 6.4 Verify probe and firmware download

```bash
ssh root@<camera_ip> "dmesg | grep -E 'hgic|hg0' | tail -20"
```

Expected output (abridged):

```
hgic_sdio_probe:894::new sdio card: vendor:a012, id:4002
hgicf_core_probe:1041::qc_mode=0, no_bootdl=0, if_agg=0, txq_size=1024
hgic_bootdl_init:53::Leave each packet len:32704
hgicf_core_probe:1086::ok
hgic_sdio_enable:847::Enter
hgic_sdio_enable:866::ok
hgic_sdio_probe:938::ok
hgicf_download_fw:760::Enter
hgic fw info:2.4.1.5, svn version:38247, app:0, 82:59:13:5e:9c:18, smt_dat:124092402
hgicf_create_iface:593::Enter
hgicf_create_procfs:294::leave
hgicf_delay_init:855::Leave, ret=28, soft_fc=0
```

Key indicators:
- `new sdio card: vendor:a012, id:4002` — SDIO detected
- `hgic fw info:2.4.1.5` — firmware downloaded successfully
- MAC in dmesg matches AH module UART output (`82:59:13:5e:9c:18`)
- `hgicf_create_procfs: leave` — `/proc/hgicf/*` entries created

### 6.5 Bring up the interface

```bash
ssh root@<camera_ip> "ip link set hg0 up && ip link show hg0"
```

Expected:
```
3: hg0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN qlen 1000
    link/ether 82:59:13:5e:9c:18 brd ff:ff:ff:ff:ff:ff
```

`state UNKNOWN` is normal for SDIO Wi-Fi before association. `LOWER_UP` confirms the SDIO
link to the module is active.

### 6.6 Renew DHCP lease manually for `hg0`
```
udhcpc -i hg0
```

---

## 7. Confirmed Working State

After the successful bringup:

| Check | Result |
|-------|--------|
| `insmod /tmp/hgicf.ko` | exit 0, no crash |
| dmesg — SDIO probe | `vendor:a012, id:4002` |
| dmesg — firmware | `hgic fw info:2.4.1.5, svn:38247` |
| dmesg — netdev | `hgicf_create_iface` completes |
| `ip link show hg0` | `UP,LOWER_UP`, MTU 1500 |
| AH module MAC | `82:59:13:5e:9c:18` |
| `/lib/firmware/hgicf.bin` | Present on camera |
| `/etc/hgicf.conf` | Deployed, driver loads config |
| `/proc/hgicf/` | Exists after insmod |

---

## 8. Known Issues and Workarounds

### 8.1 Kernel panic with wrong kernel tree

**Symptom:** `insmod` succeeded (exit 0) but camera immediately panicked and rebooted.  
**Root cause:** `utils/if_sdio.c` accesses `struct mmc_host` and `struct mmc_card` fields
directly by offset (e.g., `func->card->host->max_blk_size`, `ops->set_ios`). These fields
are at different offsets in the 4.9.84 patched tree vs. the actual 4.9.37 camera kernel.  
**Fix:** Always build against `~/openipc/openipc-firmware/output/build/linux-custom/`.

### 8.2 `__aeabi_unwind_cpp_pr0` unknown symbol

**Symptom:** `insmod` fails with unresolved symbol `__aeabi_unwind_cpp_pr0`.  
**Root cause:** Unwind table sections compiled into the module reference a runtime helper
not exported by the 4.9.37 kernel.  
**Fix (if hit again):** Add `-fno-unwind-tables -fno-asynchronous-unwind-tables` to
`CFLAGS_MODULE`. Not required when building against the correct OpenIPC 4.9.37 source.

### 8.3 SDIO card not enumerated after reboot following panic

**Symptom:** `/sys/bus/sdio/devices/` empty after camera reboots from panic; dmesg shows
no `mmc0: new ... SDIO card`.  
**Root cause:** The TXW8301 was left in an unknown SDIO state by the panic; the 4.9.37 mmc
driver does not re-probe on this platform without a proper power cycle.  
**Fix:** Power cycle the AH module dev board (disconnect USB power for ~5 s), then reboot the camera.

### 8.4 Event queue spam: `event list is full (max 16)`

**Symptom:** dmesg floods with `hgicf_rx_fw_event: event list is full (max 16), drop old event`.  
**Root cause:** The driver's internal event ring is full because no userspace process is
reading `/proc/hgicf/fwevnt`, and `/etc/hgicf.conf` was missing on first load.  
**Fix:** Deploy `/etc/hgicf.conf`. For production, also run `hgpriv` or a daemon that reads
the event file.

### 8.5 `isb` instruction build error

**Symptom:** Build fails with assembler error on `isb` instruction.  
**Root cause:** Default Makefile arch target is too generic (ARMv4/5).  
**Fix:** Pass `CFLAGS_MODULE="-march=armv7-a"` on the make command line.

---

## 9. Next Steps

### 9.1 Persistent loading (manual)

To survive reboots, add to camera's init scripts:

```bash
# On camera
mkdir -p /lib/modules/4.9.37/extra
cp /tmp/hgicf.ko /lib/modules/4.9.37/extra/hgicf.ko
depmod -a
# Add to /etc/modules or an rcS init script:
echo "hgicf" >> /etc/modules
```

`/lib/firmware/hgicf.bin` and `/etc/hgicf.conf` are already in persistent locations and
survive reboots.

### 9.2 Build `ah_tool` / `hgpriv`

The `tools/ah_tool/` directory contains a `build.sh` for the ARMv7 helper binary. Build it
against the same toolchain used for `hgicf.ko`:

```bash
# Approximate (check build.sh for exact flags)
cd tools/ah_tool
CROSS_COMPILE=arm-linux-gnueabihf- ./build.sh
```

Deploy `hgpriv` (or equivalent) to the camera to use runtime `set`/`get` commands via
`/proc/hgicf/iwpriv`.

### 9.3 OpenIPC firmware integration

See [openipc_plan.md](openipc_plan.md) for the plan to integrate this driver as a Buildroot
package in an OpenIPC firmware fork so it is included automatically in the firmware image.

### 9.4 Test RF connectivity

With `hg0` up and the module running AP mode:

1. A second TXW8301 STA device should be able to scan and associate to `ssid=hgic_ah_test`
   on 924 MHz (channel 3), 8 MHz BW.
2. Check `/proc/hgicf/status` for connected STA list.
3. Monitor events: `cat /proc/hgicf/fwevnt`

---

## 10. File Reference

| File | Role |
|------|------|
| `ko/hgicf.ko` | Built module, vermagic `4.9.37 mod_unload ARMv7 p2v8` |
| `hgicf.conf` | Driver config template; deploy to `/etc/hgicf.conf` |
| `hgic_fmac/core.c` | Module init, firmware download, config load, module params |
| `utils/if_sdio.c` | SDIO bus transport; directly accesses `mmc_host`/`mmc_card` structs |
| `kernel-trees/4.9.84-arm/` | Patched vanilla tree — **do not use for camera builds** |
| `logs/build-4.9.84-arm.log` | Build log from patched tree (reference only) |
| `logs/hgicf-5.10.61-arm.ko` | Module built against 5.10.61 (vermagic mismatch for camera) |
| `doc/openipc_plan.md` | Plan for Buildroot/OpenIPC firmware integration |
| `Firmware and Utilities/AH-EVB-firmware/txw8301_v2.4.1.5-40938_2026.3.5_default-SDIO-SLEEP.bin` | Firmware binary → `/lib/firmware/hgicf.bin` |
| `~/openipc/openipc-firmware/output/build/linux-custom/` | **Correct** 4.9.37 kernel source for camera builds |
