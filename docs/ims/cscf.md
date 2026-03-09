# 三大 CSCF 详解

CSCF（Call Session Control Function）是 IMS 的控制核心，分为 P-CSCF、I-CSCF、S-CSCF。  
可以把它们理解为：入口代理（P）、入口查询与分发（I）、核心业务控制（S）。

## 1) P-CSCF：UE 的第一接触点

P-CSCF（Proxy CSCF）是终端进入 IMS 的第一跳，所有 UE SIP 信令都先到 P-CSCF。

### 主要功能

- SIP 信令入口：接收 UE 的 `REGISTER`、`INVITE`、`MESSAGE` 等请求
- 安全关联：与 UE 建立 IPSec/TLS 等安全通道（部署策略相关）
- 消息规范化：头域检查、压缩解压、NAT/路由适配
- 策略联动：与 PCRF/PCF 交互（Rx/N5）为语音请求 QoS 资源
- 上游转发：把请求送往 I-CSCF 或既定路由

### 对外通信

- 向 UE：`Gm`（SIP）
- 向 I-CSCF：`Mw`（SIP）
- 向 PCRF/PCF：`Rx`（Diameter）或 `N5`（HTTP2）

## 2) I-CSCF：入口查询与 S-CSCF 选择

I-CSCF（Interrogating CSCF）是 IMS 域入口控制点，核心职责是“查、选、转”。

### 主要功能

- 域入口：接收来自 P-CSCF 或外部网络的 SIP 请求
- 查询 HSS：通过 `Cx` 查询用户归属和可用 S-CSCF（如 UAR/LIR）
- 选择 S-CSCF：根据 HSS 返回结果路由到目标 S-CSCF
- 拓扑隐藏：隐藏内部 S-CSCF 细节，降低暴露面

### 对外通信

- 向 P-CSCF / 外部 IMS：`Mw`（SIP）
- 向 HSS：`Cx`（Diameter）
- 向 S-CSCF：`Mw`（SIP）

## 3) S-CSCF：IMS 业务控制中枢

S-CSCF（Serving CSCF）是 IMS 注册态和会话态的“大脑”。

### 主要功能

- 注册控制：处理 `REGISTER`，维护用户绑定状态
- 鉴权协同：通过 `Cx` 向 HSS 获取鉴权向量并完成 AKA 流程
- 会话控制：处理 `INVITE` 及后续会话状态机
- 业务触发：依据 iFC 触发应用服务器（AS），如补充业务/短信
- 用户定位：记录用户当前可达位置与接入信息

### 对外通信

- 向 I-CSCF：`Mw`（SIP）
- 向 HSS：`Cx`（Diameter）
- 向 AS：`ISC`（SIP）

## 三者关系总览（谁和谁说话）

```mermaid
flowchart LR
    ue[UE]
    pcscf[P_CSCF]
    icscf[I_CSCF]
    scscf[S_CSCF]
    hss[HSS]
    pcrfpcf[PCRF_or_PCF]
    asNode[ApplicationServer]

    ue -->|Gm SIP| pcscf
    pcscf -->|Mw SIP| icscf
    icscf -->|Mw SIP| scscf
    icscf <--> |Cx Diameter| hss
    scscf <--> |Cx Diameter| hss
    pcscf <--> |Rx_or_N5| pcrfpcf
    scscf <--> |ISC SIP| asNode
```

## 注册阶段的分工（时序）

```mermaid
sequenceDiagram
    participant UE
    participant P as P_CSCF
    participant I as I_CSCF
    participant S as S_CSCF
    participant H as HSS

    UE->>P: REGISTER
    P->>I: REGISTER
    I->>H: UAR 查询用户归属
    H-->>I: UAA 返回可用 S_CSCF
    I->>S: REGISTER
    S->>H: MAR 获取鉴权向量
    H-->>S: MAA 返回鉴权数据
    S-->>UE: 401 Unauthorized（经 I/P 转发）
    UE->>P: REGISTER + 鉴权响应
    P->>I: REGISTER + 鉴权响应
    I->>S: REGISTER + 鉴权响应
    S->>H: SAR 更新注册状态
    H-->>S: SAA 确认
    S-->>UE: 200 OK（经 I/P 转发）
```

## 与 Open5GS 的协同关系

- HSS 侧：Open5GS HSS 可通过 `Cx` 为 I-CSCF/S-CSCF 提供鉴权和用户资料
- 策略侧：Open5GS PCRF（4G）或 PCF（5G）通过 `Rx/N5` 与 P-CSCF 交互
- 承载侧：Open5GS EPC/5GC 在收到策略后创建语音 QoS 承载（QCI1/5QI1）

## 关键理解

- P-CSCF 解决“怎么进 IMS”
- I-CSCF 解决“该去哪个 S-CSCF”
- S-CSCF 解决“用户是否可注册、会话如何控制、业务如何触发”
