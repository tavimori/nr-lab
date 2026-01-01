# srsRAN Base Station Overview

srsRAN Project is an open-source 5G RAN implementation providing 3GPP compliant gNB and UE.

## Project Architecture

```
                    srsRAN Project
                         │
           ┌─────────────┴─────────────┐
           │                           │
      ┌────▼────┐                ┌─────▼────┐
      │  srsGNB │                │  srsUE   │
      │ (gNodeB)│                │  (UE)    │
      └────┬────┘                └──────────┘
           │
    ┌──────┴──────┐
    │             │
┌───▼───┐    ┌────▼────┐
│  DU   │    │   CU    │
│(Distr.│    │(Central │
│ Unit) │    │  Unit)  │
└───────┘    └─────────┘
```

## Main Components

### srsGNB (gNodeB)

5G NR base station implementation supporting:

| Feature | Description |
|---------|-------------|
| 5G SA | Standalone mode |
| N2/N3 Interface | 5GC connection |
| Multiple SDRs | USRP, BladeRF, ZMQ |
| Multi-band | Sub-6 GHz |
| MIMO | Up to 4x4 |

### srsUE

5G user terminal implementation:

| Feature | Description |
|---------|-------------|
| 5G SA | Standalone mode |
| NAS | Complete NAS layer |
| PDU Session | Data session support |

## System Requirements

### Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 4-core x86_64 | 8+ cores, AVX2 |
| RAM | 8 GB | 16+ GB |
| SDR | USRP B210 | USRP X310/N310 |

### Software Requirements

- Ubuntu 22.04 LTS
- CMake 3.14+
- GCC 10+
- UHD 4.0+ (for USRP)

## Supported SDRs

| SDR | Interface | Bandwidth | Status |
|-----|-----------|-----------|--------|
| USRP B210 | USB 3.0 | 56 MHz | ✅ Full support |
| USRP X310 | 10GbE | 200 MHz | ✅ Full support |
| USRP N310 | 10GbE | 100 MHz | ✅ Full support |
| BladeRF | USB 3.0 | 40 MHz | ⚠️ Experimental |
| ZMQ | Virtual | - | ✅ Simulation |

## Supported Bands

| Band | Frequency Range | Duplex | Status |
|------|-----------------|--------|--------|
| n78 | 3300-3800 MHz | TDD | ✅ |
| n77 | 3300-4200 MHz | TDD | ✅ |
| n41 | 2496-2690 MHz | TDD | ✅ |
| n3 | 1805-1880 MHz | FDD | ✅ |
| n1 | 1920-2170 MHz | FDD | ✅ |

## Integration with Open5GS

srsRAN gNB connects to Open5GS via N2/N3 interfaces:

```
┌─────────────┐         ┌─────────────┐
│   srsGNB    │───N2───▶│    AMF      │
│             │  SCTP   │  (Open5GS)  │
└──────┬──────┘         └─────────────┘
       │
       │ N3
       │ GTP-U
       │
┌──────▼──────┐
│    UPF      │
│  (Open5GS)  │
└─────────────┘
```

## Next Steps

- [Installation](/en/srsran/installation) - Compile and install srsRAN
- [gNB Configuration](/en/srsran/gnb-config) - Configure base station
- [UE Configuration](/en/srsran/ue-config) - Configure software UE

