# VoLTE/VoNR 与 IMS 集成

本文档从 IMS 视角介绍 VoLTE（4G）和 VoNR（5G）语音系统，重点说明与 Open5GS 的协同方式，以及部署时的关键配置点。

## 什么是 VoLTE / VoNR

- VoLTE：在 LTE/EPC 上通过 IMS 提供语音
- VoNR：在 5G SA/5GC 上通过 IMS 提供语音
- 两者都走分组交换（PS），核心控制面均为 SIP + IMS

```mermaid
flowchart LR
    ue[UE]
    core[EPC_or_5GC]
    ims[IMS_Core]
    pstn[PSTN_or_SIP_Peer]

    ue -->|IP_voice_signaling_and_media| core
    core -->|service_control| ims
    ims -->|interconnect| pstn
```

## VoLTE 与 VoNR 架构对比

```mermaid
flowchart TB
    subgraph ltePath [VoLTE_4G]
        ue4[UE]
        enb[eNB]
        epc[EPC_MME_SGW_PGW_PCRF]
        ims4[IMS]
        ue4 --> enb --> epc --> ims4
    end

    subgraph nrPath [VoNR_5G]
        ue5[UE]
        gnb[gNB]
        core5[Core5G_AMF_SMF_UPF_PCF]
        ims5[IMS]
        ue5 --> gnb --> core5 --> ims5
    end
```

| 功能域 | VoLTE (4G) | VoNR (5G) |
|------|------------|-----------|
| 接入与移动性 | MME | AMF |
| 会话控制 | EPC 会话链路 | SMF |
| 用户面 | SGW/PGW | UPF |
| 策略控制 | PCRF | PCF |
| IMS 接口 | Rx + Cx | N5/Rx + Cx |

## IMS 与 Open5GS 的连接关系

在本项目中，Open5GS 负责接入/核心承载，IMS（常用 Kamailio 承担 CSCF）负责语音业务控制。

```mermaid
flowchart LR
    subgraph open5gs [Open5GS]
        hss[HSS]
        pcrfpcf[PCRF_or_PCF]
        epc5gc[EPC_or_5GC]
    end

    subgraph imsCore [IMS]
        p[P_CSCF]
        i[I_CSCF]
        s[S_CSCF]
    end

    ue[UE] -->|SIP Gm| p
    p --> i --> s
    i <--> |Cx| hss
    s <--> |Cx| hss
    p <--> |Rx_or_N5| pcrfpcf
    epc5gc <--> hss
    epc5gc <--> pcrfpcf
```

## QoS 建立关键路径（语音质量保障）

```mermaid
sequenceDiagram
    participant UE
    participant P as P_CSCF
    participant Policy as PCRF_or_PCF
    participant Core as EPC_or_5GC

    UE->>P: INVITE + SDP
    P->>Policy: Rx_or_N5 QoS 请求
    Policy->>Core: Gx_or_N7 下发策略
    Core-->>UE: 建立语音专用资源(QCI1_or_5QI1)
```

## Cx（HSS）配置思路

I-CSCF 与 S-CSCF 都需要通过 Cx 接口访问 HSS，以完成：

- 用户归属查询（选择 S-CSCF）
- 鉴权向量获取（AKA）
- 注册状态更新（用户绑定）

可采用两种模式：

1. 独立 IMS HSS（如 FHoSS）
2. 复用 Open5GS HSS（本项目侧重该模式）

## APN / DNN 设计

VoLTE/VoNR 建议至少区分两个数据通道：

- `internet`：普通数据业务
- `ims`：IMS 信令和语音相关业务

```yaml
session:
  - subnet: 10.45.0.1/16
    dnn: internet
  - subnet: 10.46.0.1/16
    dnn: ims
```

## DNS 在 IMS 中的作用

IMS 强依赖 DNS 进行网元发现，典型域名：

- `ims.mncXXX.mccXXX.3gppnetwork.org`
- `epc.mncXXX.mccXXX.3gppnetwork.org`

至少需要保证：

- P-CSCF/I-CSCF/S-CSCF 的 A/AAAA 记录
- SIP SRV 记录（用于服务发现）
- UE 能通过 PCO 拿到可用 DNS

## 通话建立（简化）

```mermaid
sequenceDiagram
    participant A as UE_A
    participant IMS as IMS_Core
    participant B as UE_B

    A->>IMS: INVITE
    IMS->>B: INVITE
    B-->>IMS: 180 Ringing
    IMS-->>A: 180 Ringing
    B-->>IMS: 200 OK
    IMS-->>A: 200 OK
    A->>IMS: ACK
    IMS->>B: ACK
    A<<->>B: RTP Media
```

## IMS 域内通话完整流程

上图将 IMS 简化为一个黑盒。下面展开 CSCF 链路，展示两个 VoLTE UE 在同一 IMS 域内通话时，INVITE 如何在各网元之间路由：

```mermaid
sequenceDiagram
    participant A as UE_A（主叫）
    participant PA as P-CSCF_A
    participant I as I-CSCF
    participant S as S-CSCF
    participant H as HSS
    participant PB as P-CSCF_B
    participant B as UE_B（被叫）

    Note over A: UE_A 已注册，拨打 UE_B 号码

    A->>PA: INVITE sip:UE_B@ims.example.com（IPsec）
    Note over PA: 发起方向：UE_A 已注册<br/>→ 缓存 UE_A 地址<br/>→ 转发到 I-CSCF

    PA->>I: INVITE
    I->>H: Diameter LIR（查 UE_B 的 S-CSCF）
    H-->>I: LIA（返回 S-CSCF 地址）
    I->>S: INVITE

    Note over S: lookup("location") 成功<br/>→ UE_B 已注册，Contact 指向 P-CSCF_B（经 Path）

    S->>PB: INVITE
    Note over PB: 终结方向：请求来自 IMS 核心<br/>→ ipsec_forward() 解析 UE_B 的 IPsec 地址
    PB->>B: INVITE（IPsec）

    B-->>PB: 180 Ringing
    PB-->>S: 180 Ringing
    S-->>I: 180 Ringing
    I-->>PA: 180 Ringing
    PA-->>A: 180 Ringing

    B-->>PB: 200 OK + SDP Answer
    PB-->>S: 200 OK
    S-->>I: 200 OK
    I-->>PA: 200 OK
    PA-->>A: 200 OK

    A->>PA: ACK
    PA->>I: ACK
    I->>S: ACK
    S->>PB: ACK
    PB->>B: ACK

    Note over A,B: RTP/AMR-WB 语音媒体（UE 之间直接或经 rtpengine）
```

### 路由关键点

上面的流程中有几个值得注意的细节：

**主叫侧 P-CSCF 与被叫侧 P-CSCF 可以相同也可以不同。** 在实验环境中通常只有一个 P-CSCF 实例（`PA` 和 `PB` 是同一进程），但在运营商网络中，主叫和被叫可能接入不同地区的 P-CSCF。

**I-CSCF 在域内通话中仍然参与。** 即使主叫和被叫在同一 S-CSCF 上，P-CSCF 也不会直接发到 S-CSCF——它总是先经过 I-CSCF，由 I-CSCF 查 HSS 决定路由。这保证了架构的一致性和 S-CSCF 分配的灵活性（参见 [为什么 I-CSCF 和 S-CSCF 要分开](/ims/cscf#为什么-i-cscf-和-s-cscf-要分开)）。

**S-CSCF 的 `lookup()` 是决策点。** 如果被叫在 IMS 中注册，S-CSCF 通过 Contact + Path 将 INVITE 路由到被叫的 P-CSCF。如果未注册，则触发 Gateway 回落（见 [Signal6A 桥接机制](/ims/signal6a#_7-桥接-webrtc-↔-ims)）或返回 404。

**媒体路径取决于部署。** 同域 VoLTE 通话中，如果两个 UE 都使用 AMR-WB 且无需转码，RTP 可以直接在 UE 之间流动（或经 P-CSCF 的 rtpengine 锚定以维持 NAT 穿越）。跨域通话才必须经 rtpengine 转码。

## SMS 在 LTE/5G 的位置

VoLTE/VoNR 解决的是语音，SMS 需要单独方案：

- SMSoIP：经 IMS（SIP MESSAGE + IP-SM-GW）
- SMSoNAS：经 NAS（4G/5G 核心侧链路）

实验环境中可先聚焦语音注册与呼叫，SMS 按需补齐。

## 部署建议（实验优先）

- 先打通：UE 入网 -> IMS 注册 -> 语音呼叫
- 再优化：QoS 保证、DNS 完整性、跨域互通
- 最后扩展：SMS、补充业务、AS 触发链路

## 参考资料

- [Open5GS VoLTE Tutorial](https://open5gs.org/open5gs/docs/tutorial/02-VoLTE-setup/)
- [Kamailio IMS Modules](https://www.kamailio.org/docs/modules/)
- [3GPP TS 23.228](https://www.3gpp.org/ftp/Specs/archive/23_series/23.228/)
