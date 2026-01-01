# UE Configuration

This page covers srsRAN UE configuration and usage.

## Overview

srsUE is a software 5G user terminal implementation, useful for:

- End-to-end testing without real phones
- Automated test scenarios
- Debugging and analysis

## Hardware Requirements

srsUE requires a separate SDR device:

| Device | Description |
|--------|-------------|
| USRP B210 | Recommended, full 5G support |
| ZMQ | Virtual RF, for gNB testing |

## Configuration Example

### Real SDR Configuration

```yaml
# ue.yaml
rat: nr                      # Network type

nas:
  apn: internet              # APN/DNN
  type: ipv4                 # PDN type

usim:
  mode: soft                 # Soft USIM
  algo: milenage             # Auth algorithm
  imsi: '001010000000001'    # IMSI
  k: 465B5CE8B199B49FAA5F0A2EE238A6BC      # K
  opc: E8ED289DEBA952E4283B54E88E6183CA    # OPc
  amf: 8000

cell_search:
  dl_arfcn: 632628           # Downlink ARFCN
  band: 78                   # NR band
  subcarrier_spacing: 30     # Subcarrier spacing

# SDR configuration
rf:
  device_name: uhd
  device_args: type=b200
  rx_gain: 40
  tx_gain: 50
  srate: 23.04e6

log:
  filename: /tmp/ue.log
  all_level: info
  nas_level: debug
  rrc_level: debug
```

### ZMQ Simulation Configuration

For testing with ZMQ mode gNB:

```yaml
# ue_zmq.yaml
rat: nr

nas:
  apn: internet
  type: ipv4

usim:
  mode: soft
  algo: milenage
  imsi: '001010000000001'
  k: 465B5CE8B199B49FAA5F0A2EE238A6BC
  opc: E8ED289DEBA952E4283B54E88E6183CA
  amf: 8000

cell_search:
  dl_arfcn: 368500
  band: 3
  subcarrier_spacing: 15

rf:
  device_name: zmq
  device_args: tx_port=tcp://127.0.0.1:2001,rx_port=tcp://127.0.0.1:2000,base_srate=23.04e6
  rx_gain: 40
  tx_gain: 50
  srate: 23.04e6

log:
  filename: /tmp/ue.log
  all_level: info
```

## Key Parameters

### USIM Parameters

| Parameter | Description |
|-----------|-------------|
| `imsi` | Must match Open5GS |
| `k` | Authentication key, must match Open5GS |
| `opc` | Operator key, must match Open5GS |
| `amf` | Usually 8000 |
| `algo` | milenage or xor |

### Cell Search Parameters

| Parameter | Description |
|-----------|-------------|
| `dl_arfcn` | Must match gNB config |
| `band` | NR band number |
| `subcarrier_spacing` | Subcarrier spacing (kHz) |

## Start srsUE

### Basic Start

```bash
sudo srsue -c ue.yaml
```

### Background

```bash
sudo srsue -c ue.yaml > /tmp/ue.log 2>&1 &
```

## Registration Process

Successful UE registration logs:

```
[NAS    ] 5GMM State: MM-DEREGISTERED -> MM-REGISTERED-INITIATED
[RRC    ] RRC Connected
[NAS    ] 5GMM State: MM-REGISTERED-INITIATED -> MM-REGISTERED
[NAS    ] PDU Session Establishment successful
[IP     ] Interface tun_srsue created, IP: 10.45.0.2
```

## Data Testing

### Check TUN Interface

```bash
ip addr show tun_srsue
```

### Ping Test

```bash
# Ping through UE TUN interface
ping -I tun_srsue 8.8.8.8
```

### Speed Test

```bash
# Install iperf3
sudo apt install iperf3

# Server side (on machine with internet)
iperf3 -s

# Client side (through UE interface)
iperf3 -c <server_ip> -B 10.45.0.2
```

## ZMQ End-to-End Testing

Complete testing method without SDR hardware.

### 1. Start Open5GS

```bash
sudo systemctl start open5gs-nrfd
sudo systemctl start open5gs-amfd
sudo systemctl start open5gs-smfd
sudo systemctl start open5gs-upfd
# ... other services
```

### 2. Start gNB (ZMQ Mode)

```bash
sudo gnb -c gnb_zmq.yaml
```

### 3. Start UE (ZMQ Mode)

```bash
sudo srsue -c ue_zmq.yaml
```

### 4. Verify Connection

```bash
# Check UE assigned IP
ip addr show tun_srsue

# Ping test
ping -I tun_srsue 10.45.0.1
```

## Troubleshooting

### Cell Search Failed

```
[PHY    ] Cell search failed
```

Check:
1. `dl_arfcn` and `band` are correct
2. SDR is working properly
3. gNB is broadcasting

### Authentication Failed

```
[NAS    ] Authentication Failure
```

Check:
1. IMSI, K, OPc match Open5GS
2. Subscriber is added to core network
3. AMF value is correct

### PDU Session Failed

```
[NAS    ] PDU Session Establishment rejected
```

Check:
1. APN/DNN is correct
2. SMF/UPF configuration is correct
3. TUN interface is created

## Next Steps

- [Getting Started](/en/guide/getting-started) - Complete lab workflow
- [Open5GS Subscriber](/en/open5gs/subscriber) - Manage UE subscribers

