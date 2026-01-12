# VoLTE 与 IMS 系统集成

本文档介绍 VoLTE (Voice over LTE) 和 VoNR (Voice over NR) 的系统架构概念，以及如何与 Open5GS 集成。

## 什么是 VoLTE/VoNR

VoLTE 是在 4G LTE 网络上提供语音服务的技术，而 VoNR 是其 5G 对应版本。与传统电路交换 (CS) 语音不同，VoLTE/VoNR 将语音作为 IP 数据包在分组交换网络上传输。

### 传统语音 vs VoLTE

```
传统 2G/3G 语音架构:
┌──────┐     电路交换      ┌──────┐
│  UE  │ ───────────────▶ │ MSC  │ ───▶ PSTN
└──────┘                   └──────┘

VoLTE/VoNR 架构:
┌──────┐     分组交换      ┌──────┐     ┌─────┐
│  UE  │ ───────────────▶ │ EPC/ │ ──▶ │ IMS │ ───▶ SIP/PSTN
└──────┘   (IP packets)   │ 5GC  │     └─────┘
```

关键区别：
- **全 IP 化**: 语音被编码为 IP 数据包
- **QoS 保障**: 通过专用承载 (Dedicated Bearer) 保证语音质量
- **统一网络**: 语音和数据共用同一网络基础设施

## IMS 架构概述

IMS (IP Multimedia Subsystem) 是 VoLTE/VoNR 的核心，负责：
- SIP 信令处理
- 用户认证与注册
- 会话建立与管理
- 媒体协商

### IMS 核心网元

```
                        ┌─────────────────────────────────────┐
                        │              IMS Core               │
                        │                                     │
┌──────┐    SIP    ┌────┴────┐    ┌─────────┐    ┌─────────┐ │
│  UE  │ ────────▶ │ P-CSCF  │───▶│ I-CSCF  │───▶│ S-CSCF  │ │
└──────┘           └─────────┘    └─────────┘    └────┬────┘ │
                        │                              │      │
                        │         ┌─────────┐    ┌────┴────┐ │
                        │         │  PCRF/  │    │   HSS   │ │
                        │         │  PCF    │    │ (FHoSS) │ │
                        │         └─────────┘    └─────────┘ │
                        └─────────────────────────────────────┘
```

| 网元 | 全称 | 功能 |
|------|------|------|
| **P-CSCF** | Proxy CSCF | 第一接触点，处理 SIP 信令压缩、IPSec |
| **I-CSCF** | Interrogating CSCF | 查询 HSS，选择 S-CSCF |
| **S-CSCF** | Serving CSCF | 核心处理，用户注册、会话控制 |
| **HSS** | Home Subscriber Server | IMS 用户数据库（可复用 Open5GS HSS 或独立部署 FHoSS） |

### Kamailio 的角色

[Kamailio](https://www.kamailio.org/) 是一个开源 SIP 服务器，在 VoLTE 部署中扮演 CSCF 角色：

- **模块化架构**: 支持 IMS 扩展模块 (`ims_*`)
- **高性能**: 可处理大量 SIP 事务
- **灵活配置**: 通过脚本语言定制路由逻辑

Kamailio 实现的 IMS 功能：
- `ims_registrar_pcscf` / `ims_registrar_scscf`: 用户注册
- `ims_auth`: 认证 (AKA)
- `ims_usrloc_*`: 用户位置管理
- `ims_charging`: 计费接口
- `ims_qos`: QoS 策略 (与 PCRF 交互)

## VoLTE vs VoNR 架构对比

虽然 VoLTE 和 VoNR 都使用 IMS 进行语音服务，但它们连接到不同的核心网：

### 架构差异

```
VoLTE (4G EPC):
┌──────┐    ┌─────┐    ┌─────────────────────────────┐    ┌───────────┐
│  UE  │───▶│ eNB │───▶│  EPC (MME, SGW, PGW, PCRF)  │───▶│    IMS    │
└──────┘ Uu └─────┘ S1 └─────────────────────────────┘ Rx └───────────┘

VoNR (5G SA):
┌──────┐    ┌─────┐    ┌─────────────────────────────┐    ┌───────────┐
│  UE  │───▶│ gNB │───▶│  5GC (AMF, SMF, UPF, PCF)   │───▶│    IMS    │
└──────┘ Uu └─────┘ N2 └─────────────────────────────┘ N5 └───────────┘
                       N3
```

### 网元映射

| 功能 | 4G EPC (VoLTE) | 5G Core (VoNR) |
|------|----------------|----------------|
| 接入管理 | MME | AMF |
| 会话管理 | MME + SGW-C + PGW-C | SMF |
| 用户面 | SGW-U + PGW-U | UPF |
| 策略控制 | PCRF | PCF |
| 用户数据 | HSS | UDM + UDR |
| IMS 连接接口 | Rx (Diameter) | N5 (HTTP/2) 或 Rx (Diameter) |

### QoS 机制对比

| 特性 | VoLTE (4G) | VoNR (5G) |
|------|------------|-----------|
| QoS 标识 | QCI (QoS Class Identifier) | 5QI (5G QoS Identifier) |
| 语音媒体 | QCI 1 (GBR) | 5QI 1 (GBR) |
| IMS 信令 | QCI 5 (Non-GBR) | 5QI 5 (Non-GBR) |
| 承载概念 | EPS Bearer | QoS Flow |

## Open5GS 与 IMS 的集成

### 4G VoLTE 架构

```
┌─────────────────────────────────────────────────────────────────┐
│                         VoLTE System (4G EPC)                    │
│                                                                  │
│  ┌─────────────────────────────┐  ┌───────────────────────────┐ │
│  │        Open5GS (EPC)        │  │     IMS (Kamailio)        │ │
│  │                             │  │                           │ │
│  │  ┌─────┐ ┌─────┐ ┌─────┐   │  │  ┌───────┐ ┌───────────┐  │ │
│  │  │ MME │ │ SGW │ │ PGW │   │  │  │P-CSCF │ │ I/S-CSCF  │  │ │
│  │  └──┬──┘ └──┬──┘ └──┬──┘   │  │  └───┬───┘ └─────┬─────┘  │ │
│  │     │       │       │      │  │      │           │        │ │
│  │     └───────┴───────┘      │  │      │     ┌─────┴─────┐  │ │
│  │             │              │  │      │     │   FHoSS   │  │ │
│  │  ┌──────────┴──────────┐   │  │      │     └───────────┘  │ │
│  │  │       PCRF ◀────────┼───┼──┼──────┘                    │ │
│  │  └─────────────────────┘   │  │  Rx (Diameter)            │ │
│  │                             │  │                           │ │
│  │  ┌─────────────────────┐   │  │                           │ │
│  │  │    HSS (Open5GS)    │   │  │                           │ │
│  │  └─────────────────────┘   │  │                           │ │
│  └─────────────────────────────┘  └───────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 5G VoNR 架构

```
┌─────────────────────────────────────────────────────────────────┐
│                         VoNR System (5G SA)                      │
│                                                                  │
│  ┌─────────────────────────────┐  ┌───────────────────────────┐ │
│  │        Open5GS (5GC)        │  │     IMS (Kamailio)        │ │
│  │                             │  │                           │ │
│  │  ┌─────┐ ┌─────┐ ┌─────┐   │  │  ┌───────┐ ┌───────────┐  │ │
│  │  │ AMF │ │ SMF │ │ UPF │   │  │  │P-CSCF │ │ I/S-CSCF  │  │ │
│  │  └──┬──┘ └──┬──┘ └──┬──┘   │  │  └───┬───┘ └─────┬─────┘  │ │
│  │     │       │       │      │  │      │           │        │ │
│  │     │    ┌──┴──┐    │      │  │      │     ┌─────┴─────┐  │ │
│  │     │    │ NRF │    │      │  │      │     │   FHoSS   │  │ │
│  │     │    └─────┘    │      │  │      │     └───────────┘  │ │
│  │  ┌──┴───────────────┴──┐   │  │      │                    │ │
│  │  │       PCF ◀─────────┼───┼──┼──────┘                    │ │
│  │  └─────────────────────┘   │  │  N5 (HTTP/2) 或 Rx        │ │
│  │                             │  │                           │ │
│  │  ┌─────────────────────┐   │  │                           │ │
│  │  │   UDM + UDR + AUSF  │   │  │                           │ │
│  │  └─────────────────────┘   │  │                           │ │
│  └─────────────────────────────┘  └───────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Kamailio 与 Open5GS 的连接

### 核心连接点：P-CSCF ↔ PCRF/PCF

Kamailio (P-CSCF) 与 Open5GS 的核心连接是通过策略控制接口，用于：
- 请求 QoS 保障（创建专用承载/QoS Flow）
- 通知媒体会话状态变化
- 接收策略决策

#### 4G 场景：Rx 接口 (Diameter)

```
┌───────────┐                              ┌───────────┐
│  P-CSCF   │         Rx Interface         │   PCRF    │
│(Kamailio) │◀────────Diameter────────────▶│ (Open5GS) │
└───────────┘        (TCP/SCTP)            └───────────┘
     │                                           │
     │  1. AAR (AA-Request)                      │
     │  ────────────────────────────────────────▶│
     │     - 请求语音媒体 QoS                      │
     │     - 携带 SDP 媒体信息                     │
     │                                           │
     │  2. AAA (AA-Answer)                       │
     │  ◀────────────────────────────────────────│
     │     - 确认 QoS 请求                        │
     │                                           │
     │                        ┌────────────────┐ │
     │                        │ PCRF 触发 SGW   │ │
     │                        │ 创建专用承载     │ │
     │                        │ (Gx → SGW/PGW) │ │
     │                        └────────────────┘ │
```

**Kamailio 配置要点 (ims_qos 模块)**：

```
# P-CSCF 中的 Diameter Rx 配置
modparam("ims_qos", "rx_dest_realm", "epc.mnc001.mcc001.3gppnetwork.org")
modparam("ims_qos", "rx_forced_peer", "pcrf.epc.mnc001.mcc001.3gppnetwork.org")
```

#### 5G 场景：N5 接口 (HTTP/2) 或 Rx 接口

5G 标准定义了 N5 接口使用 HTTP/2 + JSON (RESTful API)，但实际部署中也可继续使用 Diameter Rx 接口：

**选项 1: 继续使用 Rx (Diameter)** - 更简单，兼容现有 IMS

```
┌───────────┐                              ┌───────────┐
│  P-CSCF   │         Rx Interface         │    PCF    │
│(Kamailio) │◀────────Diameter────────────▶│ (Open5GS) │
└───────────┘                              └───────────┘
```

Open5GS PCF 支持 Rx 接口，配置方式与 PCRF 类似。

**选项 2: N5 接口 (HTTP/2)** - 原生 5G 方式

```
┌───────────┐                              ┌───────────┐
│  P-CSCF   │         N5 Interface         │    PCF    │
│           │◀────────HTTP/2──────────────▶│ (Open5GS) │
└───────────┘        (RESTful)             └───────────┘
     │                                           │
     │  POST /npcf-policyauthorization/v1/...   │
     │  ────────────────────────────────────────▶│
     │     - 请求 AF Session                     │
     │                                           │
     │  201 Created                              │
     │  ◀────────────────────────────────────────│
```

> **注意**: Kamailio 原生 IMS 模块主要支持 Diameter。使用 N5 需要额外开发或使用适配器。

### 关键接口汇总

| 接口 | 连接 | 4G 协议 | 5G 协议 | 用途 |
|------|------|---------|---------|------|
| **Rx/N5** | P-CSCF ↔ PCRF/PCF | Diameter | HTTP/2 或 Diameter | QoS 请求 |
| **Gx/N7** | PCRF/PCF ↔ PGW/SMF | Diameter | HTTP/2 | 策略下发 |
| **Cx** | I/S-CSCF ↔ HSS | Diameter | Diameter | 用户认证 |
| **Sh** | AS ↔ HSS | Diameter | Diameter | 用户数据 |
| **Gm** | UE ↔ P-CSCF | SIP | SIP | IMS 信令 |

### 数据流：VoNR 呼叫建立

```
    UE         gNB        AMF/SMF       PCF        P-CSCF      S-CSCF
     │          │           │            │           │           │
     │──────────┼───────────┼────────────┼───────────┼──────────▶│
     │          │           │            │           │  REGISTER │
     │          │           │            │           │           │
     │──────────┼───────────┼────────────┼───────────┼──────────▶│
     │          │           │            │           │  INVITE   │
     │          │           │            │           │           │
     │          │           │            │◀──────────│           │
     │          │           │            │  Rx AAR   │           │
     │          │           │            │  (请求 QoS)│           │
     │          │           │            │           │           │
     │          │           │◀───────────│           │           │
     │          │           │   N7       │           │           │
     │          │           │ (Policy)   │           │           │
     │          │           │            │           │           │
     │◀─────────│           │            │           │           │
     │  QoS Flow Creation   │            │           │           │
     │  (5QI=1 for voice)   │            │           │           │
     │          │           │            │           │           │
     │══════════════════════════════════════════════════════════▶│
     │                    RTP Media (via UPF)                    │
```

### HSS 选择

部署 IMS 时有两种 HSS 策略：

1. **独立 IMS HSS (FHoSS)**
   - 完整的 IMS HSS 实现
   - 需要同步用户数据
   - 更完整的 IMS 功能支持

2. **复用 Open5GS HSS**
   - 简化部署
   - 用户数据统一管理
   - 需要配置 Cx 接口

## APN 配置

VoLTE 需要配置专用的 IMS APN：

```yaml
# SMF/PGW 配置示例
session:
  - subnet: 10.45.0.1/16
    dnn: internet
    
  - subnet: 10.46.0.1/16
    dnn: ims
    # IMS APN 关键配置
    # - QCI 5 (IMS signaling)
    # - 专用承载用于语音 (QCI 1)
```

UE 需要配置两个 APN：
- `internet`: 默认数据连接
- `ims`: IMS 信令连接

## DNS 在 VoLTE/VoNR 中的作用

DNS 在 IMS 系统中至关重要，用于服务发现和域名解析。

### 3GPP 域名格式

IMS 使用标准化的域名格式：

```
ims.mnc<MNC>.mcc<MCC>.3gppnetwork.org

示例 (MCC=001, MNC=01):
ims.mnc001.mcc001.3gppnetwork.org
```

### 必需的 DNS 记录

#### P-CSCF 发现

UE 通过 DNS 查询发现 P-CSCF：

```dns
; P-CSCF SRV 记录
_sip._udp.ims.mnc001.mcc001.3gppnetwork.org. IN SRV 0 0 5060 pcscf.ims.mnc001.mcc001.3gppnetwork.org.

; P-CSCF A 记录
pcscf.ims.mnc001.mcc001.3gppnetwork.org. IN A 10.0.0.10
```

#### I-CSCF/S-CSCF 发现

```dns
; I-CSCF
icscf.ims.mnc001.mcc001.3gppnetwork.org. IN A 10.0.0.11

; S-CSCF  
scscf.ims.mnc001.mcc001.3gppnetwork.org. IN A 10.0.0.12
```

#### ENUM (E.164 to URI mapping)

用于电话号码到 SIP URI 的转换：

```dns
; 电话号码 +1234567890 的 ENUM 记录
0.9.8.7.6.5.4.3.2.1.e164.arpa. IN NAPTR 10 100 "u" "E2U+sip" "!^.*$!sip:+1234567890@ims.example.com!" .
```

### DNS 配置要点

1. **内网 DNS 服务器**: 需要部署专用 DNS 服务器（如 dnsmasq, BIND）
2. **PCO 传递**: EPC/5GC 通过 PCO (Protocol Configuration Options) 将 DNS 服务器地址传递给 UE
3. **分离解析**: IMS 域名和公网域名可能需要不同的解析策略

### VoNR 的 DNS 差异

VoNR 与 VoLTE 的 DNS 配置类似，但：
- 使用 5G 核心网的 DNS 配置机制
- 可能使用不同的域名后缀
- 支持 IPv6 (AAAA 记录)

## 通话建立流程

### 简化的 VoLTE 呼叫流程

```
    UE-A              IMS              UE-B
      │                │                │
      │  1. INVITE     │                │
      │ ──────────────▶│                │
      │                │  2. INVITE     │
      │                │ ──────────────▶│
      │                │                │
      │                │  3. 180 Ringing│
      │  4. 180 Ringing│◀────────────── │
      │◀────────────── │                │
      │                │                │
      │                │  5. 200 OK     │
      │  6. 200 OK     │◀────────────── │
      │◀────────────── │                │
      │                │                │
      │  7. ACK        │                │
      │ ──────────────▶│  8. ACK        │
      │                │ ──────────────▶│
      │                │                │
      │◀═══════════════════════════════▶│
      │         RTP 媒体流               │
```

### QoS 专用承载

语音通话需要建立 QoS 保障的专用承载/QoS Flow：

| 4G QCI | 5G 5QI | 类型 | 用途 |
|--------|--------|------|------|
| 1 | 1 | GBR | 语音媒体 (RTP) |
| 5 | 5 | Non-GBR | IMS 信令 (SIP) |

**4G 流程**：PCRF 通过 Rx 接口接收 P-CSCF 的请求，然后通过 Gx 接口指示 PGW 创建专用承载。

**5G 流程**：PCF 通过 Rx/N5 接口接收 P-CSCF 的请求，然后通过 N7 接口指示 SMF 创建 QoS Flow。

## 5G SA 下的语音方案选择

在 5G SA 部署中，有多种语音实现方案：

### 方案 1: VoNR (原生)

```
┌──────┐    ┌─────┐    ┌─────────┐    ┌─────────┐
│  UE  │───▶│ gNB │───▶│   5GC   │───▶│   IMS   │
└──────┘    └─────┘    └─────────┘    └─────────┘
              5G NR        ↑               ↑
                     PCF + SMF + UPF    Kamailio
```

- **优点**: 纯 5G 体验，低延迟
- **要求**: UE、gNB、5GC、IMS 全部支持 VoNR

### 方案 2: EPS Fallback (EPSFB)

当发起语音呼叫时，UE 回落到 4G 使用 VoLTE：

```
                           呼叫发起
┌──────┐    ┌─────┐         │          ┌─────┐    ┌─────────┐
│  UE  │───▶│ gNB │─────────┼─────────▶│ eNB │───▶│   EPC   │───▶ IMS
└──────┘    └─────┘         │          └─────┘    └─────────┘
              5G NR    Handover to 4G    4G LTE      VoLTE
```

- **优点**: 复用现有 VoLTE 基础设施
- **缺点**: 呼叫建立延迟增加 (需要网络切换)
- **适用**: 5G 初期部署，VoNR 未就绪时

### 方案 3: VoWiFi (Voice over WiFi)

通过 WiFi 接入 IMS：

```
┌──────┐    ┌──────┐    ┌─────────┐    ┌─────────┐
│  UE  │───▶│ WiFi │───▶│  ePDG   │───▶│   IMS   │
└──────┘    └──────┘    └─────────┘    └─────────┘
```

- **优点**: 不依赖蜂窝覆盖
- **要求**: ePDG (Evolved Packet Data Gateway)

## SMS 在 LTE/5G 中的处理

SMS 与语音是**独立的服务**，VoLTE/VoNR 解决了语音问题，但 SMS 需要单独处理。

### 传统 SMS vs LTE/5G SMS

```
传统 2G/3G SMS:
┌──────┐    电路交换信令    ┌──────┐    ┌──────┐
│  UE  │ ─────────────────▶│ MSC  │───▶│ SMSC │
└──────┘     (SS7/MAP)     └──────┘    └──────┘

LTE/5G 没有电路交换，需要其他方案！
```

### LTE/5G 中的 SMS 方案

#### 方案 1: SMS over IMS (SMSoIP)

SMS 通过 IMS 以 SIP MESSAGE 方式传输：

```
┌──────┐         ┌─────────┐         ┌───────────┐         ┌──────┐
│  UE  │──SIP───▶│ P-CSCF  │────────▶│ IP-SM-GW  │────────▶│ SMSC │
└──────┘ MESSAGE └─────────┘         └───────────┘  MAP    └──────┘
                   (IMS)            (SIP ↔ MAP 转换)
```

**组件**:
- **IP-SM-GW** (IP Short Message Gateway): 将 SIP MESSAGE 转换为传统 SMSC 协议
- **SMSC**: 短信中心，存储转发短信

**优点**: 复用 IMS 基础设施
**Kamailio 支持**: 需要配置 SIP MESSAGE 路由到 IP-SM-GW

#### 方案 2: SMS over NAS (SMSoNAS)

SMS 通过 NAS 信令传输（不经过 IMS）：

```
4G:
┌──────┐    NAS     ┌──────┐    SGd     ┌──────┐
│  UE  │──────────▶│ MME  │───────────▶│ SMSC │
└──────┘           └──────┘  (Diameter) └──────┘

5G:
┌──────┐    NAS     ┌──────┐    N21     ┌──────┐
│  UE  │──────────▶│ AMF  │───────────▶│ SMSF │───▶ SMSC
└──────┘           └──────┘            └──────┘
```

**5G 特有网元**:
- **SMSF** (SMS Function): 5G 核心网中的短信功能网元

**优点**: 不依赖 IMS
**Open5GS**: 目前 SMSoNAS 支持有限

#### 方案 3: CSFB for SMS (仅 4G)

回落到 2G/3G 网络发送 SMS（过时方案）

### SMS 方案对比

| 方案 | 依赖 IMS | 需要额外组件 | Open5GS 支持 |
|------|----------|--------------|--------------|
| SMSoIP | ✅ 是 | IP-SM-GW, SMSC | 需要配置 Kamailio |
| SMSoNAS (4G) | ❌ 否 | SMSC | 有限 |
| SMSoNAS (5G) | ❌ 否 | SMSF, SMSC | 开发中 |
| CSFB | ❌ 否 | 2G/3G 网络 | N/A |

### 实际部署建议

对于实验环境：
1. **最简方案**: 暂不实现 SMS（仅测试语音）
2. **SMSoIP**: 如果已有 IMS (Kamailio)，添加 IP-SM-GW
3. **开源 SMSC**: 可考虑使用 [Osmocom](https://osmocom.org/) 项目的 OsmoMSC

> **注意**: SMS 功能在私有 LTE/5G 网络中通常不是必须的，许多部署选择跳过 SMS，使用 OTT 消息应用（如微信、WhatsApp）替代。

## 部署考虑

### 系统组件清单

| 组件 | 实现 | 用途 |
|------|------|------|
| EPC/5GC | Open5GS | 核心网 |
| P-CSCF | Kamailio | SIP 代理 |
| I-CSCF | Kamailio | 入口控制 |
| S-CSCF | Kamailio | 服务控制 |
| HSS | Open5GS / FHoSS | 用户数据 |
| DNS | dnsmasq / BIND | 域名解析 |
| RTPProxy | rtpproxy | 媒体中继 |

### 网络要求

- **延迟**: 语音对延迟敏感，网络延迟应 < 100ms
- **QoS**: 需要正确配置 QoS 承载
- **IP 连通性**: UE 需要能够访问 P-CSCF

### UE 要求

- 支持 VoLTE/VoNR
- 正确的 IMS APN 配置
- 匹配的 USIM 配置（ISIM 或配置在 USIM 中）

## 调试工具

```bash
# 抓包分析
wireshark -f "sip or diameter or gtpv2 or s1ap or ngap"

# Wireshark 过滤器
# VoLTE 相关协议
sip || diameter || diameter.3gpp || gtpv2

# 5G VoNR
sip || diameter || pfcp || ngap
```

## 参考资料

- [Open5GS VoLTE Tutorial](https://open5gs.org/open5gs/docs/tutorial/02-VoLTE-setup/)
- [Kamailio IMS Modules](https://www.kamailio.org/docs/modules/)
- [3GPP TS 23.228](https://www.3gpp.org/ftp/Specs/archive/23_series/23.228/) - IMS 架构规范

## 下一步

- [Open5GS 配置](/open5gs/configuration) - 配置 EPC/5GC
- [用户管理](/open5gs/subscriber) - 添加 IMS 用户

