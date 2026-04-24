# AH-WNB Firmware Update: V1.6 → V2.4

## Overview

This guide documents the procedure for updating the TXW8301 WNB (bridge) firmware
from SDK V1.6 to SDK V2.4 using the XMODEM-over-UART method.

**Required because:** V1.6 and V2.4 are explicitly incompatible
(confirmed in [AH-WNB-firmware/changelog.txt](https://github.com/TXW8301/firmware-and-utilities/blob/main/AH-WNB-firmware/changelog.txt), Ver 35725).

---

## Hardware Setup

| Item | Detail |
|------|--------|
| Module | AHR900A_GMAC_38x38_V2.1 (TXW8301 chip) |
| UART port | `/dev/ttyACM0` at 115200 baud |
| Starting firmware | `hgSDK-v1.6.4.3-31636` |
| Target firmware | `txw8301_v2.4.1.3-40938_2026.3.5_TAIXIN_WNB.bin` |
| Firmware location | [AH-WNB-firmware](https://github.com/TXW8301/firmware-and-utilities/tree/main/AH-WNB-firmware) |

---

## Why the Ethernet OTA Tool Does Not Work on V1.6

The V2.4 driver package includes `tools/test_app/hgota` — a raw Ethernet OTA tool
(EtherType `0x4847`). This tool requires `wnb_ota_init()` to be running on the target
device (`SYS_APP_WNBOTA=1`).

**V1.6 WNB firmware does not include this OTA listener.** Scanning with `hgota scan <iface>`
returns zero devices when the module runs V1.6 firmware.

The `hgota` tool is usable for future updates once the module is on V2.4.

---

## Building the hgota Tool (for Future Use)

The tool has compile errors in the vendor source that must be patched before building.

### Patches Applied to [`tools/test_app/libota.c`](https://github.com/TXW8301/FMAC-linux-driver/blob/main/taixin-fmac-linux-driver-v2.2.1-41305/tools/test_app/libota.c)

1. Add missing include at top of file:
   ```c
   #include <arpa/inet.h>
   ```

2. Add `(char *)` casts on all `LIBOTA.send()` calls (struct pointer → `char *`).

3. Add struct pointer casts in `libota_rx_proc()`:
   ```c
   struct eth_ota_hdr *hdr        = (struct eth_ota_hdr *)buff;
   struct eth_ota_fw_data *data   = (struct eth_ota_fw_data *)buff;
   struct eth_ota_fwparam_hdr *param = (struct eth_ota_fwparam_hdr *)buff;
   ```

4. Add `(int8 *)` cast on `libota_check_sum()` call (line ~226).

### Patches Applied to [`tools/test_app/hgota.c`](https://github.com/TXW8301/FMAC-linux-driver/blob/main/taixin-fmac-linux-driver-v2.2.1-41305/tools/test_app/hgota.c)

Add missing include:
```c
#include "fwinfo.h"
```

### Patch Applied to [`tools/test_app/fwinfo.h`](https://github.com/TXW8301/FMAC-linux-driver/blob/main/taixin-fmac-linux-driver-v2.2.1-41305/tools/test_app/fwinfo.h)

Fix typo in declaration (vendor source has `lenght`):
```c
// Before:
uint32  fwinfo_get_fw_lenght(const uint8 *data, int32 *err_code);
// After:
uint32  fwinfo_get_fw_length(const uint8 *data, int32 *err_code);
```

### Patches Applied to [`tools/test_app/libota.h`](https://github.com/TXW8301/FMAC-linux-driver/blob/main/taixin-fmac-linux-driver-v2.2.1-41305/tools/test_app/libota.h)

Add missing function declarations:
```c
int libota_query_config(char *sta_mac);
int libota_sta_config(char *sta_mac, struct eth_ota_fwparam *param);
int libota_update_config(char *sta_mac, struct eth_ota_fwparam *param);
```

### Build

```bash
# From TXW8301 workspace root:
cd Driver/taixin-fmac-linux-driver-v2.2.1-41305/tools/test_app
# Or from FMAC-linux-driver repo root:
# cd taixin-fmac-linux-driver-v2.2.1-41305/tools/test_app
make hgota
# Binary produced at: tools/test_app/hgota
```

---

## Firmware Update Procedure (XMODEM over UART)

### Prerequisites

```bash
sudo apt install lrzsz minicom
```

### Step 1 — Open minicom

```bash
minicom -D /dev/ttyACM0 -b 115200
```

### Step 2 — Trigger XMODEM upgrade

In the minicom terminal, type:
```
AT+FWUPG
```

The device responds and waits for an XMODEM transfer (sends `C` or NAK).

### Step 3 — Send firmware via minicom file transfer

In minicom: `Ctrl+A` → `S` → select `xmodem` → navigate to and select:
```
Firmware and Utilities/AH-WNB-firmware/txw8301_v2.4.1.3-40938_2026.3.5_TAIXIN_WNB.bin
```

The transfer takes approximately 1–2 minutes. The module flashes and reboots automatically.

### Step 4 — Verify firmware version

After reboot, the UART boot log should show:
```
** hgSDK-v2.4.1.3-40938, app-0, build time:Mar  5 2026 11:40:06 **
```

---

## Post-Update: Reset Configuration (Required)

V1.6 flash config is incompatible with V2.4. If the boot log shows:
```
[1]syscfg: invalid magic_num=0, addr=fe000
```
the old config is still in flash. Send `AT+LOADDEF` to reset to V2.4 defaults:

```bash
echo -e "AT+LOADDEF\r" > /dev/ttyACM0
```

The module reboots. After reboot, `syscfg_read OK!` confirms clean V2.4 config.

---

## V2.4 Default Configuration (After LOADDEF)

| Parameter | Default Value |
|-----------|--------------|
| SSID | `HALOW_XXYYZZ` where `XXYYZZ` = last 3 bytes of MAC in hex |
| Password | `12345678` |
| Security | WPA2-PSK (CCMP) |
| Band | 915 MHz region |
| BW | 8 MHz |
| Channel | ACS (auto-select at boot) |
| Mode | AP |

Example: MAC `ba:9d:14:6a:7e:48` → SSID `HALOW_6A7E48`
