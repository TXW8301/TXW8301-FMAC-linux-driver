# TXW8301 FMAC AT Commands — Quick-Reference Cheat Sheet

Source: TX_AH_SDK_2.4 / TXW8301_FMAC-v2.4.1.5-40938  
Driver: taixin-fmac-linux-driver-v2.2.1-41305

---

## Serial Terminal — Line Ending Setup

The AT command parser on the device waits for `\r` or `\n` (5 ms idle timeout on UART1 at 115200 baud).
Each terminal tool behaves differently:

| Tool | Sends | Works? | Fix |
|---|---|---|---|
| VS Code Serial Monitor | `\n` | ✓ out of the box | None needed |
| `picocom` | `\n` only by default | ✗ unless fixed | Add `--omap crcrlf` (see below) |
| `minicom` | `\r` | sometimes | Press **Ctrl-A → U** inside minicom to toggle "Add LF"; **Ctrl-A → E** for local echo |
| `screen` | `\r` | sometimes | Inside screen: **Ctrl-A → `:defcr on`** |

**Recommended: `picocom`** — simplest, no menu config needed:

```bash
sudo apt install picocom
picocom -b 115200 --omap crcrlf /dev/ttyACM4
```

`--omap crcrlf` converts every `\n` you type to `\r\n`, which the device parser reliably detects.

**`minicom` quick fix:**

```bash
minicom -D /dev/ttyACM4 -b 115200
# Inside minicom:
#   Ctrl-A  U  → toggle "Add Carriage Return" (enable LF→CRLF mapping)
#   Ctrl-A  E  → toggle local echo (so you see what you type)
```

**From Linux host via driver (no serial terminal needed):**

```bash
hgpriv hg0 set atcmd=AT+<COMMAND>=<value>
# Example:
hgpriv hg0 set atcmd=AT+SYSDBG=lmac,0
```

---

## System & Maintenance

| Command | Description | Values | Example |
|---|---|---|---|
| AT+RST | Software reset the device | — | `AT+RST` |
| AT+LOADDEF | Load factory default config and reboot | `=1` to apply | `AT+LOADDEF=1` |
| AT+SYSDBG | Control runtime debug output verbosity per subsystem | `=<key>,<level>` — keys: `lmac` `umac` `heap` `top` `irq`; levels: `0`=off `1`=on `2`=verbose (default) | `AT+SYSDBG=lmac,0` — stop LMAC status spam<br>`AT+SYSDBG=lmac,2` — restore default level<br>`AT+SYSDBG=umac,0` — stop UMAC output<br>`AT+SYSDBG=heap,0` — stop heap output<br>`AT+SYSDBG=irq,1` — enable IRQ stats |
| AT+SYSCFG | Dump full system configuration to console | query only | `AT+SYSCFG` |
| AT+VERSION | Report firmware version string | query only | `AT+VERSION` |
| AT+FWUPG | Firmware upgrade via xmodem protocol on UART | starts xmodem receive | `AT+FWUPG` |
| AT+JTAG | JTAG interface control (factory use only) | — | `AT+JTAG` |

## Wi-Fi Setup & Role

| Command | Description | Values | Example |
|---|---|---|---|
| AT+SSID | Set or query SSID (max 32 chars) | `=<ssid>` or `=?` | `AT+SSID=MyNetwork`<br>`AT+SSID=?` |
| AT+PSK | Set or query WPA2 passphrase | `=<passphrase>` or `=?` | `AT+PSK=mypassword123`<br>`AT+PSK=?` |
| AT+KEY | Set raw key material (hex) | `=<hex_key>` | `AT+KEY=0123456789abcdef` |
| AT+ENCRYPT | Set encryption mode | `=OPEN` `=WPA2` `=WPA3` (build-dependent) | `AT+ENCRYPT=WPA2` |
| AT+WIFIMODE | Switch Wi-Fi operational mode | `=STA` `=AP` `=WNBAP` `=WNBSTA` | `AT+WIFIMODE=STA`<br>`AT+WIFIMODE=AP` |
| AT+CHANNEL | Set working channel number | `=<ch>` or `=?`; `0` = ACS auto-select | `AT+CHANNEL=6`<br>`AT+CHANNEL=0` |
| AT+BSS_BW | Set BSS bandwidth in MHz | `=1` `=2` `=4` `=8` | `AT+BSS_BW=2` |
| AT+CHAN_LIST | Set or inspect channel scan list | `=<ch1>,<ch2>,...` or `=?` | `AT+CHAN_LIST=1,2,3,4,5,6` |
| AT+HWMODE | Set PHY hardware profile | device-specific integer | `AT+HWMODE=0` |
| AT+PAIR | Start pairing / trigger connection | — | `AT+PAIR` |
| AT+UNPAIR | Remove stored pairing info | — | `AT+UNPAIR` |
| AT+SCAN | Trigger a Wi-Fi active scan | — | `AT+SCAN` |
| AT+APHIDE | Toggle AP hidden SSID (beacon suppression) | `=0` visible `=1` hidden | `AT+APHIDE=1` |
| AT+ROAM | Roaming enable / threshold config | `=0` disable `=1` enable | `AT+ROAM=1` |

## Link Status & Station Info

| Command | Description | Values | Example |
|---|---|---|---|
| AT+RSSI | Read current link RSSI in dBm | `=?` | `AT+RSSI=?` |
| AT+STA_INFO | Dump associated station table (AP mode) | query only | `AT+STA_INFO` |
| AT+MAC_ADDR | Get or set device MAC address | `=?` or `=<XX:XX:XX:XX:XX:XX>` | `AT+MAC_ADDR=?`<br>`AT+MAC_ADDR=0X102030405060` |

## Network Diagnostics

| Command | Description | Values | Example |
|---|---|---|---|
| AT+PING | Send ICMP echo request | `=<host>,<count>,<size>` | `AT+PING=192.168.1.1,4,64` |
| AT+IPERF2 | Run iPerf2 throughput test (client or server) | server: `-s`; client: `-c,<ip>` | `AT+IPERF2=-s`<br>`AT+IPERF2=-c,192.168.1.1` |
| AT+ICMPMNTR | ICMP packet monitor on interface | `=<ifindex>,<0\|1>` | `AT+ICMPMNTR=0,1` |

## Repeater (requires WIFI_REPEATER_SUPPORT build flag)

| Command | Description | Values | Example |
|---|---|---|---|
| AT+R_SSID | Upstream (root AP) SSID to associate with | `=<ssid>` | `AT+R_SSID=UpstreamAP` |
| AT+R_KEY | Upstream AP raw key | `=<key>` | `AT+R_KEY=upstreamkey` |
| AT+R_PSK | Upstream AP WPA2 passphrase | `=<passphrase>` | `AT+R_PSK=upstreampass` |

## Sleep, Wake & Power

| Command | Description | Values | Example |
|---|---|---|---|
| AT+SLEEP_EN | Enable or disable sleep mode | `=0` disable `=1` enable | `AT+SLEEP_EN=0` |
| AT+DSLEEP | Configure deep sleep mode | mode-specific integer | `AT+DSLEEP=1` |
| AT+AP_PSMODE | AP power-save mode selection | `=0` off `=1` on | `AT+AP_PSMODE=1` |
| AT+AP_SLEEP_MODE | Tune AP sleep timing parameters | `=<value>` | `AT+AP_SLEEP_MODE=1` |
| AT+WAKEUP | Trigger an immediate wakeup event | — | `AT+WAKEUP` |
| AT+WAKE_EN | Configure wake-up source mechanism | `=0` disable `=1` enable | `AT+WAKE_EN=1` |
| AT+PS_CHECK | Dump power-save state diagnostics | query only | `AT+PS_CHECK` |
| AT+RADIO_ONOFF | Turn RF transceiver on or off | `=0` off `=1` on | `AT+RADIO_ONOFF=0` |

## TX Power & Analog

| Command | Description | Values | Example |
|---|---|---|---|
| AT+TXPOWER | Set or read TX power level | `=<dBm>` or `=?` | `AT+TXPOWER=20`<br>`AT+TXPOWER=?` |
| AT+TX_ATTN | TX attenuation in dB (floating point) | `=<float>` | `AT+TX_ATTN=6.0` |
| AT+TX_PWR_AUTO | Automatic TX power control | `=0` disable `=1` enable | `AT+TX_PWR_AUTO=1` |
| AT+TX_PWR_MAX | Maximum TX power cap | `=<0..255>` | `AT+TX_PWR_MAX=20` |
| AT+TX_PWR_SUPER | Super (boosted) power mode | `=0` off `=1` on | `AT+TX_PWR_SUPER=1` |
| AT+TX_PWR_SUPER_TH | Super power activation threshold | `=<0..1>` | `AT+TX_PWR_SUPER_TH=0` |
| AT+TX_PHA_AMP | TX phase/amplitude fine-tuning | `=<value>` | `AT+TX_PHA_AMP=1` |
| AT+SET_VDD13 | Adjust 1.3 V supply rail | `=<value>` | `AT+SET_VDD13=1` |
| AT+XO_CS | Crystal oscillator capacitor trim | `=<hex>` or `=?` | `AT+XO_CS=0x8` |
| AT+XO_CS_AUTO | Automatic XO capacitor calibration | `=<hex>` or `=?` | `AT+XO_CS_AUTO=0x8` |
| AT+LO_FREQ | Local oscillator frequency (kHz) | `=<kHz>` or `=?` | `AT+LO_FREQ=930000` |
| AT+LO_TABLE | Read LO calibration table | query only | `AT+LO_TABLE` |
| AT+FT_ATT | Front-end attenuation (not TX4001A) | `=<value>` | `AT+FT_ATT=3` |

## TX PHY/MAC Tuning

| Command | Description | Values | Example |
|---|---|---|---|
| AT+TX_BW | Set TX bandwidth in MHz | `=1` `=2` `=4` `=8` | `AT+TX_BW=2` |
| AT+TX_BW_DYNAMIC | Enable dynamic TX bandwidth negotiation | `=0` off `=1` on | `AT+TX_BW_DYNAMIC=1` |
| AT+TX_MCS | Set TX MCS index | `=0`–`=7`; `=255` = auto | `AT+TX_MCS=3` |
| AT+TX_MCS_MAX | Upper MCS limit for rate control | `=0`–`=7` | `AT+TX_MCS_MAX=7` |
| AT+TX_MCS_MIN | Lower MCS limit for rate control | `=0`–`=7` | `AT+TX_MCS_MIN=0` |
| AT+TX_MAX_AGG | Maximum A-MPDU aggregation count | `=<1..64>` | `AT+TX_MAX_AGG=16` |
| AT+TX_MAX_SYMS | Maximum OFDM symbols per PPDU | `=<value>` e.g. `16` | `AT+TX_MAX_SYMS=16` |
| AT+TX_AGG_AUTO | Automatic aggregation size control | `=0` manual `=1` auto | `AT+TX_AGG_AUTO=1` |
| AT+TX_RATE_FIXED | Fix TX rate (disable adaptive rate control) | `=0` adaptive `=1` fixed | `AT+TX_RATE_FIXED=1` |
| AT+TX_FLAGS | Internal MAC TX flags bitmask | `=<hex>` | `AT+TX_FLAGS=0x80000000` |
| AT+TX_ORDERED | Enforce strict TX frame ordering | `=0` off `=1` on | `AT+TX_ORDERED=1` |
| AT+TX_FC | TX flow control frame type code | `=<hex>` | `AT+TX_FC=0x308` |
| AT+TX_TYPE | TX test payload type | `=N` normal `=S` sine `=T` triangle | `AT+TX_TYPE=N` |
| AT+TX_TRV_PILOT_EN | TX traverse pilot tone enable | `=0` off `=1` on | `AT+TX_TRV_PILOT_EN=1` |
| AT+TX_LEN | TX test frame length in bytes | `=<len>` | `AT+TX_LEN=100` |

## TX Test Controls

| Command | Description | Values | Example |
|---|---|---|---|
| AT+TEST_START | Enter RF test mode | `=1` start `=0` stop | `AT+TEST_START=1` |
| AT+TX_START | Start or stop TX test | `=1` start `=0` stop | `AT+TX_START=1` |
| AT+TX_STEP | Step through TX test sequence | `=<step>` | `AT+TX_STEP=1` |
| AT+TX_TRIG | Trigger a single TX test event | `=0` off `=1` trigger | `AT+TX_TRIG=1` |
| AT+TX_CONT | Continuous TX mode | `=0` off `=1` on | `AT+TX_CONT=1` |
| AT+TX_CW | CW (unmodulated carrier) transmit | `=0` off `=1` on | `AT+TX_CW=1` |
| AT+TX_DELAY | Inter-packet TX delay in ms | `=<ms>` | `AT+TX_DELAY=5` |
| AT+TX_CNT_MAX | Max TX packet count for test | `=<n>,<limit>` | `AT+TX_CNT_MAX=7,31` |
| AT+TX_DST_ADDR | Destination MAC address for TX test | `=<hex_mac>` | `AT+TX_DST_ADDR=0XB0B0B0B0B0B0` |

## RX & Counters

| Command | Description | Values | Example |
|---|---|---|---|
| AT+RX_RSSI | Read raw RX RSSI from PHY layer | `=?` | `AT+RX_RSSI=?` |
| AT+RX_EVM | Read RX EVM (error vector magnitude) | `=?` | `AT+RX_EVM=?` |
| AT+RX_AGC | Read current RX AGC gain state | `=?` | `AT+RX_AGC=?` |
| AT+RX_ERR | Read RX error counters (CRC, MIC, etc.) | `=?` | `AT+RX_ERR=?` |
| AT+RX_PKTS | Read RX packet counters | `=?` | `AT+RX_PKTS=?` |
| AT+RX_REORDER | RX reorder buffer stats | `=?` | `AT+RX_REORDER=?` |
| AT+TX_PKTS | Read TX packet counters | `=?` | `AT+TX_PKTS=?` |
| AT+TX_FAIL | Read TX failure and retry counters | `=?` | `AT+TX_FAIL=?` |
| AT+T_SENSOR | Read on-chip temperature sensor (°C) | `=?` | `AT+T_SENSOR=?` |

## PHY/RF Reset & Channel

| Command | Description | Values | Example |
|---|---|---|---|
| AT+PHY_RESET | Reset the PHY baseband processor | — | `AT+PHY_RESET` |
| AT+RF_RESET | Reset the RF front-end | — | `AT+RF_RESET` |
| AT+PRI_CHAN | Set primary channel offset (1–6) | `=<1..6>` | `AT+PRI_CHAN=1` |
| AT+SHORT_GI | Short Guard Interval enable | `=0` off `=1` on | `AT+SHORT_GI=1` |
| AT+SHORT_TH | Short preamble detection threshold | `=<value>` | `AT+SHORT_TH=10` |
| AT+SET_RTS | RTS/CTS threshold in bytes | `=<bytes>` | `AT+SET_RTS=50` |
| AT+RTS_DUP | RTS frame duplication enable | `=0` off `=1` on | `AT+RTS_DUP=1` |
| AT+CTS_DUP | CTS frame duplication enable | `=0` off `=1` on | `AT+CTS_DUP=1` |
| AT+CCMP_SUPPORT | Toggle CCMP (AES-CCMP) cipher support | `=0` off `=1` on | `AT+CCMP_SUPPORT=1` |
| AT+TXOP_EN | TXOP burst mode enable | `=0` off `=1` on | `AT+TXOP_EN=1` |

## OBSS/CCA/EDCA/PCF

| Command | Description | Values | Example |
|---|---|---|---|
| AT+CCA_OBSV | CCA observation window in seconds | `=<1..128>` | `AT+CCA_OBSV=4` |
| AT+OBSS_CCA_DIFF | OBSS CCA threshold offset (dB) | `=<0..4>` | `AT+OBSS_CCA_DIFF=4` |
| AT+OBSS_NAV_DIFF | OBSS NAV threshold offset | `=<0..1>` | `AT+OBSS_NAV_DIFF=1` |
| AT+OBSS_SWITCH | Enable OBSS detection & mitigation | `=0` off `=1` on | `AT+OBSS_SWITCH=1` |
| AT+OBSS_TH | OBSS RSSI trigger threshold (dBm, negative) | `=<-dBm>` | `AT+OBSS_TH=-30` |
| AT+OBSS_EDCA | OBSS-aware EDCA parameter adjustment | `=0` off `=1` on | `AT+OBSS_EDCA=1` |
| AT+EDCA_AIFS | EDCA AIFS per access class | `=<ac>,<aifs>` AC: 0=BK 1=BE 2=VI 3=VO | `AT+EDCA_AIFS=1,3` |
| AT+EDCA_CW | EDCA contention window per AC | `=<ac>,<cw_min>,<cw_max>` | `AT+EDCA_CW=1,4,10` |
| AT+EDCA_TXOP | EDCA TXOP limit per AC | `=<ac>,<txop>` | `AT+EDCA_TXOP=2,94` |
| AT+AP_BACKOFF | AP EDCA backoff tuning | `=<value>` | `AT+AP_BACKOFF=1` |
| AT+PCF_EN | PCF (Point Coordination Function) enable | `=0` off `=1` on | `AT+PCF_EN=1` |
| AT+PCF_PERCENT | PCF time as % of beacon interval | `=<0..100>` | `AT+PCF_PERCENT=50` |
| AT+PCF_PERIOD | PCF polling cycle period | `=<0..1>` | `AT+PCF_PERIOD=1` |

## Register & Factory

| Command | Description | Values | Example |
|---|---|---|---|
| AT+REG_RD | Read a chip memory-mapped register | `=<hex_addr>` | `AT+REG_RD=0X20000000` |
| AT+REG_WT | Write a chip memory-mapped register | `=<hex_addr>,<hex_val>` | `AT+REG_WT=0X20000000,0x12345678` |
| AT+NOR_RD | Read bytes from NOR flash | `=<addr>` | `AT+NOR_RD=0` |
| AT+BUS_WT | Bus interface write test | `=<0\|1>` | `AT+BUS_WT=1` |
| AT+SMT_DAT | SMT factory data access | `=<value>` | `AT+SMT_DAT=0` |
| AT+ADC_DUMP | Dump raw ADC sample data | — | `AT+ADC_DUMP` |
| AT+LMAC_DBGSEL | Select LMAC internal debug signal output | `=<selector>` | `AT+LMAC_DBGSEL=0` |
| AT+PRINT_PERIOD | LMAC-internal periodic status print interval (ms). **Note:** does NOT silence the main SYSDBG status loop — use `AT+SYSDBG=lmac,0` for that | `=<ms>` (`0` = stop internal LMAC timer) or `=?` | `AT+PRINT_PERIOD=0`<br>`AT+PRINT_PERIOD=5000` |

## Antenna

| Command | Description | Values | Example |
|---|---|---|---|
| AT+ANT_DUAL | Dual antenna mode enable | `=0` off `=1` on | `AT+ANT_DUAL=1` |
| AT+ANT_CTRL | Manual antenna port selection | `=<index>` | `AT+ANT_CTRL=0` |
| AT+ANT_AUTO | Automatic antenna diversity selection | `=0` off `=1` on | `AT+ANT_AUTO=1` |
| AT+ANT_DEF | Set default antenna index | `=<index>` | `AT+ANT_DEF=0` |

## QA/Factory

| Command | Description | Values | Example |
|---|---|---|---|
| AT+QA_ATT | QA attenuation setting | `=<value>` | `AT+QA_ATT=3` |
| AT+QA_CFG | QA test configuration parameters | `=<params>` | `AT+QA_CFG=1` |
| AT+QA_RESULTS | Print QA pass/fail test results | query only | `AT+QA_RESULTS` |
| AT+QA_RXTHD | QA RX pass/fail RSSI threshold | `=<value>` | `AT+QA_RXTHD=10` |
| AT+QA_TXTHD | QA TX pass/fail power threshold | `=<value>` | `AT+QA_TXTHD=10` |
| AT+QA_START | Start QA test sequence | — | `AT+QA_START` |

## Multicast

| Command | Description | Values | Example |
|---|---|---|---|
| AT+MCAST_DUP | Multicast duplicate frame transmission count | `=<n>` or `=?` | `AT+MCAST_DUP=7` |
| AT+MCAST_REORDER | Multicast reorder buffer enable | `=0` off `=1` on | `AT+MCAST_REORDER=1` |
| AT+MCAST_BW | Multicast TX bandwidth in MHz | `=1` `=2` `=4` `=8` | `AT+MCAST_BW=2` |
| AT+MCAST_MCS | Multicast MCS index | `=0`–`=7` | `AT+MCAST_MCS=0` |
| AT+MCAST_RTS | Multicast RTS protection enable | `=0` off `=1` on | `AT+MCAST_RTS=1` |

## Misc

| Command | Description | Values | Example |
|---|---|---|---|
| AT+CHAN_SCAN | Trigger a per-channel scan test | `=0` stop `=1` start | `AT+CHAN_SCAN=1` |
| AT+FREQ_LIST | Dump or set frequency list | `=?` | `AT+FREQ_LIST=?` |
| AT+ACS_START | Start Automatic Channel Selection | — | `AT+ACS_START` |
| AT+ACK_TO | Extra ACK timeout margin in µs | `=<µs>` | `AT+ACK_TO=50` |
| AT+RC_NEW | Select new rate-control algorithm | `=0` legacy `=1` new | `AT+RC_NEW=1` |
| AT+BGRSSI_MARGIN | Background RSSI margin in dB | `=<0..3>` | `AT+BGRSSI_MARGIN=3` |
| AT+BGRSSI_SPUR | Background RSSI spur compensation | `=<0..3>` | `AT+BGRSSI_SPUR=1` |
| AT+CS_CNT | Carrier sense event counter (read) | `=?` | `AT+CS_CNT=?` |
| AT+CS_EN | Carrier sense enable | `=0` off `=1` on | `AT+CS_EN=1` |
| AT+CS_NUM | Carrier sense consecutive hit threshold | `=<0..255>` | `AT+CS_NUM=3` |
| AT+CS_PERIOD | Carrier sense check period in ms | `=<ms>` | `AT+CS_PERIOD=1000` |
| AT+CS_TH | Carrier sense RSSI threshold (dBm, negative) | `=<-dBm>` | `AT+CS_TH=-70` |
| AT+EVM_MARGIN | EVM detection margin threshold | `=<0..3>` | `AT+EVM_MARGIN=3` |

## Disabled in Current Build

| Command | Status |
|---|---|
| AT+BSS_BW (test variant) | Commented out — use system `AT+BSS_BW` instead |
| AT+LOADDEF (test variant) | Commented out — use `AT+LOADDEF=1` |
| AT+REBOOT | Commented out |
| AT+RX_ADDR_FILTER | Commented out |
| AT+RX_PHY_CHECK | Commented out |
