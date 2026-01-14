# RF Regulations & Compliance

::: danger ⚠️ Important Warning
Before conducting any radio transmission experiments, you must understand and comply with relevant laws and regulations. **Illegal use of radio equipment may result in administrative detention or even criminal prosecution!**
:::

## Why Should You Care About RF Regulations?

Software Defined Radio (SDR) and private 5G network experiments involve the use of radio frequencies. In China (and most countries), the radio spectrum is a national resource subject to strict regulation. Unauthorized radio transmission may:

- Interfere with civilian communications (mobile signals, WiFi, etc.)
- Disrupt critical infrastructure like aviation, railways, and emergency services
- Affect national security and public safety
- **Result in legal penalties**

## China Radio Management Regulations

### Radio Regulations of the People's Republic of China

This is the fundamental regulation for radio management in China, stipulating:

- Radio spectrum resources belong to the state
- Setting up and using radio stations requires approval
- Radio transmission equipment must be type-approved
- Interference with legitimate radio services is prohibited

### Public Security Administration Punishments Law (Effective January 1, 2026)

::: danger 🚨 2026 New Regulation - Pay Special Attention!
The new Public Security Administration Punishments Law, effective from January 1, 2026, has explicit penalties for radio violations:
:::

> **Article 32** Anyone who, in violation of state regulations, commits any of the following acts shall be detained for not less than 5 days but not more than 10 days; if the circumstances are serious, detained for not less than 10 days but not more than 15 days:
> 
> (1) Intentionally interfering with the normal operation of radio services;
> 
> (2) Causing harmful interference to normally operating radio stations, and refusing to take effective measures to eliminate it after being notified by the relevant authorities;
> 
> (3) **Setting up radio broadcasting stations, communication base stations, or other radio stations without approval, or illegally using or occupying radio frequencies to engage in illegal activities.**

**Summary:**

| Violation | Penalty |
|-----------|---------|
| Intentional interference with radio services | 5-10 days detention |
| Causing harmful interference and refusing to correct | 5-10 days detention |
| Setting up base stations without approval | 5-10 days detention |
| Serious circumstances | 10-15 days detention |

::: warning What Does This Mean?
If you use SDR equipment to transmit signals without proper shielding and interfere with public communication networks, you may be **administratively detained for 5-15 days**!
:::

### Criminal Law of the People's Republic of China

For particularly serious radio violations, criminal charges may apply:

> **Article 288** Whoever, in violation of state regulations, sets up or uses a radio station without authorization, or uses radio frequencies without authorization, thereby disrupting radio communication order, shall, if the circumstances are serious, be sentenced to fixed-term imprisonment of not more than three years, criminal detention or public surveillance, and/or a fine; if the circumstances are especially serious, be sentenced to fixed-term imprisonment of not less than three years but not more than seven years and a fine.

## How to Conduct Experiments Legally?

### Option 1: Use RF Shielded Box (Recommended)

An RF shielded box confines radio signals inside the enclosure, preventing external interference.

**Advantages:**
- Completely legal, no license required
- No interference with external communications
- Can experiment with any frequency

**Disadvantages:**
- Need to purchase a shielded box (prices vary widely)
- Cannot test long-distance communications

**Purchasing Tips:**
- Attenuation of at least 60dB
- Size must accommodate your equipment
- Frequency range must cover your experimental bands

### Option 2: Very Low Power + Cable Connection

Reduce SDR transmission power to minimum and use coaxial cable to directly connect transmitter and receiver, with appropriate attenuators.

```
┌────────┐      ┌──────────────┐      ┌────────┐
│  SDR   │──────│ 30dB Attenu. │──────│  UE    │
│ (gNB)  │      │ (Coax cable) │      │        │
└────────┘      └──────────────┘      └────────┘
```

**Note:** Even with cable connection, ensure extremely low transmission power to prevent electromagnetic leakage.

### Option 3: Apply for Experimental Radio Station License

If you need to conduct over-the-air testing, you can apply for an experimental radio station license from local radio management authorities.

**Application Process:**
1. Submit application to provincial radio management authority
2. Specify experiment purpose, frequencies, power, and location
3. Wait for approval (usually takes several weeks)
4. Operate within approved parameters after receiving license

**Suitable For:**
- Research projects at universities/research institutions
- Enterprise R&D testing
- Government technical verification

### Option 4: Use ISM Bands (With Restrictions)

Industrial, Scientific, and Medical (ISM) bands can be used without a license, but with strict power limits:

| Band | Frequency Range | Max Power | Notes |
|------|-----------------|-----------|-------|
| 2.4 GHz ISM | 2400-2483.5 MHz | 100 mW EIRP | WiFi/Bluetooth band |
| 5.8 GHz ISM | 5725-5850 MHz | 25 mW EIRP | Distinguish from WiFi |

**Note:** The n78 (3.5 GHz) and n41 (2.5 GHz) bands used by 5G NR are **NOT ISM bands** and require a license for transmission!

## Experiment Safety Checklist

Before starting experiments, please confirm the following:

- [ ] **Understand Regulations**: Have read and understood this page
- [ ] **Shielding Measures**: Using RF shielded box or cable connection
- [ ] **Power Control**: Transmission power set to minimum usable value
- [ ] **Frequency Selection**: Frequency used won't interfere with nearby devices
- [ ] **Emergency Preparedness**: Know how to quickly shut down transmission
- [ ] **Environment Check**: Experiment location away from airports, hospitals, government facilities

## FAQ

### Q: I'm just experimenting at home with very low power, will I get caught?

**A:** Don't take chances! Radio management authorities have professional monitoring equipment that can precisely locate illegal radio sources. Even with low power, if you interfere with carrier networks, they will report to the authorities.

### Q: Do I need to follow these regulations when using srsRAN in simulation mode?

**A:** If using pure software simulation (without connecting SDR hardware), there's no radio transmission involved, so radio regulations don't apply. However, once you connect an SDR and transmit signals, you must comply.

### Q: Any recommendations for purchasing shielded boxes?

**A:** You can search for "RF Shield Box" or "射频屏蔽箱" on shopping platforms. When choosing:
- Shielding effectiveness (at least 60dB)
- Size (fits your equipment)
- Has feedthrough connectors (for power and network cables)

### Q: Can I experiment directly in a university lab?

**A:** We recommend consulting your school's radio management department first. Many universities have already applied for experimental frequency licenses and can legally conduct experiments in designated labs.

## Relevant Links

- [Ministry of Industry and Information Technology Radio Management Bureau](https://www.miit.gov.cn/)
- Consult local radio management authorities for specific regulations in your country

::: tip Remember
**Legal compliance is a prerequisite for radio experiments. It's better to spend money on a shielded box than to risk detention for illegal transmission!**
:::

## Next Steps

After understanding the regulations, you can continue:

- [Prerequisites](/en/guide/prerequisites) - Install necessary software
- [Hardware Requirements](/en/guide/hardware) - Learn about SDR equipment choices
- [Quick Start](/en/guide/getting-started) - Start building your lab environment
