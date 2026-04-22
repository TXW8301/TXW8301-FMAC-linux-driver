# RTSP Streaming Test: GK7205V300 + TXW8301 over 802.11ah HaLow

## Overview

End-to-end validation of RTSP video streaming from an OpenIPC GK7205V300 camera
to a host PC via a TXW8301 802.11ah HaLow link through a WNB Ethernet bridge module.

---

## Test Setup

```
[GK7205V300 Camera]
  eth0: <camera_eth_ip>  (wired, management)
  hg0:  <camera_halow_ip> (802.11ah STA, TXW8301 SDIO)
       |
  802.11ah HaLow  916 MHz, 8 MHz BW, WPA2-PSK
       |
[TXW8301 WNB RMII Module]  (AP, hgSDK-v2.4.1.3-40938)
       |
  Ethernet (RMII → RJ45)
       |
[Host PC]  enp3s0: <host_ip>
```

---

## Hardware

| Component | Detail |
|-----------|--------|
| Camera SoC | GK7205V300 |
| Camera OS | OpenIPC, Linux kernel 4.9.37 |
| FMAC driver | `hgicf.ko` v2.2.1-41305 / firmware v2.4.1.5-40938 |
| HaLow interface | `hg0` (SDIO) |
| WNB module | AHR900A_GMAC_38x38_V2.1 (TXW8301), hgSDK-v2.4.1.3-40938 |
| Host NIC | `enp3s0`, same LAN as WNB module |

---

## Link Parameters (Observed)

| Parameter | Value |
|-----------|-------|
| Frequency | 916.0 MHz (ACS selected) |
| Bandwidth | 8 MHz |
| Security | WPA2-PSK (CCMP/CCMP) |
| Camera AID | 1 |
| SNR | 64 dB |
| RSSI (camera rx) | −9 dBm |
| Estimated rate | ~1877 kbps uplink |
| Camera tx MCS | 1 |
| Camera rx MCS | 6 |

---

## RTSP Stream Access

OpenIPC default RTSP paths:

```bash
# Main stream (high resolution)
ffplay rtsp://<camera_halow_ip>:554/stream=0

# Sub stream (lower resolution)
ffplay rtsp://<camera_halow_ip>:554/stream=1
```

---

## Bring-Up Sequence

### 1. Confirm HaLow association

```bash
ssh root@<camera_halow_ip> "ifconfig hg0"
# Must show inet addr
```

### 2. Disable wired Ethernet (optional — power saving test)

```bash
ssh root@<camera_halow_ip> "ip link set eth0 down"
# Access continues via hg0 HaLow link
```

To restore:
```bash
ssh root@<camera_halow_ip> "ip link set eth0 up && udhcpc -i eth0"
```

### 3. Verify reachability over HaLow only

```bash
ping <camera_halow_ip>
ssh root@<camera_halow_ip> "echo HaLow OK"
```

### 4. Play stream

```bash
ffplay rtsp://<camera_halow_ip>:554/stream=0
```

---

## Troubleshooting

### hg0 UP but no IP address

`dhcpc=1` in `hgicf.conf` is a driver hint, not a Linux DHCP trigger. Run manually:
```bash
ssh root@<camera_eth_ip> "udhcpc -i hg0"
```

### Association timeout after config change

Reload the driver after pushing updated `hgicf.conf`:
```bash
ssh root@<camera_eth_ip> \
  "rmmod hgicf && sleep 1 && insmod /tmp/hgicf.ko && sleep 5 && ip link set hg0 up"
ssh root@<camera_eth_ip> "udhcpc -i hg0"
```

### Repeated "pairing success" without AID assignment

The WNB V2.4 firmware requires the FMAC STA to also be on V2.4. If "pairing success"
repeats without `add_STA: aid=X` appearing, check for SDK version mismatch.

### CCMP errors during 4-way handshake

Transient `lmac error!!!ccmp_err` during handshake is normal and self-resolves.
Association completes once `WPA: Key negotiation completed` appears in the WNB log.

---

## Notes

- Streaming is unicast RTSP over TCP; the HaLow link handles ~900 kbps sustained
  comfortably at MCS6 in test conditions.
- The WNB module acts as a transparent L2 bridge — the camera's `hg0` IP is on the
  same subnet as the wired LAN, assigned by the LAN DHCP server.
- The RMII module's built-in DHCP client (`dhcp done, ip:192.168.1.168`) is for its
  own Ethernet management interface, not related to the camera's HaLow IP.
