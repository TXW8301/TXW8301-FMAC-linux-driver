# TXW8301 FMAC AT Commands — User Guide

Source: TX_AH_SDK_2.4 / TXW8301_FMAC-v2.4.1.5-40938  
Driver: taixin-fmac-linux-driver-v2.2.1-41305

## How AT Commands Work on Linux

The FMAC Linux driver does **not** expose AT commands directly over a serial port.
Instead, AT commands are tunneled to the TXW8301 firmware through the `hgpriv` iwpriv interface using the `atcmd` set parameter.

### Basic syntax

```bash
hgpriv hg0 set atcmd=AT+<COMMAND>=<args>
```

The driver function `hgic_fwctrl_set_atcmd()` auto-prepends `at+` if you omit it.
Both of these are equivalent:

```bash
hgpriv hg0 set atcmd=AT+VERSION
hgpriv hg0 set atcmd=version         # driver prepends "at+"
```

### Query syntax

Several AT commands support `?` to read the current value:

```bash
hgpriv hg0 set atcmd=AT+SSID?
hgpriv hg0 set atcmd=AT+RSSI?
```

### Response

AT command responses are returned via firmware debug output (dbginfo).
Enable debug info first to see responses:

```bash
hgpriv hg0 set dbginfo=1
```

---

## 1. System & Maintenance

### Check firmware version
```bash
hgpriv hg0 set atcmd=AT+VERSION
```
Returns firmware version, SVN revision, and build info.

### Software reset
```bash
hgpriv hg0 set atcmd=AT+RST
```
Triggers a firmware restart on the module.

### Load default configuration
```bash
hgpriv hg0 set atcmd=AT+LOADDEF
```
Restores factory defaults. Requires reset to take effect.

### Set debug flags
```bash
hgpriv hg0 set atcmd=AT+SYSDBG=heap,1    # Enable heap debug
hgpriv hg0 set atcmd=AT+SYSDBG=lmac,2    # LMAC summary info
hgpriv hg0 set atcmd=AT+SYSDBG=umac,1    # UMAC info (SDK V2.x)
hgpriv hg0 set atcmd=AT+SYSDBG=irq,1     # IRQ debug
```

### Dump system configuration
```bash
hgpriv hg0 set atcmd=AT+SYSCFG
```

---

## 2. Wi-Fi Setup

### Set SSID
```bash
hgpriv hg0 set atcmd=AT+SSID=MyNetwork
```

### Query current SSID
```bash
hgpriv hg0 set atcmd=AT+SSID?
```

### Set PSK
```bash
hgpriv hg0 set atcmd=AT+PSK=mypassword123
```

### Set encryption mode
```bash
hgpriv hg0 set atcmd=AT+ENCRYPT=WPA2
```

### Set Wi-Fi mode (STA/AP/WNB)
```bash
hgpriv hg0 set atcmd=AT+WIFIMODE=sta
hgpriv hg0 set atcmd=AT+WIFIMODE=ap
```

### Set channel
```bash
hgpriv hg0 set atcmd=AT+CHANNEL=1
```

### Set BSS bandwidth
```bash
hgpriv hg0 set atcmd=AT+BSS_BW=4
```

### Configure channel list
```bash
hgpriv hg0 set atcmd=AT+CHAN_LIST=1,2,3,5
```

### Trigger scan
```bash
hgpriv hg0 set atcmd=AT+SCAN
```

### Start pairing
```bash
hgpriv hg0 set atcmd=AT+PAIR
```

### Remove pairing
```bash
hgpriv hg0 set atcmd=AT+UNPAIR
```

### Hide AP SSID
```bash
hgpriv hg0 set atcmd=AT+APHIDE=1
```

### Enable roaming
```bash
hgpriv hg0 set atcmd=AT+ROAM=1
```

---

## 3. Link Status & Monitoring

### Read RSSI
```bash
hgpriv hg0 set atcmd=AT+RSSI?
```

### Read station info
```bash
hgpriv hg0 set atcmd=AT+STA_INFO
```

### Read/set MAC address
```bash
hgpriv hg0 set atcmd=AT+MAC_ADDR?
```

---

## 4. Network Diagnostics

### Ping
```bash
hgpriv hg0 set atcmd=AT+PING=192.168.1.1,10,64   # host, count, size
```
Requires `SYS_NETWORK_SUPPORT` and `LWIP_RAW` compile flags.

### iPerf2 throughput test
```bash
hgpriv hg0 set atcmd=AT+IPERF2
```

### ICMP monitor
```bash
hgpriv hg0 set atcmd=AT+ICMPMNTR=0,1    # ifindex=0, enable=1
```

---

## 5. Repeater (requires WIFI_REPEATER_SUPPORT)

### Set upstream credentials
```bash
hgpriv hg0 set atcmd=AT+R_SSID=UplinkAP
hgpriv hg0 set atcmd=AT+R_PSK=uplinkpassword
```

---

## 6. Power Management

### Enable/disable sleep
```bash
hgpriv hg0 set atcmd=AT+SLEEP_EN=1
hgpriv hg0 set atcmd=AT+SLEEP_EN=0
```

### Deep sleep
```bash
hgpriv hg0 set atcmd=AT+DSLEEP=1
```
Requires `CONFIG_SLEEP` compile flag.

### AP power-save mode
```bash
hgpriv hg0 set atcmd=AT+AP_PSMODE=1
```

### Wakeup a station
```bash
hgpriv hg0 set atcmd=AT+WAKEUP
```

### Radio on/off
```bash
hgpriv hg0 set atcmd=AT+RADIO_ONOFF=1    # Turn on
hgpriv hg0 set atcmd=AT+RADIO_ONOFF=0    # Turn off
```

---

## 7. TX Power

### Set TX power
```bash
hgpriv hg0 set atcmd=AT+TXPOWER=20
```

### Auto TX power
```bash
hgpriv hg0 set atcmd=AT+TX_PWR_AUTO=1
```

### Max TX power limit
```bash
hgpriv hg0 set atcmd=AT+TX_PWR_MAX=30
```

---

## 8. RF Test & Calibration (Lab/Factory Use)

> **Warning:** These commands can destabilize runtime. Use only in test environments.

### Enter RF test mode
```bash
hgpriv hg0 set atcmd=AT+TEST_START
```

### Start continuous TX
```bash
hgpriv hg0 set atcmd=AT+TX_CONT=1
```

### Set TX MCS for test
```bash
hgpriv hg0 set atcmd=AT+TX_MCS=7
```

### CW transmit (carrier wave)
```bash
hgpriv hg0 set atcmd=AT+TX_CW=1
```

### Read RX metrics
```bash
hgpriv hg0 set atcmd=AT+RX_RSSI
hgpriv hg0 set atcmd=AT+RX_EVM
hgpriv hg0 set atcmd=AT+RX_AGC
hgpriv hg0 set atcmd=AT+RX_ERR
hgpriv hg0 set atcmd=AT+RX_PKTS
```

### Read temperature
```bash
hgpriv hg0 set atcmd=AT+T_SENSOR
```

---

## 9. Register Access (Low-Level Debug)

> **Warning:** Direct register writes can brick the module.

### Read register
```bash
hgpriv hg0 set atcmd=AT+REG_RD=0x40000000
```

### Write register
```bash
hgpriv hg0 set atcmd=AT+REG_WT=0x40000000,0x01
```

---

## 10. Alternative: Direct iwpriv Commands

Many AT command functions have direct iwpriv equivalents that bypass the AT parser.
Use the direct iwpriv path when available — it is faster and returns structured data.

```bash
# These are equivalent:
hgpriv hg0 set atcmd=AT+SSID=MyNetwork    # Via AT passthrough
hgpriv hg0 set ssid=MyNetwork              # Direct iwpriv (preferred)
```

See TXW8301_FMAC-AT_IWPRIV_MAPPING.md for the full cross-reference.

---

## Response and Error Model

| Response | Meaning |
|---|---|
| OK | Command executed successfully |
| ERROR | Argument validation failed or command rejected |

Monitor firmware output with:

```bash
hgpriv hg0 set dbginfo=1
cat /proc/hgicf/fwevnt
```
