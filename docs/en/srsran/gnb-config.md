# gNB Configuration

This page details the srsRAN gNB configuration parameters.

## Configuration File Structure

gNB uses YAML format configuration:

```yaml
gnb_id: 411
gnb_id_bit_length: 22

cell_cfg:
  # Cell configuration
  
cu_cp:
  # CU-CP configuration
  
ru_sdr:
  # SDR configuration
  
log:
  # Logging configuration
```

## Complete Configuration Example

### USRP B210 Configuration

```yaml
# gNB Identity
gnb_id: 411
gnb_id_bit_length: 22

# Cell Configuration
cell_cfg:
  dl_arfcn: 632628          # n78 band center frequency
  band: 78                   # NR band
  channel_bandwidth_MHz: 20  # Bandwidth
  common_scs: 30             # Subcarrier spacing (kHz)
  plmn: "00101"              # PLMN
  tac: 1                     # Tracking Area Code

  pdcch:
    common:
      ss0_index: 0
      coreset0_index: 12
    dedicated:
      ss2_type: common
      dci_format_0_1_and_1_1: false

  prach:
    prach_config_index: 1

# CU-CP Configuration (Core Network Connection)
cu_cp:
  amf:
    addr: 192.168.1.10       # AMF address
    port: 38412              # NGAP port
    bind_addr: 192.168.1.20  # gNB local address
    n2_bind_addr: 192.168.1.20
    n2_bind_interface: eth0  # Optional

  upf:
    bind_addr: 192.168.1.20  # N3 interface address

# SDR Configuration
ru_sdr:
  device_driver: uhd         # USRP driver
  device_args: type=b200     # Device parameters
  srate: 23.04               # Sample rate (MHz)
  tx_gain: 50                # TX gain (dB)
  rx_gain: 40                # RX gain (dB)
  
  # Clock configuration
  clock: internal            # internal/external/gpsdo
  sync: internal

# Logging Configuration
log:
  filename: /tmp/gnb.log
  all_level: info            # debug/info/warning/error
  phy_level: info
  mac_level: info
  rlc_level: info
  pdcp_level: info
  rrc_level: info
  ngap_level: info

# Performance Configuration
expert:
  phy:
    threads:
      pdsch:
        nof_threads: 2
      pusch:
        nof_threads: 2
```

## Key Parameters

### Cell Parameters

| Parameter | Description | Common Values |
|-----------|-------------|---------------|
| `dl_arfcn` | Downlink Absolute Radio Frequency Channel Number | See band table |
| `band` | NR band number | 78, 41, 3, etc. |
| `channel_bandwidth_MHz` | Channel bandwidth | 10, 20, 40, 100 |
| `common_scs` | Subcarrier spacing | 15, 30 kHz |
| `plmn` | Public Land Mobile Network | Must match Open5GS |
| `tac` | Tracking Area Code | Must match Open5GS |

### Band and ARFCN

Common n78 band ARFCNs:

| Center Frequency | ARFCN | SCS |
|------------------|-------|-----|
| 3.5 GHz | 632628 | 30 kHz |
| 3.6 GHz | 636666 | 30 kHz |
| 3.7 GHz | 640704 | 30 kHz |

### Core Network Connection

| Parameter | Description |
|-----------|-------------|
| `amf.addr` | Open5GS AMF IP address |
| `amf.port` | NGAP port, default 38412 |
| `amf.bind_addr` | gNB local IP |
| `upf.bind_addr` | N3 interface bind address |

## Start gNB

```bash
# Foreground
sudo gnb -c gnb.yaml

# Background
sudo gnb -c gnb.yaml > /tmp/gnb.log 2>&1 &
```

## Verify Connection

### Check AMF Connection

On successful connection, gNB logs show:

```
[NGAP   ] NG Setup procedure successful
[NGAP   ] AMF connected
```

Open5GS AMF logs show:

```
[amf] INFO: gNB-N2 accepted[192.168.1.20]:38412
```

## Troubleshooting

### NGAP Connection Failed

```
[NGAP   ] Failed to connect to AMF
```

Check:
1. AMF address and port are correct
2. Network connectivity `ping 192.168.1.10`
3. AMF service is running
4. Firewall rules

### PLMN Mismatch

```
[NGAP   ] NGAP Setup Failure - Unknown PLMN
```

Ensure `plmn` matches Open5GS configuration.

## Next Steps

- [UE Configuration](/en/srsran/ue-config) - Configure software terminal
- [Open5GS Subscriber](/en/open5gs/subscriber) - Add subscribers

