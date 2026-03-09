---
layout: home

hero:
  name: "NR Lab"
  text: "5G NR Lab Documentation"
  tagline: Private 5G Network Setup Guide with Open5GS + srsRAN + SDR
  image:
    src: /hero-image.svg
    alt: 5G NR Lab
  actions:
    - theme: brand
      text: Get Started
      link: /en/guide/getting-started
    - theme: alt
      text: View on GitHub
      link: https://github.com/your-repo/nr-lab

features:
  - icon: 📚
    title: 5G Fundamentals
    details: Learn about 5G network architecture, RAN/Core components, spectrum allocation, and base station types
    link: /en/guide/5g-architecture
  - icon: ⚖️
    title: RF Regulations
    details: Radio regulations, 2026 Public Security Law, legal experimentation methods
    link: /en/guide/rf-regulations
  - icon: 🌐
    title: Open5GS Core Network
    details: Complete 5G SA core network deployment with AMF, SMF, UPF and other network functions
    link: /en/open5gs/
  - icon: 📡
    title: srsRAN Base Station
    details: Build 5G gNB using srsRAN Project with support for various SDR hardware
    link: /en/srsran/
  - icon: 🔧
    title: SDR Hardware
    details: Configuration guide for USRP, BladeRF, LimeSDR and other software-defined radios
    link: /en/guide/hardware
  - icon: 📱
    title: End-to-End Testing
    details: Complete test workflow from UE registration to data transmission
    link: /en/guide/getting-started
---

## Project Overview

This documentation provides a comprehensive guide for building a private 5G NR network using open-source software and Software Defined Radio (SDR) hardware.

### Technology Stack

| Component | Software/Hardware | Description |
|-----------|-------------------|-------------|
| Core Network | Open5GS | Open source 5G SA core implementation |
| Base Station | srsRAN Project | Open source 5G gNB implementation |
| RF Frontend | USRP B210 / BladeRF | SDR hardware |
| Terminal | COTS UE / srsUE | Commercial phones or software UE |

### Quick Links

- 📚 [5G System Architecture](/en/guide/5g-architecture) - Understand 5G network fundamentals first
- ⚖️ [RF Regulations](/en/guide/rf-regulations) - **Must read!** Understand RF compliance requirements
- 📖 [Prerequisites](/en/guide/prerequisites) - System requirements & software installation
- 🔧 [Open5GS Installation](/en/open5gs/installation) - Core network deployment steps
- 📡 [srsRAN Configuration](/en/srsran/gnb-config) - gNB parameter configuration

::: tip
This project is for educational and research purposes only. Please ensure experiments are conducted within legal frequency bands and power limits.
:::

