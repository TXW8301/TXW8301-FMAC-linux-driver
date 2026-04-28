# TXW8301 FMAC — AT Command ↔ iwpriv Mapping

Source: TX_AH_SDK_2.4 / TXW8301_FMAC-v2.4.1.5-40938  
Driver: taixin-fmac-linux-driver

## Architecture Overview

The FMAC Linux driver offers two parallel command paths to the TXW8301 firmware:

1. **Direct iwpriv** (`hgpriv hg0 set/get <param>=<value>`)  
   Each parameter maps to a dedicated `HGIC_CMD_*` ID sent in a control frame.

2. **AT passthrough** (`hgpriv hg0 set atcmd=AT+<CMD>`)  
   All AT commands funnel through a single `HGIC_CMD_SET_ATCMD` (ID 115).
   The firmware's AT parser does string matching on the command name.

**Prefer direct iwpriv** when a mapping exists — it returns structured data, is type-safe, and avoids the AT string parsing overhead.

---

## SET Commands: iwpriv → AT Equivalent

| iwpriv set | HGIC_CMD ID | AT Command | Notes |
|---|---|---|---|
| `ssid=<val>` | 4 | AT+SSID | SSID (max 32) |
| `bssid=<mac>` | 5 | — | No AT equiv in table |
| `country_region=<CC>` | 6 | — | 2-char code |
| `channel=<n>` | 7 | AT+CHANNEL | |
| `rts_threshold=<n>` | 9 | AT+SET_RTS | |
| `frag_threshold=<n>` | 10 | — | |
| `key_mgmt=<str>` | 11 | AT+ENCRYPT | Different semantics |
| `wpa_psk=<str>` | 12 | AT+PSK | |
| `bssid_filter=<str>` | 16 | — | |
| `freq_range=<s,e,step>` | 30 | — | |
| `acs=<n>` | 31 | AT+ACS_START | Different trigger |
| `primary_chan=<n>` | 32 | AT+PRI_CHAN | |
| `bgrssi=<n>` | 33 | — | |
| `bss_bw=<n>` | 34 | AT+BSS_BW | |
| `tx_bw=<n>` | 28 | AT+TX_BW | |
| `tx_mcs=<n>` | 29 | AT+TX_MCS | |
| `chan_list=<ch,...>` | 39 | AT+CHAN_LIST | |
| `mode=<str>` | 41 | AT+WIFIMODE | STA/AP/WNB |
| `paired_stas=<macs>` | 42 | — | |
| `pairing=<n>` | 44 | AT+PAIR | |
| `beacon_int=<n>` | 52 | — | |
| `txpower=<n>` | 22 | AT+TXPOWER | |
| `agg_cnt=<tx,rx>` | 60 | AT+TX_MAX_AGG | Partial overlap |
| `radio_onoff=<0/1>` | 65 | AT+RADIO_ONOFF | |
| `ps_connect=<n>` | 70 | — | |
| `bss_max_idle=<n>` | 71 | — | |
| `wkio_mode=<n>` | 72 | — | |
| `dtim_period=<n>` | 73 | — | |
| `ps_mode=<n>` | 74 | — | |
| `loaddef` | 75 | AT+LOADDEF | |
| `disassoc_sta=<mac>` | 76 | — | |
| `aplost_time=<n>` | 77 | — | |
| `unpair` | 79 | AT+UNPAIR | |
| `auto_chswitch=<n>` | 80 | — | |
| `reassoc_wkhost=<n>` | 81 | — | |
| `wakeup_io=<n>` | 82 | — | |
| `dbginfo=<n>` | 83 | AT+SYSDBG | Different scope |
| `sysdbg=<key,val>` | 84 | AT+SYSDBG | Direct match |
| `autosleep_time=<n>` | 85 | — | |
| `super_pwr=<n>` | 88 | AT+TX_PWR_SUPER | |
| `r_ssid=<str>` | 89 | AT+R_SSID | Repeater |
| `r_psk=<str>` | 90 | AT+R_PSK | Repeater |
| `auto_save=<n>` | 91 | — | |
| `pair_autostop=<n>` | 87 | — | |
| `dcdc13=<n>` | 94 | AT+SET_VDD13 | |
| `acktmo=<n>` | 95 | AT+ACK_TO | |
| `pa_pwrctl_dis=<n>` | 97 | — | |
| `dhcpc=<n>` | 98 | — | |
| `wkdata_save=<n>` | 103 | — | |
| `mcast_txparam=<args>` | 105 | — | |
| `reset_sta=<mac>` | 107 | — | |
| `ant_auto=<n>` | 110 | AT+ANT_AUTO | |
| `ant_sel=<n>` | 111 | — | |
| `wkhost_reason=<bytes>` | 113 | — | |
| `macfilter=<n>` | 114 | — | |
| `atcmd=AT+<cmd>` | 115 | **All AT commands** | Passthrough |
| `roaming=<vals>` | 116 | AT+ROAM | |
| `ap_hide=<n>` | 117 | AT+APHIDE | |
| `max_txcnt=<n>` | 119 | — | |
| `assert_holdup=<n>` | 120 | — | |
| `ap_psmode=<n>` | 121 | AT+AP_PSMODE | |
| `dupfilter=<n>` | 122 | — | |
| `dis_1v1m2u=<n>` | 123 | — | |
| `dis_psconnect=<n>` | 124 | — | |
| `rtc=<n>` | 125 | — | |
| `kick_assoc=<n>` | 127 | — | |
| `start_assoc=<n>` | 128 | — | |
| `sleep=<n>` | 46 | AT+SLEEP_EN | Different trigger |
| `reset` | 132 | AT+RST | |
| `user_edca=<args>` | 136 | AT+EDCA_AIFS/CW/TXOP | Granular AT variants |
| `fix_txrate=<n>` | 137 | AT+TX_RATE_FIXED | |
| `nav_max=<n>` | 138 | — | |
| `clr_nav` | 139 | — | |
| `cca_param=<args>` | 140 | AT+CCA_OBSV | Partial overlap |
| `tx_modgain=<args>` | 141 | — | |
| `rts_duration=<n>` | 152 | — | |
| `disable_print=<n>` | 160 | — | |
| `standby=<idx,time>` | 153 | — | |
| `ap_chansw=<n>` | 158 | — | |
| `cca_ce=<n>` | 159 | — | |
| `xosc=<n>` | 169 | AT+XO_CS | |
| `watchdog=<n>` | 165 | — | |
| `retry_fallback_cnt=<n>` | 166 | — | |
| `fallback_mcs=<n>` | 167 | — | |
| `heartbeat=<args>` | 58 | — | |
| `heartbeat_int=<n>` | 58 | — | |
| `wakeup=<mac>` | 67 | AT+WAKEUP | |
| `conn_paironly=<n>` | 154 | — | |
| `diffcust_conn=<n>` | 155 | — | |
| `wait_psmode=<n>` | 157 | — | |
| `apep_padding=<n>` | 161 | — | |
| `freq_cali_period=<n>` | 171 | — | |
| `max_txdelay=<n>` | 173 | — | |
| `sleep_roaming=<en,rssi>` | 188 | — | |
| `roaming_bssid=<mac>` | 193 | — | |
| `bss_disable=<mac,dis>` | 197 | — | |

## GET Commands: iwpriv → AT Equivalent

| iwpriv get | HGIC_CMD ID | AT Command | Notes |
|---|---|---|---|
| `mode` | 145 | AT+WIFIMODE? | |
| `ssid` | 48 | AT+SSID? | |
| `bssid` | 18 | — | Returns MAC,aid |
| `wpa_psk` | 49 | AT+PSK? | |
| `txpower` | 23 | AT+TXPOWER? | |
| `bss_bw` | 62 | AT+BSS_BW? | |
| `agg_cnt` | 61 | — | Returns tx,rx pair |
| `chan_list` | 64 | AT+CHAN_LIST? | |
| `freq_range` | 63 | — | Returns start,end,step |
| `key_mgmt` | 86 | — | |
| `sta_list` | 53 | AT+STA_INFO | Different format |
| `sta_count` | 57 | — | |
| `scan_list` | 15 | AT+SCAN | Different output |
| `conn_state` | 40 | — | 0=disconn, 9=connected |
| `signal` | 50 | AT+RSSI? | |
| `tx_bitrate` | 51 | — | |
| `temperature` | 45 | AT+T_SENSOR | |
| `module_type` | 96 | — | |
| `disassoc_reason` | 102 | — | |
| `wkreason` | 78 | — | |
| `wkdata_buff` | 101 | — | |
| `ant_sel` | 112 | — | |
| `battery_level` | 93 | — | |
| `nav` | 142 | — | |
| `rtc` | 126 | — | |
| `bgrssi=<bw>` | 146 | AT+RX_RSSI | Different scope |
| `center_freq` | 156 | — | |
| `txq_param` | 134 | — | Binary struct |
| `acs_result` | 162 | — | Binary struct |
| `reason_code` | 164 | — | |
| `status_code` | 163 | — | |
| `dhcpc_result` | 99 | — | 24-byte struct |
| `xosc` | 168 | AT+XO_CS? | |
| `freq_offset=<mac>` | 170 | — | |
| `fwinfo` | 43 | AT+VERSION | Different format |
| `stainfo=<mac>` | 174 | AT+STA_INFO | Same data, different path |
| `link_quality` | 194 | — | Struct with bgrssi/rssi/evm/per/cca |

---

## AT Commands Without iwpriv Equivalents

These commands are **only** reachable via `hgpriv hg0 set atcmd=AT+...`:

| Category | Commands |
|---|---|
| RF Test | TEST_START, TX_START, TX_STEP, TX_TRIG, TX_CONT, TX_CW, TX_DELAY, TX_CNT_MAX, TX_DST_ADDR, TX_LEN, TX_TYPE |
| RF Calibration | TX_ATTN, TX_PHA_AMP, LO_FREQ, LO_TABLE, FT_ATT, XO_CS_AUTO, ADC_DUMP |
| PHY Tuning | SHORT_GI, SHORT_TH, RTS_DUP, CTS_DUP, CCMP_SUPPORT, TXOP_EN, TX_FLAGS, TX_ORDERED, TX_FC, TX_BW_DYNAMIC, TX_MAX_SYMS, TX_AGG_AUTO, TX_TRV_PILOT_EN |
| RX Readback | RX_RSSI, RX_EVM, RX_AGC, RX_ERR, RX_PKTS, RX_REORDER, TX_PKTS, TX_FAIL |
| Power | TX_PWR_AUTO, TX_PWR_MAX, TX_PWR_SUPER_TH, AP_SLEEP_MODE, WAKE_EN, PS_CHECK, DSLEEP |
| OBSS/CCA | CCA_OBSV, OBSS_CCA_DIFF, OBSS_NAV_DIFF, OBSS_SWITCH, OBSS_TH, OBSS_EDCA |
| EDCA/PCF | EDCA_AIFS, EDCA_CW, EDCA_TXOP, AP_BACKOFF, PCF_EN, PCF_PERCENT, PCF_PERIOD |
| Register | REG_RD, REG_WT, NOR_RD, BUS_WT |
| Factory/QA | QA_ATT, QA_CFG, QA_RESULTS, QA_RXTHD, QA_TXTHD, QA_START, SMT_DAT |
| Misc | PHY_RESET, RF_RESET, LMAC_DBGSEL, PRINT_PERIOD, RC_NEW, CHAN_SCAN, FREQ_LIST, CS_CNT, CS_EN, CS_NUM, CS_PERIOD, CS_TH, EVM_MARGIN, BGRSSI_MARGIN, BGRSSI_SPUR, MCAST_DUP, MCAST_REORDER, MCAST_BW, MCAST_MCS, MCAST_RTS, ANT_DUAL, ANT_CTRL, ANT_DEF |

## iwpriv-Only Commands (No AT Equivalent)

These driver-level commands have no matching AT command:

| iwpriv | Description |
|---|---|
| `bssid_filter` | BSSID filter |
| `frag_threshold` | Fragmentation threshold |
| `freq_range` | Frequency range config |
| `paired_stas` | Paired station list |
| `beacon_int` | Beacon interval |
| `ps_connect` | PS connect |
| `bss_max_idle` | BSS max idle |
| `wkio_mode` | Wakeup IO mode |
| `dtim_period` | DTIM period |
| `aplost_time` | AP lost timeout |
| `auto_chswitch` | Auto channel switch |
| `reassoc_wkhost` | Reassoc wakeup host |
| `wakeup_io` | Wakeup IO config |
| `autosleep_time` | Auto sleep time |
| `auto_save` | Config auto-save |
| `pair_autostop` | Pair auto-stop |
| `pa_pwrctl_dis` | PA power control disable |
| `dhcpc` | DHCP client |
| `wkdata_save` | Wakeup data save |
| `mcast_txparam` | Multicast TX params |
| `reset_sta` | Reset station |
| `macfilter` | MAC filter enable |
| `dupfilter` | Dup filter enable |
| `dis_1v1m2u` | Disable 1v1 M2U |
| `dis_psconnect` | Disable PS connect |
| `nav_max` | NAV maximum |
| `clr_nav` | Clear NAV |
| `tx_modgain` | TX modulation gain |
| `standby` | Standby config |
| `disable_print` | Disable prints |
| `conn_paironly` | Connect paired only |
| `diffcust_conn` | Different customer connect |
| `wait_psmode` | Wait PS mode |
| `ap_chansw` | AP channel switch |
| `cca_ce` | CCA for CE |
| `watchdog` | Watchdog |
| `retry_fallback_cnt` | Retry fallback count |
| `fallback_mcs` | Fallback MCS |
| `freq_cali_period` | Freq calibration period |
| `max_txdelay` | Max TX delay |
| `sleep_roaming` | Sleep roaming |
| `roaming_bssid` | Roaming BSSID |
| `bss_disable` | BSS disable |
| `heartbeat` | Heartbeat config |
| `heartbeat_int` | Heartbeat interval |
| `heartbeat_resp` | Heartbeat response |
| `wakeup_data` | Wake data config |
| `wkdata_mask` | Wake data mask |
| `hbdata_mask` | Heartbeat data mask |
| `custmgmt` | Custom mgmt frames |
| `mgmtframe` | Send mgmt frame |
| `driverdata` | Custom driver data |
| `cust_drvdata` | Customer driver data |
| `freqinfo` | Frequency info |
| `blenc` | BLE coexistence |
| `hwscan` | HW scan |
| `apep_padding` | APEP padding |
| `rts_duration` | RTS duration |
