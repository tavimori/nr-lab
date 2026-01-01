# Open5GS Core Network Overview

Open5GS is an open-source 5G SA (Standalone) and 4G LTE core network implementation that fully complies with 3GPP specifications.

## Architecture Overview

```
                                    ┌─────────────┐
                                    │    NSSF     │
                                    └──────┬──────┘
                                           │
┌─────────────┐    ┌─────────────┐    ┌────┴────┐    ┌─────────────┐
│    gNB      │───▶│    AMF      │───▶│   NRF   │◀───│    UDM      │
└─────────────┘ N2 └──────┬──────┘    └────┬────┘    └──────┬──────┘
                          │                │                │
                          │           ┌────┴────┐    ┌──────┴──────┐
                          │           │   SCP   │    │    UDR      │
                          │           └─────────┘    └─────────────┘
                          │ N11
                    ┌─────▼─────┐
                    │    SMF    │
                    └─────┬─────┘
                          │ N4
                    ┌─────▼─────┐
                    │    UPF    │────▶ Internet
                    └───────────┘ N6
```

## Network Functions

### Control Plane Functions

| NF | Full Name | Function |
|----|-----------|----------|
| **AMF** | Access and Mobility Management Function | Access and mobility management, handles N1/N2 signaling |
| **SMF** | Session Management Function | Session management, controls UPF |
| **NRF** | Network Repository Function | NF registration and discovery |
| **UDM** | Unified Data Management | User data management |
| **UDR** | Unified Data Repository | User data storage |
| **AUSF** | Authentication Server Function | Authentication service |
| **NSSF** | Network Slice Selection Function | Network slice selection |
| **PCF** | Policy Control Function | Policy control |
| **BSF** | Binding Support Function | Binding support |
| **SCP** | Service Communication Proxy | Service communication proxy |

### User Plane Functions

| NF | Full Name | Function |
|----|-----------|----------|
| **UPF** | User Plane Function | User plane processing, packet forwarding |

## Interfaces

| Interface | Connection | Protocol | Description |
|-----------|------------|----------|-------------|
| N1 | UE ↔ AMF | NAS | Non-Access Stratum signaling |
| N2 | gNB ↔ AMF | NGAP/SCTP | RAN control plane |
| N3 | gNB ↔ UPF | GTP-U | User data tunnel |
| N4 | SMF ↔ UPF | PFCP | Session management |
| N6 | UPF ↔ DN | IP | Data network connection |
| N11 | AMF ↔ SMF | HTTP/2 | Session management requests |

## Key Features

- ✅ **5G SA Core Network**: Complete 5G standalone support
- ✅ **4G EPC**: Backward compatible with 4G LTE
- ✅ **WebUI**: Graphical subscriber management
- ✅ **MongoDB**: Persistent user data storage
- ✅ **Containerization**: Docker deployment support
- ✅ **Kubernetes**: Cloud-native deployment support

## System Requirements

- **OS**: Ubuntu 22.04 LTS (recommended)
- **RAM**: 4GB+
- **Storage**: 10GB+
- **MongoDB**: 4.4+

## Configuration Files

Open5GS configuration files are located at `/etc/open5gs/`:

```
/etc/open5gs/
├── amf.yaml
├── smf.yaml
├── upf.yaml
├── nrf.yaml
├── udm.yaml
├── udr.yaml
├── ausf.yaml
├── nssf.yaml
├── pcf.yaml
├── bsf.yaml
└── scp.yaml
```

## Log Files

Log files are located at `/var/log/open5gs/`:

```bash
# View AMF logs
sudo tail -f /var/log/open5gs/amf.log

# View UPF logs
sudo tail -f /var/log/open5gs/upf.log
```

## Next Steps

- [Installation](/en/open5gs/installation) - Detailed installation steps
- [Configuration](/en/open5gs/configuration) - NF configuration guide
- [Subscriber Management](/en/open5gs/subscriber) - Add and manage subscribers

