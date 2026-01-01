# Open5GS Configuration

This page details the configuration parameters for Open5GS network functions.

## Configuration Overview

All configuration files are located at `/etc/open5gs/` in YAML format.

## AMF Configuration

AMF (Access and Mobility Management Function) is the entry point for the 5G core, handling N2 connections from gNB.

Config file: `/etc/open5gs/amf.yaml`

```yaml
amf:
  sbi:
    server:
      - address: 127.0.0.5
        port: 7777
    client:
      nrf:
        - uri: http://127.0.0.10:7777

  ngap:
    server:
      - address: 192.168.1.10  # Address for gNB connection
        port: 38412

  guami:
    - plmn_id:
        mcc: 001
        mnc: 01
      amf_id:
        region: 2
        set: 1
        pointer: 0

  tai:
    - plmn_id:
        mcc: 001
        mnc: 01
      tac: 1

  plmn_support:
    - plmn_id:
        mcc: 001
        mnc: 01
      s_nssai:
        - sst: 1
          sd: 000001

  security:
    integrity_order: [NIA2, NIA1, NIA0]
    ciphering_order: [NEA0, NEA1, NEA2]

  network_name:
    full: Open5GS
    short: O5GS

  amf_name: open5gs-amf0
```

### Key Parameters

| Parameter | Description |
|-----------|-------------|
| `ngap.server.address` | IP address for gNB connection, must be reachable |
| `guami` | Globally Unique AMF Identifier |
| `tai` | Tracking Area Identity, must match gNB config |
| `plmn_support` | Supported PLMN and slice info |
| `s_nssai` | Network Slice Selection Assistance Information |

## SMF Configuration

SMF (Session Management Function) manages PDU sessions.

Config file: `/etc/open5gs/smf.yaml`

```yaml
smf:
  sbi:
    server:
      - address: 127.0.0.4
        port: 7777
    client:
      nrf:
        - uri: http://127.0.0.10:7777

  pfcp:
    server:
      - address: 127.0.0.4
    client:
      upf:
        - address: 127.0.0.7

  session:
    - subnet: 10.45.0.1/16
      gateway: 10.45.0.1
      dnn: internet
```

### Key Parameters

| Parameter | Description |
|-----------|-------------|
| `pfcp.client.upf` | UPF PFCP address |
| `session.subnet` | IP address pool for UEs |
| `session.dnn` | Data Network Name |

## UPF Configuration

UPF (User Plane Function) handles user data forwarding.

Config file: `/etc/open5gs/upf.yaml`

```yaml
upf:
  pfcp:
    server:
      - address: 127.0.0.7

  gtpu:
    server:
      - address: 192.168.1.10  # Address for gNB connection

  session:
    - subnet: 10.45.0.1/16
      gateway: 10.45.0.1
      dnn: internet
      dev: ogstun
```

### Key Parameters

| Parameter | Description |
|-----------|-------------|
| `gtpu.server.address` | Address for receiving gNB GTP-U data |
| `session.dev` | TUN interface name |

## Common Configuration Scenarios

### Modify PLMN

PLMN (Public Land Mobile Network) consists of MCC and MNC:

```yaml
# All NFs need modification
plmn_id:
  mcc: 460    # China
  mnc: 00     # Operator code
```

Files to modify:
- `amf.yaml`
- `smf.yaml`
- `nrf.yaml`
- `ausf.yaml`
- `udm.yaml`
- `pcf.yaml`
- `nssf.yaml`

### Configure Multiple Slices

```yaml
# amf.yaml
plmn_support:
  - plmn_id:
      mcc: 001
      mnc: 01
    s_nssai:
      - sst: 1        # eMBB
        sd: 000001
      - sst: 2        # URLLC
        sd: 000002
      - sst: 3        # mMTC
        sd: 000003
```

### External gNB Connection

If gNB is on a different machine:

```yaml
# amf.yaml
ngap:
  server:
    - address: 0.0.0.0  # Listen on all interfaces
      port: 38412

# upf.yaml
gtpu:
  server:
    - address: 0.0.0.0  # Listen on all interfaces
```

## Configuration Validation

After modifying config, validate syntax:

```bash
# Test AMF config
sudo open5gs-amfd -c /etc/open5gs/amf.yaml -t

# Test SMF config
sudo open5gs-smfd -c /etc/open5gs/smf.yaml -t
```

Restart services to apply changes:

```bash
sudo systemctl restart open5gs-amfd
sudo systemctl restart open5gs-smfd
sudo systemctl restart open5gs-upfd
```

## Next Steps

- [Subscriber Management](/en/open5gs/subscriber) - Add UE subscriber info
- [srsRAN Configuration](/en/srsran/gnb-config) - Configure gNB for core network

