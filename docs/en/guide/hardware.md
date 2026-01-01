# Hardware Requirements

This page covers the hardware needed to build a 5G NR lab environment.

## Computing Platform

### Recommended Configuration

| Spec | Minimum | Recommended |
|------|---------|-------------|
| CPU | 4-core x86_64 | 8+ cores, AVX2 support |
| RAM | 8 GB | 16+ GB |
| Storage | 50 GB SSD | 100+ GB NVMe |
| Network | 1 Gbps | 10 Gbps |
| USB | USB 3.0 | USB 3.0 (for SDR) |

::: tip
Real-time performance is critical for the base station. Disable CPU power saving and use a low-latency kernel.
:::

## SDR Devices

### USRP B210 (Recommended)

**Ettus Research USRP B210** is the most commonly used SDR for 5G experiments:

| Spec | Value |
|------|-------|
| Frequency Range | 70 MHz - 6 GHz |
| Bandwidth | 56 MHz (2x2 MIMO) |
| ADC/DAC | 12-bit, 61.44 MS/s |
| Interface | USB 3.0 |
| Price | ~$1,500 USD |

Use cases:
- n78 (3.5 GHz) band experiments
- 20 MHz bandwidth 5G NR

### USRP N310

High-performance version for larger bandwidth:

| Spec | Value |
|------|-------|
| Frequency Range | 10 MHz - 6 GHz |
| Bandwidth | 100 MHz (4x4 MIMO) |
| ADC/DAC | 14-bit, 153.6 MS/s |
| Interface | 10 Gbps Ethernet |
| Price | ~$8,000 USD |

### BladeRF x40/xA4

Cost-effective option:

| Spec | BladeRF x40 | BladeRF xA4 |
|------|-------------|-------------|
| Frequency Range | 300 MHz - 3.8 GHz | 47 MHz - 6 GHz |
| Bandwidth | 40 MHz | 56 MHz |
| Interface | USB 3.0 | USB 3.0 |
| Price | ~$420 USD | ~$480 USD |

### LimeSDR

Open-source community choice:

| Spec | Value |
|------|-------|
| Frequency Range | 100 kHz - 3.8 GHz |
| Bandwidth | 61.44 MHz |
| MIMO | 2x2 |
| Interface | USB 3.0 |
| Price | ~$300 USD |

## Antennas

### Band Selection

Common 5G NR bands:

| Band | Frequency Range | Bandwidth | Notes |
|------|-----------------|-----------|-------|
| n78 | 3300-3800 MHz | 100 MHz | Primary Sub-6 band |
| n77 | 3300-4200 MHz | 100 MHz | Covers n78 |
| n41 | 2496-2690 MHz | 194 MHz | TDD band |
| n1 | 1920-2170 MHz | 60 MHz | FDD band |

### Recommended Antennas

- **Omni-directional**: Suitable for lab testing
- **Directional**: For specific coverage direction
- **PCB antenna**: For short-range testing

::: warning
Ensure antenna frequency range covers your experiment band. Impedance should be 50Ω.
:::

## SIM Cards

### Programmable SIM

**sysmoUSIM-SJS1** is recommended:

| Feature | Spec |
|---------|------|
| Type | USIM (4G/5G) |
| Algorithm | Milenage, TUAK |
| Interface | PC/SC programming |
| Price | ~$10 USD |

### SIM Programming

Use `pySim` tool to write parameters:

```bash
pip install pysim

# Write IMSI and Key
pySim-prog.py -p 0 -t sysmoUSIM-SJS1 \
    -i 001010000000001 \
    -k 465B5CE8B199B49FAA5F0A2EE238A6BC \
    -o E8ED289DEBA952E4283B54E88E6183CA \
    -a 12345678
```

## Test Terminals

### COTS Phones

Commercial phones supporting 5G SA:

- Samsung Galaxy S21+ and above
- Google Pixel 5 and above
- OnePlus 8T and above

::: tip
Ensure the phone supports your experiment band and can force 5G SA mode.
:::

### srsUE

Software UE solution, requires additional SDR:

- No real phone or SIM card needed
- Easy automation testing
- Detailed logging available

## RF Shielding

To avoid interference, RF shielded enclosures are highly recommended:

| Type | Isolation | Use Case |
|------|-----------|----------|
| Small enclosure | 60-80 dB | Phone + antenna |
| Medium enclosure | 80-100 dB | Complete test bench |

## Shopping List

### Basic Lab Setup

| Device | Qty | Budget |
|--------|-----|--------|
| USRP B210 | 1 | $1,500 |
| Antenna (n78) | 2 | $100 |
| SIM Cards | 5 | $50 |
| SIM Reader | 1 | $20 |
| Small RF Box | 1 | $500 |
| **Total** | - | **~$2,200** |

### Advanced Lab Setup

| Device | Qty | Budget |
|--------|-----|--------|
| USRP N310 | 1 | $8,000 |
| USRP B210 (for UE) | 1 | $1,500 |
| Antenna Kit | 1 | $300 |
| Medium RF Box | 1 | $2,000 |
| **Total** | - | **~$12,000** |

## Next Steps

- [Getting Started](/en/guide/getting-started) - Begin setting up your lab
- [Open5GS Installation](/en/open5gs/installation) - Core network deployment

