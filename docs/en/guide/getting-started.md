# Getting Started

This guide will help you quickly set up a complete 5G NR private network lab environment.

## System Architecture

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│     UE       │────▶│    gNB       │────▶│   5G Core    │
│ (Phone/srsUE)│ Air │  (srsRAN)    │ N2/N3│  (Open5GS)   │
└──────────────┘     └──────────────┘     └──────────────┘
                           │
                     ┌─────┴─────┐
                     │   SDR     │
                     │ (USRP)    │
                     └───────────┘
```

## Prerequisites

Before you begin, ensure you have the following:

### Hardware Requirements

| Device | Recommended | Notes |
|--------|-------------|-------|
| Server/PC | Ubuntu 22.04, 16GB+ RAM | Run core network and gNB |
| SDR | USRP B210 / BladeRF x40 | RF frontend |
| Antenna | 700-2700MHz | Select based on band |
| SIM Card | Programmable SIM | sysmoUSIM-SJS1 recommended |
| Test UE | 5G SA capable phone | Or use srsUE |

### Software Requirements

- Ubuntu 22.04 LTS (recommended)
- Open5GS v2.7+
- srsRAN Project 24.04+
- UHD driver (for USRP users)

## Installation Overview

### 1. Install Open5GS Core Network

```bash
# Add Open5GS repository
sudo add-apt-repository ppa:open5gs/latest
sudo apt update

# Install Open5GS
sudo apt install open5gs
```

For detailed configuration, see [Open5GS Installation Guide](/en/open5gs/installation).

### 2. Install srsRAN gNB

```bash
# Install dependencies
sudo apt install cmake make gcc g++ pkg-config \
    libfftw3-dev libmbedtls-dev libsctp-dev libyaml-cpp-dev \
    libgtest-dev libzmq3-dev

# Clone and compile srsRAN
git clone https://github.com/srsran/srsRAN_Project.git
cd srsRAN_Project
mkdir build && cd build
cmake ..
make -j$(nproc)
sudo make install
```

For detailed configuration, see [srsRAN Installation Guide](/en/srsran/installation).

### 3. Configure Subscriber

Add subscriber in Open5GS WebUI:

```yaml
IMSI: 001010000000001
Key: 465B5CE8B199B49FAA5F0A2EE238A6BC
OPc: E8ED289DEBA952E4283B54E88E6183CA
```

### 4. Start Services

```bash
# Start Open5GS services
sudo systemctl start open5gs-amfd
sudo systemctl start open5gs-smfd
sudo systemctl start open5gs-upfd
# ... other services

# Start gNB
sudo gnb -c gnb.yaml
```

## Verify Connection

After successful startup, you should see gNB connection info in AMF logs:

```
[amf] INFO: gNB-N2 accepted[192.168.1.100]:38412 in ng-path module (../src/amf/ngap-sctp.c:113)
[amf] INFO: gNB-N2 accepted[192.168.1.100] in master_sm module (../src/amf/amf-sm.c:754)
```

## Next Steps

- [Prerequisites](/en/guide/prerequisites) - Detailed system configuration
- [Open5GS Configuration](/en/open5gs/configuration) - Core network parameters
- [gNB Configuration](/en/srsran/gnb-config) - Base station configuration

::: warning Warning
Before conducting over-the-air experiments, ensure:
1. You have legal spectrum authorization
2. Use shielded box or low power settings
3. No interference to public wireless networks
:::

