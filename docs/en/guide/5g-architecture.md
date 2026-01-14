# 5G System Architecture Overview

Before building a private 5G network, let's understand the overall architecture and basic concepts of 5G systems. This knowledge will help you understand the role of each component and the purpose of our subsequent configurations.

## 5G Network Overall Architecture

A 5G network consists of three main parts:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        5G Network Architecture                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌─────────┐        ┌──────────────────┐        ┌─────────────────┐   │
│   │   UE    │◄──────►│   RAN (gNB)      │◄──────►│   5G Core (5GC) │   │
│   │Terminal │ Radio  │ Radio Access Net │Backhaul│   Core Network  │   │
│   └─────────┘        └──────────────────┘        └─────────────────┘   │
│                                                           │             │
│                                                           ▼             │
│                                                    ┌─────────────┐     │
│                                                    │   Internet  │     │
│                                                    │   / DN      │     │
│                                                    └─────────────┘     │
└─────────────────────────────────────────────────────────────────────────┘
```

| Component | Full Name | Description |
|-----------|-----------|-------------|
| **UE** | User Equipment | End-user devices such as phones, CPE, IoT devices |
| **RAN** | Radio Access Network | Handles wireless signal transmission and reception |
| **gNB** | gNodeB | 5G base station, the core device of RAN |
| **5GC** | 5G Core | 5G core network for authentication, session management, etc. |
| **DN** | Data Network | Usually refers to the Internet or enterprise networks |

## Radio Access Network (RAN) Architecture

### Traditional vs Modern Base Stations

**Traditional 4G base stations (eNodeB)** are integrated devices, while **5G base stations (gNB)** adopt a more flexible disaggregated architecture.

### gNB Functional Decomposition

A 5G base station can be decomposed into the following logical units:

```
┌─────────────────────────────────────────────────────────────────┐
│                     gNB Functional Split                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌───────────┐     ┌───────────┐     ┌───────────┐            │
│   │    RU     │◄───►│    DU     │◄───►│    CU     │            │
│   │Radio Unit │     │Distributed│     │Centralized│            │
│   └───────────┘     │   Unit    │     │   Unit    │            │
│        │            └───────────┘     └───────────┘            │
│        ▼                 │                  │                   │
│   ┌─────────────────────────────────────────────────────────┐  │
│   │  • RF transmission     • Physical layer   • RRC protocol│  │
│   │  • ADC/DAC conversion  • MAC layer        • PDCP layer  │  │
│   │  • Power amp/filter    • Real-time sched  • UP/CP       │  │
│   └─────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

| Unit | Full Name | Function |
|------|-----------|----------|
| **RU** | Radio Unit | Also called RRU/AAU, handles RF signal Tx/Rx, includes antennas, power amplifiers, filters |
| **DU** | Distributed Unit | Processes time-critical physical layer and MAC layer functions |
| **CU** | Centralized Unit | Handles non-real-time higher layer protocols, can be split into CU-CP (Control Plane) and CU-UP (User Plane) |

::: tip Why Disaggregate?
Functional separation allows:
- **Flexible deployment**: CU can be centralized while DU/RU are distributed
- **Resource sharing**: Multiple DUs can share one CU
- **Cost optimization**: Choose different deployment options based on needs
:::

### Common Deployment Scenarios

```
Option 1: Traditional Integrated Deployment
┌─────────────────────────────────┐
│  RU + DU + CU (Integrated gNB)  │
└─────────────────────────────────┘

Option 2: RU Separation (Common for DAS)
┌──────┐      ┌──────────────┐
│  RU  │◄────►│   DU + CU    │
└──────┘      └──────────────┘

Option 3: Full Disaggregation (Large Networks)
┌──────┐      ┌──────┐      ┌──────┐
│  RU  │◄────►│  DU  │◄────►│  CU  │
└──────┘      └──────┘      └──────┘
```

## 5G Core (5GC) Architecture

The 5G core network adopts a **Service-Based Architecture (SBA)**, where each network function provides services as microservices.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        5G Core Network Architecture                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐          │
│   │ NSSF │  │ AUSF │  │ UDM  │  │ PCF  │  │ NEF  │  │ NRF  │          │
│   └──┬───┘  └──┬───┘  └──┬───┘  └──┬───┘  └──┬───┘  └──┬───┘          │
│      │         │         │         │         │         │              │
│   ───┴─────────┴─────────┴─────────┴─────────┴─────────┴───────────   │
│                        Service Bus (SBI)                               │
│   ───┬─────────────────────────────────────────────────────┬───────   │
│      │                                                     │          │
│   ┌──┴───┐                                             ┌───┴──┐       │
│   │ AMF  │◄───────────────────────────────────────────►│ SMF  │       │
│   └──┬───┘                                             └───┬──┘       │
│      │  N2                                                 │ N4       │
│      ▼                                                     ▼          │
│   ┌──────┐                                             ┌──────┐       │
│   │ gNB  │◄───────────────────N3──────────────────────►│ UPF  │──►DN  │
│   └──────┘                                             └──────┘       │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Core Network Functions

| NF | Full Name | Function |
|----|-----------|----------|
| **AMF** | Access and Mobility Management Function | Access and mobility management, handles UE registration, authentication, mobility |
| **SMF** | Session Management Function | Session management, handles PDU session establishment, modification, release |
| **UPF** | User Plane Function | User plane function, responsible for packet forwarding, QoS handling |
| **AUSF** | Authentication Server Function | Authentication service, handles UE security authentication |
| **UDM** | Unified Data Management | Unified data management, stores user subscription data |
| **PCF** | Policy Control Function | Policy control, defines QoS and charging policies |
| **NRF** | Network Repository Function | Network repository function, service discovery and registration |
| **NSSF** | Network Slice Selection Function | Network slice selection |
| **NEF** | Network Exposure Function | Network capability exposure |

::: info Open5GS Implementation
In our lab, Open5GS implements most of the core network functions and can be used as a complete 5G SA core network.
:::

## 5G Base Station Physical Forms

In the real world, you may have seen various forms of base station equipment. Understanding them helps you understand how 5G networks are deployed.

### Macro Cell

Macro cells are the largest coverage base station type, usually installed on towers or building rooftops.

<figure>
  <img src="/images/5g-architecture/macro-cell-tower.jpg" alt="5G Macro Cell Tower" />
  <figcaption>5G Macro Cell Tower - A typical 5G base station in Malta (Image: Wikimedia Commons, CC BY-SA 4.0)</figcaption>
</figure>

**Characteristics:**
- Coverage radius: 1-10 km
- Transmit power: 20-40W (per antenna)
- Application: Outdoor wide-area coverage

<figure>
  <img src="/images/5g-architecture/aau-closeup.jpg" alt="Deutsche Telekom 5G Site" />
  <figcaption>Deutsche Telekom 5G AAU antenna close-up - Note the square Active Antenna Unit (Image: Wikimedia Commons, CC BY-SA 4.0)</figcaption>
</figure>

**Visual identification:**
```
           ▲ Antenna
          /│\
         / │ \      ← Large antenna array (AAU)
        /  │  \
       /   │   \
      ─────┴─────
           │
           │        ← Feeder/Fiber
           │
      ┌────┴────┐
      │  BBU    │   ← Baseband Unit (usually in cabinet)
      └─────────┘
```

Common antenna forms:
- **Traditional antenna + RRU**: Separate antenna and radio unit
- **AAU (Active Antenna Unit)**: Integrated antenna and radio unit, supports Massive MIMO

### Small Cells

Small cells supplement macro cell coverage in hard-to-reach areas or add capacity in hotspot areas.

<figure>
  <img src="/images/5g-architecture/small-cell.jpg" alt="5G Small Cell Antennas" />
  <figcaption>5G Small Cell antennas installed on a rooftop - Pittsburgh, USA (Image: Wikimedia Commons, CC BY 2.0)</figcaption>
</figure>

**Micro Cell**
- Coverage radius: 200m - 2km
- Common in streets, commercial areas

**Pico Cell**
- Coverage radius: 100-200m
- Common in large indoor venues

**Femto Cell**
- Coverage radius: 10-50m
- For homes or small offices

### Distributed Antenna System (DAS)

Large buildings often use indoor distributed antenna systems:

<figure>
  <img src="/images/5g-architecture/das-diagram.png" alt="DAS System Architecture" />
  <figcaption>Distributed Antenna System (DAS) architecture diagram - Multiple antenna nodes connected to a common source (Image: Wikimedia Commons, CC BY-SA 4.0)</figcaption>
</figure>

```
                    ┌─────────┐
                    │ Source  │  ← Macro signal or small cell
                    └────┬────┘
                         │
                    ┌────┴────┐
                    │ Master  │
                    │  Unit   │
                    └────┬────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
    ┌────┴────┐    ┌────┴────┐    ┌────┴────┐
    │ Remote  │    │ Remote  │    │ Remote  │
    │  Unit   │    │  Unit   │    │  Unit   │
    └────┬────┘    └────┬────┘    └────┬────┘
         │               │               │
        ⊕               ⊕               ⊕
     Antenna         Antenna         Antenna
```

<figure>
  <img src="/images/5g-architecture/das-indoor-antenna.jpg" alt="Indoor DAS Antenna" />
  <figcaption>Indoor DAS antenna mounted on ceiling - Samsung KX, London (Image: Wikimedia Commons, CC BY 2.0)</figcaption>
</figure>

### How to Identify 5G Base Stations

**Visual characteristics:**
1. **Antenna size**: 5G antennas are usually larger than 4G due to Massive MIMO support
2. **AAU form factor**: 5G AAUs are typically square or rectangular integrated devices
3. **Quantity**: A single site may have multiple AAUs covering different sectors

**Typical 5G AAU Size Comparison:**
| Type | Typical Size | Features |
|------|--------------|----------|
| 4G Antenna | Smaller/lighter | Usually passive antenna |
| Sub-6G 5G AAU | ~50×50×15 cm | Supports 64T64R MIMO |
| mmWave 5G AAU | Smaller | Highly integrated, beamforming |

## 5G Frequency Bands

### Global 5G Spectrum Allocation

5G uses two main frequency ranges:

| Frequency Range | Spectrum | Characteristics |
|-----------------|----------|-----------------|
| **FR1 (Sub-6GHz)** | 410 MHz - 7125 MHz | Good coverage, strong penetration, currently mainstream |
| **FR2 (mmWave)** | 24.25 GHz - 52.6 GHz | Large bandwidth, high speed, limited coverage |

### China 5G Spectrum Allocation

The spectrum allocation for China's three major operators:

| Operator | Band | Frequency Range | Bandwidth |
|----------|------|-----------------|-----------|
| **China Mobile** | n41 | 2515-2675 MHz | 160 MHz |
| **China Mobile** | n79 | 4800-4900 MHz | 100 MHz |
| **China Telecom** | n78 | 3400-3500 MHz | 100 MHz |
| **China Unicom** | n78 | 3500-3600 MHz | 100 MHz |
| **China Broadnet** | n28 | 703-733 / 758-788 MHz | 30+30 MHz |
| **China Broadnet** | n79 | 4900-4960 MHz | 60 MHz |

::: warning Spectrum Usage Notice
These bands are allocated to operators by national radio management authorities. When conducting private 5G experiments, you must:
1. Use a shielded box or extremely low power to avoid interfering with public networks
2. Or apply for experimental frequency license
3. Understand and comply with local radio regulations
:::

### Frequency Bands for Our Lab

In this lab environment, we typically use the following configuration:

| Parameter | Recommended Value | Description |
|-----------|-------------------|-------------|
| Band | n78 | 3.5 GHz band, widely supported by devices |
| Center Frequency | 3750 MHz | Can be adjusted based on actual conditions |
| Bandwidth | 20 MHz | Recommended for beginners, reduces hardware requirements |

## 5G Network Types

### SA vs NSA

There are two main 5G deployment modes:

**NSA (Non-Standalone)**
```
┌──────┐        ┌─────────┐
│  UE  │◄──────►│ 4G eNB  │◄──────►┌─────────┐
└──────┘        └─────────┘        │ 4G EPC  │
    ▲                              └─────────┘
    │           ┌─────────┐             ▲
    └──────────►│ 5G gNB  │◄────────────┘
                └─────────┘
```
- Uses 4G core network (EPC)
- 4G handles control plane, 5G assists user plane
- Transitional solution, commonly used in early deployments

**SA (Standalone)**
```
┌──────┐        ┌─────────┐        ┌─────────┐
│  UE  │◄──────►│ 5G gNB  │◄──────►│ 5GC     │
└──────┘        └─────────┘        └─────────┘
```
- Uses 5G core network (5GC)
- Completely independent 5G network
- Supports full 5G features, the ultimate goal

::: tip Our Lab Environment
This project builds a **5G SA** network, including a complete 5G core network (Open5GS) and 5G base station (srsRAN gNB).
:::

### Public vs Private Networks

| Type | Characteristics | Use Cases |
|------|-----------------|-----------|
| **Public** | Operator-deployed, public-facing | Personal communication, public Internet |
| **Private** | Enterprise/organization-built | Factories, campuses, ports |
| **Hybrid** | Public-private coordination | Scenarios requiring high security and reliability |

## Mapping to Our Lab

After understanding the above concepts, let's see how they map to our lab environment:

| Real Component | Lab Equivalent | Description |
|----------------|----------------|-------------|
| 5G UE (Phone) | 5G-capable phone / srsUE | Commercial phones need 5G SA mode enabled |
| RU/AAU | SDR device (USRP B210) | Handles RF signal Tx/Rx |
| DU + CU | srsRAN gNB software | Software base station running on PC |
| 5GC | Open5GS | Core network running on PC/server |

```
┌─────────────────── Our Lab Environment ──────────────────┐
│                                                          │
│   ┌───────┐     ┌──────────────────────────────┐        │
│   │ Phone │◄───►│ USRP B210 ──► srsRAN gNB     │        │
│   │ srsUE │     │   (RU)         (DU+CU)       │        │
│   └───────┘     └────────────────┬─────────────┘        │
│                                  │                       │
│                                  ▼                       │
│                          ┌─────────────┐                │
│                          │  Open5GS    │                │
│                          │   (5GC)     │                │
│                          └──────┬──────┘                │
│                                 │                        │
│                                 ▼                        │
│                          ┌─────────────┐                │
│                          │  Internet   │                │
│                          └─────────────┘                │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

## Next Steps

Now that you understand the basic architecture of 5G systems, you can start building:

- [Prerequisites](/en/guide/prerequisites) - Install necessary software and drivers
- [Open5GS Core Network](/en/open5gs/) - Deploy the 5G core network
- [srsRAN Base Station](/en/srsran/) - Configure the 5G gNB

::: info Further Reading
If you want to dive deeper into 5G technical details, you can refer to:
- 3GPP TS 23.501 - 5G System Architecture
- 3GPP TS 38.300 - NR Overall Description
- O-RAN Alliance Specifications - Open RAN standards
:::
