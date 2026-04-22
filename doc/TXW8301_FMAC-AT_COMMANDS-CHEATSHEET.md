# TXW8301 FMAC AT Commands — Quick-Reference Cheat Sheet

Source: TX_AH_SDK_2.4 / TXW8301_FMAC-v2.4.1.5-40938  
Driver: taixin-fmac-linux-driver-v2.2.1-41305

All AT commands are sent from the Linux host via:

```
hgpriv hg0 set atcmd=AT+<COMMAND>
```

---

## System & Maintenance

| Command | Description |
|---|---|
| AT+RST | Software reset |
| AT+LOADDEF | Load default config |
| AT+SYSDBG | Set debug flags (key,value) |
| AT+SYSCFG | Dump system config |
| AT+VERSION | Report firmware version |
| AT+FWUPG | Firmware upgrade (xmodem) |
| AT+JTAG | JTAG control (factory) |

## Wi-Fi Setup & Role

| Command | Description |
|---|---|
| AT+SSID | Set/query SSID (max 32 chars) |
| AT+PSK | Set/query PSK |
| AT+KEY | Set/query key material |
| AT+ENCRYPT | Set encryption mode |
| AT+WIFIMODE | Switch STA/AP/WNB mode |
| AT+CHANNEL | Set working channel |
| AT+BSS_BW | Set BSS bandwidth |
| AT+CHAN_LIST | Set/inspect channel list |
| AT+HWMODE | Set PHY profile |
| AT+PAIR | Start pairing/connect |
| AT+UNPAIR | Remove pairing |
| AT+SCAN | Trigger scan |
| AT+APHIDE | AP hidden SSID |
| AT+ROAM | Roaming control |

## Link Status & Station Info

| Command | Description |
|---|---|
| AT+RSSI | Read RSSI (query with ?) |
| AT+STA_INFO | Dump station info |
| AT+MAC_ADDR | Get/set MAC address |

## Network Diagnostics

| Command | Description |
|---|---|
| AT+PING | Ping (host,count,size) |
| AT+IPERF2 | iPerf2 throughput test |
| AT+ICMPMNTR | ICMP monitor (ifindex,enable) |

## Repeater

| Command | Description | Guard |
|---|---|---|
| AT+R_SSID | Upstream SSID | WIFI_REPEATER_SUPPORT |
| AT+R_KEY | Upstream key | WIFI_REPEATER_SUPPORT |
| AT+R_PSK | Upstream PSK | WIFI_REPEATER_SUPPORT |

## Sleep, Wake & Power

| Command | Description |
|---|---|
| AT+SLEEP_EN | Enable/disable sleep |
| AT+DSLEEP | Deep sleep config |
| AT+AP_PSMODE | AP power-save mode |
| AT+AP_SLEEP_MODE | AP sleep mode tuning |
| AT+WAKEUP | Trigger wakeup |
| AT+WAKE_EN | Wake mechanism control |
| AT+PS_CHECK | Power-save diagnostics |
| AT+RADIO_ONOFF | RF on/off |

## TX Power & Analog

| Command | Description |
|---|---|
| AT+TXPOWER | Set/read TX power |
| AT+TX_ATTN | TX attenuation |
| AT+TX_PWR_AUTO | Auto TX power |
| AT+TX_PWR_MAX | Max TX power limit |
| AT+TX_PWR_SUPER | Super power mode |
| AT+TX_PWR_SUPER_TH | Super power threshold |
| AT+TX_PHA_AMP | Phase/amplitude tuning |
| AT+SET_VDD13 | Voltage rail tuning |
| AT+XO_CS | Crystal oscillator cap |
| AT+XO_CS_AUTO | Auto XO calibration |
| AT+LO_FREQ | LO frequency tuning |
| AT+LO_TABLE | Read LO table |
| AT+FT_ATT | Front-end attenuation (not TX4001A) |

## TX PHY/MAC Tuning

| Command | Description |
|---|---|
| AT+TX_BW | TX bandwidth |
| AT+TX_BW_DYNAMIC | Dynamic TX bandwidth |
| AT+TX_MCS | TX MCS index |
| AT+TX_MCS_MAX | Max MCS limit |
| AT+TX_MCS_MIN | Min MCS limit |
| AT+TX_MAX_AGG | Max aggregation |
| AT+TX_MAX_SYMS | Max symbols |
| AT+TX_AGG_AUTO | Auto aggregation |
| AT+TX_RATE_FIXED | Fix TX rate |
| AT+TX_FLAGS | Internal TX flags |
| AT+TX_ORDERED | Ordered TX |
| AT+TX_FC | TX flow control |
| AT+TX_TYPE | Test packet type |
| AT+TX_TRV_PILOT_EN | Pilot test option |
| AT+TX_LEN | Test TX frame length |

## TX Test Controls

| Command | Description |
|---|---|
| AT+TEST_START | Enter RF test mode |
| AT+TX_START | Start TX test |
| AT+TX_STEP | Step TX test |
| AT+TX_TRIG | Trigger TX event |
| AT+TX_CONT | Continuous TX |
| AT+TX_CW | CW transmit mode |
| AT+TX_DELAY | TX delay config |
| AT+TX_CNT_MAX | Max TX count |
| AT+TX_DST_ADDR | TX test dest addr |

## RX & Counters

| Command | Description |
|---|---|
| AT+RX_RSSI | RX RSSI (low-level) |
| AT+RX_EVM | RX EVM |
| AT+RX_AGC | RX AGC state |
| AT+RX_ERR | RX error counters |
| AT+RX_PKTS | RX packet counters |
| AT+RX_REORDER | RX reorder counters |
| AT+TX_PKTS | TX packet counters |
| AT+TX_FAIL | TX failure counters |
| AT+T_SENSOR | Temperature sensor |

## PHY/RF Reset & Channel

| Command | Description |
|---|---|
| AT+PHY_RESET | Reset PHY |
| AT+RF_RESET | Reset RF |
| AT+PRI_CHAN | Set primary channel |
| AT+SHORT_GI | Short GI config |
| AT+SHORT_TH | Short threshold |
| AT+SET_RTS | RTS threshold |
| AT+RTS_DUP | RTS duplicate |
| AT+CTS_DUP | CTS duplicate |
| AT+CCMP_SUPPORT | CCMP toggle |
| AT+TXOP_EN | TXOP enable |

## OBSS/CCA/EDCA/PCF

| Command | Description |
|---|---|
| AT+CCA_OBSV | CCA observation |
| AT+OBSS_CCA_DIFF | OBSS CCA threshold |
| AT+OBSS_NAV_DIFF | OBSS NAV threshold |
| AT+OBSS_SWITCH | OBSS enable |
| AT+OBSS_TH | OBSS threshold |
| AT+OBSS_EDCA | OBSS-aware EDCA |
| AT+EDCA_AIFS | EDCA AIFS |
| AT+EDCA_CW | EDCA contention window |
| AT+EDCA_TXOP | EDCA TXOP limits |
| AT+AP_BACKOFF | AP backoff |
| AT+PCF_EN | PCF enable |
| AT+PCF_PERCENT | PCF percentage |
| AT+PCF_PERIOD | PCF period |

## Register & Factory

| Command | Description |
|---|---|
| AT+REG_RD | Read chip register |
| AT+REG_WT | Write chip register |
| AT+NOR_RD | Read NOR flash |
| AT+BUS_WT | Bus write test |
| AT+SMT_DAT | SMT data access |
| AT+ADC_DUMP | Dump ADC data |
| AT+LMAC_DBGSEL | LMAC debug selector |
| AT+PRINT_PERIOD | Debug print interval |

## Antenna

| Command | Description |
|---|---|
| AT+ANT_DUAL | Dual antenna mode |
| AT+ANT_CTRL | Antenna control |
| AT+ANT_AUTO | Auto antenna select |
| AT+ANT_DEF | Default antenna |

## QA/Factory

| Command | Description |
|---|---|
| AT+QA_ATT | QA attenuation |
| AT+QA_CFG | QA configuration |
| AT+QA_RESULTS | QA results |
| AT+QA_RXTHD | QA RX threshold |
| AT+QA_TXTHD | QA TX threshold |
| AT+QA_START | Start QA test |

## Multicast

| Command | Description |
|---|---|
| AT+MCAST_DUP | Multicast duplicate |
| AT+MCAST_REORDER | Multicast reorder |
| AT+MCAST_BW | Multicast bandwidth |
| AT+MCAST_MCS | Multicast MCS |
| AT+MCAST_RTS | Multicast RTS |

## Misc

| Command | Description |
|---|---|
| AT+CHAN_SCAN | Channel scan test |
| AT+FREQ_LIST | Frequency list |
| AT+ACS_START | Start ACS |
| AT+ACK_TO | ACK timeout tuning |
| AT+RC_NEW | Rate-control hook |
| AT+BGRSSI_MARGIN | Bg RSSI margin |
| AT+BGRSSI_SPUR | Bg RSSI spur handling |
| AT+CS_CNT | Carrier sense counter |
| AT+CS_EN | Carrier sense enable |
| AT+CS_NUM | Carrier sense count |
| AT+CS_PERIOD | Carrier sense period |
| AT+CS_TH | Carrier sense threshold |
| AT+EVM_MARGIN | EVM margin threshold |

## Disabled in Current Build

| Command | Status |
|---|---|
| AT+BSS_BW (test variant) | Commented out |
| AT+LOADDEF (test variant) | Commented out |
| AT+REBOOT | Commented out |
| AT+RX_ADDR_FILTER | Commented out |
| AT+RX_PHY_CHECK | Commented out |
