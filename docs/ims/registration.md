# IMS 注册与入网流程

本页回答两个关键问题：

1. 手机如何先加入 4G/5G 核心网（Open5GS）  
2. 加入核心网后，手机如何完成 IMS 注册并具备语音能力

## 阶段 A：先入网（非 IMS）

IMS 注册前，UE 必须先完成无线接入、鉴权和数据会话建立。

### 5G SA 入网（UE 加入 Open5GS 5GC）

```mermaid
sequenceDiagram
    participant UE
    participant gNB
    participant AMF
    participant AUSF
    participant UDM
    participant SMF
    participant UPF

    UE->>gNB: RRC 建链 + NAS Registration Request
    gNB->>AMF: N2 Registration
    AMF->>AUSF: 鉴权请求
    AUSF->>UDM: 获取鉴权数据
    UDM-->>AUSF: 返回鉴权向量
    AUSF-->>AMF: 鉴权结果
    AMF-->>UE: Registration Accept
    UE->>AMF: PDU Session Establishment（ims 或 internet）
    AMF->>SMF: N11 建立会话
    SMF->>UPF: N4 建立用户面规则
    UPF-->>UE: 分配 UE IP（通过用户面生效）
```

### 4G LTE 入网（UE 加入 Open5GS EPC）

```mermaid
sequenceDiagram
    participant UE
    participant eNB
    participant MME
    participant HSS
    participant SGW
    participant PGW

    UE->>eNB: Attach Request
    eNB->>MME: S1AP + NAS Attach
    MME->>HSS: S6a 鉴权与用户资料
    HSS-->>MME: 鉴权向量/订阅数据
    MME->>SGW: Create Session
    SGW->>PGW: Create Session
    PGW-->>UE: 分配 UE IP（APN 如 ims）
    MME-->>UE: Attach Accept
```

## 阶段 B：发现 P-CSCF

UE 建立 IMS APN/PDU 后，需要知道 P-CSCF 地址，常见来源：

- PCO 下发（核心网在会话建立阶段提供）
- DNS SRV/A 查询（例如 `ims.mncXXX.mccXXX.3gppnetwork.org`）

## 阶段 C：IMS 注册（REGISTER）

```mermaid
sequenceDiagram
    participant UE
    participant P as P_CSCF
    participant I as I_CSCF
    participant S as S_CSCF
    participant H as HSS

    UE->>P: REGISTER（首包，无鉴权）
    P->>I: 转发 REGISTER
    I->>H: Cx UAR 查询用户归属
    H-->>I: UAA（返回可用 S_CSCF）
    I->>S: 转发 REGISTER
    S->>H: Cx MAR 获取鉴权向量
    H-->>S: MAA 鉴权向量
    S-->>UE: 401 Unauthorized（经 I/P 回传）
    UE->>P: REGISTER + AKA 响应
    P->>I: 转发
    I->>S: 转发
    S->>H: Cx SAR 更新注册状态
    H-->>S: SAA
    S-->>UE: 200 OK（注册成功）
```

## 阶段 D：语音呼叫建立（谁在何时说话）

下面示例是主叫发起 INVITE 后的关键控制流程：

```mermaid
sequenceDiagram
    participant UE as UE_Caller
    participant P as P_CSCF
    participant S as S_CSCF
    participant Policy as PCRF_or_PCF
    participant Core as EPC_or_5GC
    participant UEb as UE_Callee

    UE->>P: INVITE（SDP 携带媒体能力）
    P->>Policy: Rx_or_N5 授权请求（AAR 或 API）
    Policy-->>Core: 下发策略（Gx_or_N7）
    Core-->>UE: 建立语音 QoS（QCI1_or_5QI1）
    P->>S: 转发 INVITE
    S->>UEb: 路由到被叫侧
    UEb-->>S: 180 Ringing / 200 OK
    S-->>P: 回传应答
    P-->>UE: 回传应答
    UE->>P: ACK
    P->>S: ACK
```

## 4G 与 5G 的关键差异

| 维度 | 4G VoLTE | 5G VoNR |
|------|----------|----------|
| 接入核心 | EPC（MME/SGW/PGW） | 5GC（AMF/SMF/UPF） |
| 策略控制 | PCRF（Rx + Gx） | PCF（N5/Rx + N7） |
| 语音承载 | Dedicated Bearer（QCI1） | QoS Flow（5QI1） |
| IMS 控制 | P/I/S-CSCF（相同） | P/I/S-CSCF（相同） |

## 一句话总结

- UE 先“入网拿 IP”，再“注册 IMS”
- CSCF 负责 SIP 控制，Open5GS 负责接入/会话/承载
- 策略网元（PCRF/PCF）把语音会话映射成可保障的 QoS 资源
