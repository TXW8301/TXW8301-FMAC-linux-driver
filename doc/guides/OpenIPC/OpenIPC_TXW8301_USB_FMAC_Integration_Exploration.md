# TXW8301 FMAC USB Integration — OpenIPC Exploration

**Driver package:** `taixin-fmac-linux-driver-v2.2.1-41305` (SVN 41305)  
**Board:** TAIXIN-AH-Rx00P_EVB_V1.7  
**Interface:** USB (native TXW8301 USB device → OpenIPC USB host)  
**Status:** Pre-bringup planning / exploration  
**Date:** 2026-04-24

---

## 1. Motivation vs SDIO Path

SDIO bringup on GK7205V300 is already confirmed working (see
[OpenIPC_GK7205V300_Linux_4.9.37_TXW8301_SDIO_Bringup.md](OpenIPC_GK7205V300_Linux_4.9.37_TXW8301_SDIO_Bringup.md)).
USB integration offers several practical advantages:

| | SDIO | USB |
|---|---|---|
| Physical wiring | 6+ signals (CLK, CMD, DAT0–3, GND) direct-wired | Single USB-A cable |
| Signal integrity | Sensitive to lengths/floating lines; -EILSEQ from bad wiring | Differential pair, hardware error correction |
| Host kernel config | Requires `CONFIG_MMC`, `CONFIG_MMC_SDHCI`, platform mmc driver | Requires `CONFIG_USB_EHCI_HCD` or `CONFIG_USB_OHCI_HCD` + host driver |
| Boot order | Camera must boot after TF slot enumeration | Module must enumerate on USB bus (similar dependency) |
| Driver build target | `make fmac_sdio` (`CONFIG_HGIC_SDIO=y`) | `make fmac_usb` (`CONFIG_HGIC_USB=y`) |
| Firmware | Pre-built SDIO binary available | **Must build from SDK** |
| Power | EVB powered separately via USB power connector | Same |

---

## 2. EVB V1.7 USB Hardware

### 2.1 Two USB connectors — distinct functions

The EVB V1.7 has **two** USB connectors:

| Connector | Type | Function |
|-----------|------|----------|
| Power-Input / Print-Port | USB micro or Type-C | 5V power input + CH340 serial (debug/AT) |
| **USB** (data connector) | USB Type-C or Type-A | **Native TXW8301 USB D+/D− data interface** |

> Source: [Taixin AH Module Development Board Guide v1.4](../../../official/)  
> "USB: Used for communication with the host controller via USB interface"

The native USB data connector carries the TXW8301's own USB peripheral signals and is the
connector to use when operating in USB FMAC mode.

### 2.2 UART debug jumper for USB firmware

The serial debug UART output pin mapping differs by firmware type:

| Firmware type | CH340 connects to | UART jumper position |
|---------------|-------------------|---------------------|
| SDIO / SPI | A12 / A13 | Short A12/A13 to middle row |
| **USB** | **A10 / A11** | **Short A10/A11 to middle row** |
| UART (bus) | A12/A13 = debug; A10/A11 = bus comms | Short A12/A13 + external wire A10/A11 |

> Source: Development Board Guide, UART Jumper section.

When loading USB firmware, **move the UART jumper to A10/A11** before debug sessions.

### 2.3 R28 power pad (V1.6 note, applicable to V1.7)

For USB / UART / SPI interface: **R28 must be populated** (0Ω short) to power IOA6–11 rails.
For SDIO: R28 should be open (SVCC power supplied from host TF slot).

On EVB V1.7 with the SVCC jumper: set SVCC to VCC (external power from USB connector)
rather than pulling power from a host TF slot. This is already the normal operating condition
for USB mode since there is no TF slot connection.

**Verify R28 is shorted on your specific EVB V1.7 board when using USB firmware.**

---

## 3. Firmware Build (USB)

### 3.1 Pre-built binary availability

> `Firmware and Utilities/AH-EVB-firmware/changelog.txt` line 2:  
> "本固件是SDIO接口固件（也是SPI接口固件）；**USB和UART接口固件，请用SDK编译产生**"  
> (This firmware is the SDIO interface firmware; USB and UART interface firmware must be
> compiled from the SDK.)

**No pre-built USB firmware is provided.** USB firmware must be compiled from:
`SDK/TX_AH_SDK_2.4/FMAC/TXW8301_FMAC-v2.4.1.5-40938`

### 3.2 project_config.h changes

In `SDK/TX_AH_SDK_2.4/FMAC/TXW8301_FMAC-v2.4.1.5-40938/project/project_config.h`:

```c
// Before (SDIO default):
#define MACBUS_SDIO
//#define MACBUS_USB

// After (USB):
//#define MACBUS_SDIO
#define MACBUS_USB
```

The `sys_config.h` selects `MAC_BUS_TYPE_USB` when `MACBUS_USB` is defined, and
`ATCMD_UARTDEV` defaults to `HG_UART0_DEVID` (the A10/A11 pins) for USB firmware.

### 3.3 Build output

Use the Taixin SDK toolchain (CDK IDE or command-line) to build. The output binary is:
`project/Output/txw8301_vX.Y.Z-NNNNN_<date>_default-USB.bin`

Deploy to the OpenIPC camera at `/lib/firmware/hgicf.bin`.

---

## 4. Linux Driver Build (USB)

### 4.1 Build target

```bash
cd ~/TXW8301/Driver/taixin-fmac-linux-driver

make fmac_usb \
  ARCH=arm \
  COMPILER=arm-linux-gnueabihf- \
  LINUX_KERNEL_PATH=$HOME/openipc/openipc-firmware/output/build/linux-custom \
  CONFIG_HGIC_AH=y \
  CFLAGS_MODULE="-march=armv7-a"
```

The `fmac_usb` target passes only `CONFIG_HGIC_USB=y` (no `CONFIG_HGIC_SDIO`), producing
a USB-only `ko/hgicf.ko`. The same `CONFIG_HGIC_AH=y` flag is required for 802.11ah mode.

### 4.2 USB device table

From `utils/if_usb.c`:

```c
static const struct usb_device_id hgic_usb_wdev_ids[] = {
    { USB_DEVICE(0xA012, 0x4002) },
    { USB_DEVICE(0xA012, 0x4104) },
    { USB_DEVICE(0xA012, 0x8400) },
    { /* end */ },
};
```

When the TXW8301 USB firmware enumerates on the host, the kernel will bind `hgicf.ko`
to one of these VID:PID combinations.

### 4.3 Verify vermagic (same requirement as SDIO)

```bash
modinfo ko/hgicf.ko | grep vermagic
# Must match the target OpenIPC camera's running kernel exactly
```

---

## 5. OpenIPC Host Board Requirements

### 5.1 USB host prerequisite

The target OpenIPC camera must have a **USB 2.0 host controller** (EHCI or OHCI) enabled
in its kernel config and accessible physically. Not all IP camera PCBs expose USB host pins
externally even if the SoC supports it.

Requirements checklist:
- [ ] SoC has USB host controller (most modern IPC SoCs do: GK7205V300, HI3516EV300, T31, SSC33x)
- [ ] OpenIPC kernel build has `CONFIG_USB=y` and the appropriate host controller driver enabled
- [ ] Physical USB-A or USB host pads accessible on the camera board
- [ ] 5V VBUS available on the host USB port (or EVB powered separately — recommended)

### 5.2 GK7205V300 (XM IVG-G5F) — existing test platform

The GK7205V300 SoC includes a USB 2.0 host controller. Whether the XM IVG-G5F camera board
physically exposes USB host remains to be verified:

- **To check**: `lsmod` or `dmesg | grep -i usb` on the running OpenIPC camera to see if
  `usb-storage`, `ehci-hcd`, or similar USB host stack is loaded.
- **To check**: Look for USB-A connector or USB pad on the PCB.
- `cat /proc/bus/usb/devices` or `lsusb` (if available) after loading kernel USB driver.

If the GK7205V300 USB host is accessible, this becomes the simplest path since the kernel
source tree is already known-good.

### 5.3 Other OpenIPC boards with accessible USB host

Boards commonly seen in OpenIPC community with confirmed USB host:

| SoC | Board example | USB notes |
|-----|--------------|-----------|
| GK7205V300 | XM IVG-G5F | USB host in SoC; physical exposure TBD |
| HI3516EV300 | Various XM boards | USB host exposed on some boards |
| Ingenic T31 | Various | USB OTG, can operate as host |
| SigmaStar SSC335 | Various | USB host in SoC |

> **Action required**: Confirm which OpenIPC board you are targeting before proceeding with
> a full bringup.

---

## 6. Physical Setup

```
OpenIPC camera board
  USB-A host port (or USB pads)
        │
        │ USB cable (host ↔ device)
        │
EVB V1.7 native USB data connector (TXW8301 USB D+/D−)
        │
        ├── Power: USB power connector (separate, from PC or USB adapter, 5V@500mA)
        ├── Debug UART: Power/print port (CH340) → jumper at A10/A11
        └── SVCC jumper: set to VCC (external power, not from host)
```

Key differences from SDIO setup:
- No multi-wire harness — single USB cable for data
- No TF card slot needed on the camera board
- EVB still needs separate 5V power (unless camera USB port provides VBUS and is ≥500mA)

---

## 7. Driver Load and Verify Sequence

Once firmware and driver are built and deployed:

```bash
# 1. Power on EVB first, wait for USB firmware to initialise
#    (serial monitor at A10/A11, 115200 baud)

# 2. Plug USB data cable between EVB and camera USB host port

# 3. On camera: verify USB enumeration
dmesg | grep -E 'usb|a012' | tail -20
# Expect: "New USB device found, idVendor=a012, idProduct=4002" (or 4104/8400)

# 4. Load module
insmod /tmp/hgicf.ko

# 5. Verify probe
dmesg | grep -E 'hgic|hg0' | tail -20

# 6. Check interface
ip link show hg0
```

The firmware download sequence is identical to SDIO: `hgicf_download_fw()` sends
`hgicf.bin` over the USB bulk endpoint if the module is in boot state.

---

## 8. Configuration

`/etc/hgicf.conf` format is identical to SDIO. The driver reads this via
`hgicf_load_config()` regardless of bus type.

```ini
freq_range=9080,9240,8
bss_bw=8
tx_mcs=255
chan_list=9080,9160,9240
key_mgmt=WPA-PSK
wpa_psk=12345678
ssid=HALOW_6A7E48
mode=sta
dhcpc=1
```

---

## 9. Known Unknowns / Open Items

| Item | Status |
|------|--------|
| Target OpenIPC board selection | **Must decide before proceeding** |
| GK7205V300 USB host physical access on XM IVG-G5F | Unverified — check PCB and dmesg |
| OpenIPC kernel USB host config for target board | Verify `CONFIG_USB=y` etc. in `.config` |
| USB firmware binary build from SDK | Not yet done — requires SDK toolchain |
| TXW8301 USB PID that enumerates (4002 vs 4104 vs 8400) | Will be seen at enumeration time |
| R28 pad populated on specific EVB V1.7 unit | Verify visually on board |
| Boot/enumeration timing (USB vs SDIO) | To be characterised on first attempt |

---

## 10. Next Steps

1. **Decide target board**: Confirm USB host accessibility on the OpenIPC camera you have.
2. **Verify USB host on camera**: Boot OpenIPC, run `dmesg | grep -i ehci` and check for USB-A port.
3. **Build USB firmware**: In `SDK/TX_AH_SDK_2.4/FMAC/TXW8301_FMAC-v2.4.1.5-40938/project/project_config.h`, swap `MACBUS_SDIO` → `MACBUS_USB`, rebuild SDK.
4. **Build USB driver**: `make fmac_usb ...` using the known-good OpenIPC kernel tree.
5. **Set EVB jumper**: Move UART debug jumper from A12/A13 to A10/A11.
6. **Verify R28**: Confirm 0Ω short is present on your EVB unit.
7. **First bringup**: Follow the sequence in Section 7.
8. **Document results**: Record USB PID seen, dmesg output, and any timing requirements in this file.
