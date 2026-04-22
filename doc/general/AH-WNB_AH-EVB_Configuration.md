# AH-WNB and AH-EVB 802.11ah Configuration

## Overview

This guide documents the configuration required to connect a TXW8301 FMAC device
(STA, e.g. OpenIPC camera with `hgicf.ko`) to a TXW8301 WNB bridge module (AP)
over 802.11ah HaLow using SDK V2.4.

---

## System Roles

| Device | Role | Interface | SDK |
|--------|------|-----------|-----|
| AHR900A_GMAC_38x38_V2.1 (RMII WNB module) | AP | Ethernet bridge (`w0`) | hgSDK-v2.4.1.3-40938 |
| OpenIPC GK7205V300 camera | STA | `hg0` (SDIO FMAC) | FMAC v2.4.1.5-40938 |

**Compatibility rule:** FMAC and WNB must both be on V2.x. V1.x and V2.x are incompatible.

---

## AH-WNB AP Configuration (V2.4 Defaults After LOADDEF)

The WNB module runs ACS (auto channel selection) on boot. With 915 MHz region
and 8 MHz BW, ACS selects among 908 / 916 / 924 MHz.

| Parameter | Value |
|-----------|-------|
| SSID | `HALOW_<MAC3><MAC4><MAC5>` (last 3 MAC bytes, uppercase hex) |
| Password | `12345678` |
| Security | WPA2-PSK |
| BW | 8 MHz |
| ACS candidates | 908, 916, 924 MHz |
| DHCP server | Enabled on Ethernet side only; DHCP client on 802.11ah STA side |

To read current WNB config via UART (`/dev/ttyACM0`, 115200 baud):
```
AT+GET_SSID
AT+GET_BSS_BW
AT+GET_CHAN
```

---

## AH-EVB (FMAC STA) Configuration

Driver config file: `Driver/taixin-fmac-linux-driver-v2.2.1-41305/hgicf.conf`

Deployed to camera at: `/etc/hgicf.conf`

### hgicf.conf

```ini
freq_range=9080,9240,8
bss_bw=8
tx_mcs=255
chan_list=9080,9160,9240
key_mgmt=WPA-PSK
wpa_psk=12345678
ssid=HALOW_<WNB_MAC_SUFFIX>
mode=sta
dhcpc=1
```

**Key parameters explained:**

| Parameter | Value | Notes |
|-----------|-------|-------|
| `freq_range` | `9080,9240,8` | Scan range 908–924 MHz in 8 MHz steps |
| `bss_bw` | `8` | Must match AP bandwidth exactly |
| `chan_list` | `9080,9160,9240` | All three ACS candidates; camera scans all |
| `key_mgmt` | `WPA-PSK` | Must match AP; V2.4 default is WPA2 |
| `wpa_psk` | `12345678` | V2.4 WNB default passphrase |
| `ssid` | `HALOW_<WNB_MAC_SUFFIX>` | Replace with actual last-3-byte MAC suffix |
| `mode` | `sta` | Camera is always STA |
| `dhcpc` | `1` | Hint only; run `udhcpc -i hg0` manually on Linux |

### Common Mistakes to Avoid

| Mistake | Symptom |
|---------|---------|
| `bss_bw` mismatch (e.g. 4 vs 8) | Association timeout |
| Wrong SSID (placeholder left in) | Scan finds nothing |
| `key_mgmt=NONE` when AP uses WPA2 | 4-way handshake failure |
| `chan_list` not covering ACS result | Association timeout |
| V1.6 WNB + V2.4 FMAC | Association timeout (version incompatibility) |

---

## Deploying Config to Camera

SCP is not available on OpenIPC. Use pipe over SSH:

```bash
cat Driver/taixin-fmac-linux-driver-v2.2.1-41305/hgicf.conf | \
  ssh root@<camera_eth_ip> "cat > /etc/hgicf.conf"
```

### Reload Driver

```bash
ssh root@<camera_eth_ip> \
  "rmmod hgicf && sleep 1 && insmod /tmp/hgicf.ko && sleep 5 && ip link set hg0 up && ip addr show hg0"
```

### Obtain IP on HaLow Interface

The `dhcpc=1` in hgicf.conf does not automatically trigger a Linux DHCP client.
Run manually after driver loads:

```bash
ssh root@<camera_eth_ip> "udhcpc -i hg0"
```

---

## Verifying the Link

### From camera UART or SSH

```bash
ifconfig hg0
# Should show inet addr assigned by DHCP
```

### From WNB UART

The periodic LMAC STATUS dump shows connected STAs:
```
STA0: <CAMERA_HALOW_MAC> V2.4
tx0: mcs=*1 snr=XX rssi=XX data=...
```

`AID != 0` and `mode=1` in the camera's LMAC STATUS confirms association.
