# China ISP Spectrum Allocation

This page provides detailed information about the 4G/5G frequency band allocations for China's major carriers (China Mobile, China Telecom, China Unicom) and China Broadcasting Network (CBN), including common EARFCN/NR-ARFCN values and their corresponding frequency ranges.

::: tip About Channel Numbers
- **EARFCN** (E-UTRA Absolute Radio Frequency Channel Number): 4G LTE channel number
- **NR-ARFCN** (NR Absolute Radio Frequency Channel Number): 5G NR channel number

The center frequency can be calculated from these channel numbers. See [Frequency Calculation Formulas](#frequency-calculation-formulas) at the bottom of this page.
:::

## China Mobile

### 4G LTE Bands

| Band | Frequency Range | Duplex | Common EARFCN | Center Frequency | Notes |
|------|-----------------|--------|---------------|------------------|-------|
| B38 | 2570-2620 MHz | TDD | 37900, 38098 | 2585, 2604.8 MHz | 2.6G band, mostly refarmed to 5G |
| B39 | 1880-1920 MHz | TDD | 38400, 38544, 38350, 38496, 38352 | 1895, 1909.4 MHz | 1.9G band |
| B40 | 2300-2400 MHz | TDD | 38950, 39148 | 2330, 2349.8 MHz | 2.3G band |
| B41 | 2496-2690 MHz | TDD | 40936, 41134, 41140, 41332, 41339 | 2624.6, 2644.4 MHz | 2.6G band |
| B34 | 2010-2025 MHz | TDD | 36275 | 2017.5 MHz | 2.0G band, 5G refarming in progress |
| B3 | 1805-1880 MHz | FDD | 1300, 1303, 1306, 1375, 1275, 1350, 1368 | 1815-1822.5 MHz | 1.8G band, 5G refarming in progress |
| B8 | 925-960 MHz | FDD | 3683, 3590, 3600 | 939-948.3 MHz | 900M band |

### 5G NR Bands

| Band | Frequency Range | Duplex | Common NR-ARFCN | Center Frequency | Notes |
|------|-----------------|--------|-----------------|------------------|-------|
| n41 | 2515-2675 MHz | TDD | 504990, 507150, 516990, 513000 | 2524.95, 2535.75, 2584.95, 2565 MHz | Primary 2.6G band, 160 MHz bandwidth |
| n79 | 4800-4900 MHz | TDD | 721824, 723360, 723334 | 4827.36, 4850.4 MHz | 4.9G band, 100 MHz bandwidth |
| n28 | 703-733 / 758-788 MHz | FDD | 152890, 152650, 154600 | 764.45, 763.25, 773 MHz | 700M band (shared with CBN) |

## China Telecom

### 4G LTE Bands

| Band | Frequency Range | Duplex | Common EARFCN | Center Frequency | Notes |
|------|-----------------|--------|---------------|------------------|-------|
| B1 | 2110-2170 MHz | FDD | 100 | 2120 MHz | 2.1G band |
| B3 | 1805-1880 MHz | FDD | 1825, 1850 | 1867.5, 1870 MHz | 1.8G band |
| B5 | 869-894 MHz | FDD | 2452 | 874.2 MHz | 850M band |

### 5G NR Bands

| Band | Frequency Range | Duplex | Common NR-ARFCN | Center Frequency | Notes |
|------|-----------------|--------|-----------------|------------------|-------|
| n78 | 3400-3500 MHz | TDD | 627264, 633984 | 3408.96, 3509.76 MHz | 3.5G band (shared with Unicom) |
| n1 | 2110-2170 MHz | FDD | 428910, 427970, 422930 | 2144.55, 2139.85, 2114.65 MHz | 2.1G band |

## China Unicom

### 4G LTE Bands

| Band | Frequency Range | Duplex | Common EARFCN | Center Frequency | Notes |
|------|-----------------|--------|---------------|------------------|-------|
| B1 | 2110-2170 MHz | FDD | 300, 500, 350, 400 | 2140, 2160 MHz | 2.1G band |
| B3 | 1805-1880 MHz | FDD | 1650, 1525, 1506 | 1850, 1837.5 MHz | 1.8G band |
| B8 | 925-960 MHz | FDD | 3715, 3740, 3745, 3739 | 951.5, 954 MHz | 900M band |

### 5G NR Bands

| Band | Frequency Range | Duplex | Common NR-ARFCN | Center Frequency | Notes |
|------|-----------------|--------|-----------------|------------------|-------|
| n78 | 3500-3600 MHz | TDD | 620640, 623328 | 3309.6, 3349.92 MHz | 3.5G band (shared with Telecom) |
| n1 | 2110-2170 MHz | FDD | 428910, 427970, 422930 | 2144.55, 2139.85, 2114.65 MHz | 2.1G band (shared with Telecom) |
| n8 | 925-960 MHz | FDD | 190350 | 951.75 MHz | 900M band |

## China Broadcasting Network (CBN)

### 5G NR Bands

| Band | Frequency Range | Duplex | Common NR-ARFCN | Center Frequency | Notes |
|------|-----------------|--------|-----------------|------------------|-------|
| n28 | 703-733 / 758-788 MHz | FDD | 152890, 152650, 154600 | 764.45, 763.25, 773 MHz | 700M golden band, shared with China Mobile |
| n79 | 4900-4960 MHz | TDD | - | 4930 MHz | 4.9G band, 60 MHz bandwidth |

## Summary Table

The following table summarizes all bands by carrier and network generation:

| Carrier | Band | Generation | EARFCN/NR-ARFCN | Typical Frequency Range |
|---------|------|------------|-----------------|-------------------------|
| China Mobile | B38 | 4G TDD | 37900, 38098 | 2570-2620 MHz |
| China Mobile | B39 | 4G TDD | 38400, 38544 | 1880-1920 MHz |
| China Mobile | B40 | 4G TDD | 38950, 39148 | 2300-2400 MHz |
| China Mobile | B41 | 4G TDD | 40936, 41134, 41339 | 2496-2690 MHz |
| China Mobile | B34 | 4G TDD | 36275 | 2010-2025 MHz |
| China Mobile | B3 | 4G FDD | 1300, 1375 | 1805-1880 MHz |
| China Mobile | B8 | 4G FDD | 3683, 3590 | 925-960 MHz |
| China Mobile | n41 | 5G TDD | 504990, 507150, 516990 | 2515-2675 MHz |
| China Mobile | n79 | 5G TDD | 721824, 723360 | 4800-4900 MHz |
| China Mobile | n28 | 5G FDD | 152890, 154600 | 703-788 MHz |
| China Telecom | B1 | 4G FDD | 100 | 2110-2170 MHz |
| China Telecom | B3 | 4G FDD | 1825, 1850 | 1805-1880 MHz |
| China Telecom | B5 | 4G FDD | 2452 | 869-894 MHz |
| China Telecom | n78 | 5G TDD | 627264, 633984 | 3400-3500 MHz |
| China Telecom | n1 | 5G FDD | 428910, 427970 | 2110-2170 MHz |
| China Unicom | B1 | 4G FDD | 300, 500 | 2110-2170 MHz |
| China Unicom | B3 | 4G FDD | 1650, 1525 | 1805-1880 MHz |
| China Unicom | B8 | 4G FDD | 3715, 3740 | 925-960 MHz |
| China Unicom | n78 | 5G TDD | 620640, 623328 | 3500-3600 MHz |
| China Unicom | n1 | 5G FDD | 428910, 427970 | 2110-2170 MHz |
| China Unicom | n8 | 5G FDD | 190350 | 925-960 MHz |
| CBN | n28 | 5G FDD | 152890, 154600 | 703-788 MHz |
| CBN | n79 | 5G TDD | - | 4900-4960 MHz |

## Frequency Calculation Formulas

### 4G LTE EARFCN Calculation

For FDD bands, the downlink frequency is calculated as:

$$
F_{DL} = F_{DL,low} + 0.1 \times (EARFCN - N_{offs,DL})
$$

Common band parameters:

| Band | F_DL_low (MHz) | N_offs_DL | EARFCN Range |
|------|----------------|-----------|--------------|
| B1 | 2110 | 0 | 0-599 |
| B3 | 1805 | 1200 | 1200-1949 |
| B5 | 869 | 2400 | 2400-2649 |
| B8 | 925 | 3450 | 3450-3799 |

For TDD bands:

| Band | F_low (MHz) | N_offs | EARFCN Range |
|------|-------------|--------|--------------|
| B34 | 2010 | 36200 | 36200-36349 |
| B38 | 2570 | 37750 | 37750-38249 |
| B39 | 1880 | 38250 | 38250-38649 |
| B40 | 2300 | 38650 | 38650-39649 |
| B41 | 2496 | 39650 | 39650-41589 |

### 5G NR-ARFCN Calculation

According to 3GPP TS 38.104, NR-ARFCN to frequency conversion:

$$
F = F_{REF-Offs} + \Delta F_{Global} \times (N_{REF} - N_{REF-Offs})
$$

| Frequency Range | ΔF_Global | F_REF-Offs (MHz) | N_REF-Offs | NR-ARFCN Range |
|-----------------|-----------|------------------|------------|----------------|
| 0-3000 MHz | 5 kHz | 0 | 0 | 0-599999 |
| 3000-24250 MHz | 15 kHz | 3000 | 600000 | 600000-2016666 |
| 24250-100000 MHz | 60 kHz | 24250.08 | 2016667 | 2016667-3279165 |

**Calculation Example:**

For NR-ARFCN 627264:
- This value falls in the 600000-2016666 range, use the second set of parameters
- F = 3000 + 0.015 × (627264 - 600000) = 3000 + 408.96 = **3408.96 MHz**

## 5G Spectrum Refarming Progress

As of 2025, Chinese carriers are refarming the following bands for 5G:

| Carrier | Original Band | Refarmed Band | Status |
|---------|---------------|---------------|--------|
| China Mobile | B38 (2.6G 4G) | n41 (2.6G 5G) | Mostly completed |
| China Mobile | B34 (2.0G 4G) | n34 (2.0G 5G) | In progress (2025) |
| China Mobile | B3 (1.8G 4G) | n3 (1.8G 5G) | In progress (2025) |

::: warning Note
Spectrum allocations may change over time. Please refer to official announcements from MIIT and carriers for the latest information.
:::

## References

- [Zhihu: China ISP 4G and 5G Frequency Band Details](https://zhuanlan.zhihu.com/p/1942166976358228737)
- 3GPP TS 36.101 - E-UTRA User Equipment (UE) radio transmission and reception
- 3GPP TS 38.104 - NR Base Station (BS) radio transmission and reception

## Related Pages

- [5G System Architecture](/en/guide/5g-architecture) - Understand the overall 5G network architecture
- [RF Regulations](/en/guide/rf-regulations) - Learn about legal requirements for spectrum usage
