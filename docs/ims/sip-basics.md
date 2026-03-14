# SIP 协议基础与 IP 电话原理

在进入 IMS 之前，先理解 SIP 和 IP 电话的基本工作方式会更容易。  
本页从“传统电话系统”过渡到“纯 SIP 系统”，再连接回 IMS。

## 从传统电话到 IP 电话

- 传统 PSTN 语音多基于电路交换，一次通话占用固定链路
- IP 电话（VoIP）基于分组交换，把“信令控制”和“媒体传输”分开
- 常见分工是：**SIP 负责信令**，**RTP 负责语音媒体**

这也是后续理解 VoLTE/VoNR 的关键：IMS 主要增强和规范的是 SIP 信令控制链路。

## 什么是 SIP

SIP（Session Initiation Protocol）是文本协议，风格类似 HTTP，采用请求/响应模型。

### SIP URI 格式

SIP 用 URI 标识用户和服务，基本格式：

```
sip:user@domain
```

例如 `sip:alice@example.com`。但在实际抓包中你会看到更复杂的形式，特别是 VoLTE 通话中的 INVITE Request-URI 和 To/From 头：

```
sip:+8613800001234@ims.mnc044.mcc460.3gppnetwork.org;user=phone
```

这里有两个常见参数：

**`user=phone`**：表示 `@` 前面的部分是一个电话号码，而不是普通用户名。SIP Proxy 看到 `user=phone` 后知道应按电话号码路由规则处理（如查号码前缀、匹配 E.164 格式），而不是当作 SIP 账户名去 usrloc 里查找。

**`phone-context`**：当号码不是全球唯一的（非 E.164 格式，如本地分机号）时，`phone-context` 指明号码所属的域或拨号上下文，帮助 Proxy 理解号码含义。完整形式如：

```
sip:1001;phone-context=example.com@ims.example.com;user=phone
```

这里 `1001` 是一个本地号码，`phone-context=example.com` 说明它属于 `example.com` 这个拨号域。

还有一种等价的 `tel:` URI 格式（RFC 3966），有时会出现在 IMS 信令中：

```
tel:+8613800001234
tel:1001;phone-context=example.com
```

SIP Proxy 通常会将 `tel:` URI 转换为带 `user=phone` 的 `sip:` URI 再处理。

| URI 示例 | 含义 |
|----------|------|
| `sip:alice@example.com` | 普通 SIP 用户 |
| `sip:+861380000@ims.example.com;user=phone` | E.164 电话号码（全球唯一） |
| `sip:1001;phone-context=home.example.com@ims.example.com;user=phone` | 本地号码，属于指定拨号域 |
| `tel:+861380000` | tel URI，需转为 sip URI 路由 |

### 常见 SIP 角色

- **UA（User Agent）**：终端（手机、软电话）发起和接收 SIP 消息
- **Registrar**：处理 `REGISTER`，维护用户当前 Contact
- **Proxy**：按路由策略转发请求/应答
- **Redirect Server**：不转发请求，返回新的目标地址给请求方

## 常见 SIP 方法

| 方法 | 用途 |
|------|------|
| `REGISTER` | 用户向 Registrar 注册当前可达地址 |
| `INVITE` | 发起会话（语音/视频） |
| `ACK` | 确认最终应答（通常是 2xx） |
| `BYE` | 主动结束已建立会话 |
| `CANCEL` | 取消尚未建立成功的呼叫 |
| `OPTIONS` | 能力探测与连通性检查 |
| `UPDATE` | 会话中更新 SDP（不创建新对话） |
| `SUBSCRIBE` | 订阅某个事件的状态通知 |
| `NOTIFY` | 服务器向订阅者推送事件状态变化 |
| `PRACK` | 确认临时应答（可靠 1xx 的 ACK） |

## 常见 SIP 响应码

| 类别 | 含义 | 常见码 |
|------|------|--------|
| 1xx | 临时应答（呼叫处理中） | `100 Trying`, `180 Ringing` |
| 2xx | 成功 | `200 OK` |
| 3xx | 重定向 | `302 Moved Temporarily` |
| 4xx | 客户端请求错误 | `401 Unauthorized`, `404 Not Found`, `486 Busy Here` |
| 5xx | 服务器侧错误 | `500 Server Internal Error` |
| 6xx | 全局失败 | `603 Decline` |

## 纯 SIP 架构（不含 IMS）

```mermaid
flowchart LR
    callerUa[CallerUA]
    proxyNode[SIPProxy]
    registrarNode[RegistrarAndLocationService]
    calleeUa[CalleeUA]

    callerUa -->|"REGISTER / INVITE"| proxyNode
    proxyNode -->|"LocationLookup"| registrarNode
    registrarNode -->|"CurrentContact"| proxyNode
    proxyNode -->|"INVITE"| calleeUa
    calleeUa -->|"200OK"| proxyNode
    proxyNode -->|"200OK"| callerUa
```

上图是最小化 VoIP 思路：终端先注册，再通过代理按位置库路由通话。

## SIP 注册流程（REGISTER）

```mermaid
sequenceDiagram
    participant ua as UserAgent
    participant proxy as SIPProxy
    participant reg as Registrar

    ua->>proxy: REGISTER sip:example.com
    proxy->>reg: REGISTER
    reg-->>proxy: 200 OK
    proxy-->>ua: 200 OK
```

实际部署中经常会加鉴权挑战：

- 首次 `REGISTER` 可能返回 `401 Unauthorized`
- UA 带 Digest 凭据重发 `REGISTER`
- 校验成功后返回 `200 OK`

## SIP 呼叫建立流程（INVITE Trapezoid）

```mermaid
sequenceDiagram
    participant caller as CallerUA
    participant proxyA as ProxyA
    participant proxyB as ProxyB
    participant callee as CalleeUA

    caller->>proxyA: INVITE + SDP Offer
    proxyA->>proxyB: INVITE + SDP Offer
    proxyB->>callee: INVITE + SDP Offer

    callee-->>proxyB: 100 Trying
    proxyB-->>proxyA: 100 Trying
    proxyA-->>caller: 100 Trying

    callee-->>proxyB: 180 Ringing
    proxyB-->>proxyA: 180 Ringing
    proxyA-->>caller: 180 Ringing

    callee-->>proxyB: 200 OK + SDP Answer
    proxyB-->>proxyA: 200 OK + SDP Answer
    proxyA-->>caller: 200 OK + SDP Answer

    caller->>proxyA: ACK
    proxyA->>proxyB: ACK
    proxyB->>callee: ACK

    caller-->>callee: RTP Media
    callee-->>caller: RTP Media

    caller->>proxyA: BYE
    proxyA->>proxyB: BYE
    proxyB->>callee: BYE
    callee-->>proxyB: 200 OK
    proxyB-->>proxyA: 200 OK
    proxyA-->>caller: 200 OK
```

## 可靠临时应答：PRACK 与 100rel

在标准 SIP 中，`180 Ringing` 等 1xx 临时应答是**不可靠**的——它们通过 UDP 发送后没有确认机制，丢了就丢了。对于基本的"对方在响铃"提示这无所谓，但 VoLTE 通话中，`183 Session Progress` 临时应答常携带 SDP Answer（用于提前建立媒体路径、播放回铃音），丢失会导致通话无法正常建立。

RFC 3262 引入了 `100rel`（reliable 1xx）机制来解决这个问题。

### 工作原理

```mermaid
sequenceDiagram
    participant A as CallerUA
    participant B as CalleeUA

    A->>B: INVITE（Supported: 100rel）
    B-->>A: 183 Session Progress + SDP Answer<br/>（Require: 100rel, RSeq: 1）
    A->>B: PRACK（RAck: 1）
    B-->>A: 200 OK（对 PRACK 的确认）
    B-->>A: 200 OK（对 INVITE 的最终应答）
    A->>B: ACK
```

要点：

- 被叫在 1xx 应答中加 `Require: 100rel` 头和 `RSeq` 序号，表示"这条临时应答需要确认"
- 主叫收到后发 `PRACK`（Provisional Response ACKnowledgement），携带 `RAck` 头引用对应的 `RSeq`
- 如果主叫不发 PRACK，被叫会重传该 1xx，直到收到 PRACK 或超时

### 为什么在 VoLTE 中常见

VoLTE UE 几乎都使用 `100rel`，因为 `183 Session Progress` 在 VoLTE 通话中承担重要角色：

- 携带 SDP Answer，让双方提前协商媒体参数
- 触发 QoS 资源建立（专用承载/QoS Flow）
- 允许在正式接听前就播放回铃音或彩铃（Early Media）

这些都依赖 183 的可靠送达，因此 `100rel` + `PRACK` 是 VoLTE 的标准做法。

::: warning WebRTC 兼容性问题
WebRTC 客户端（如 JsSIP）通常不支持 PRACK。当 VoLTE UE 发来带 `Require: 100rel` 的 183，而 WebRTC 侧无法回 PRACK 时，VoLTE UE 会超时等待并最终挂断。Signal6A 的 Gateway Kamailio 通过在回复路由中**剥离 `Require` 和 `RSeq` 头**来解决这个问题——把可靠临时应答降级为普通临时应答，让 WebRTC 客户端能正常处理。详见 [Signal6A 网关架构 - 应答处理](/ims/signal6a#_3-7-应答处理)。
:::

## SIP 事件订阅：SUBSCRIBE 与 NOTIFY

除了 REGISTER（注册）和 INVITE（通话），你在 Wireshark 中很可能还会看到 `SUBSCRIBE` 和 `NOTIFY` 消息。这是 SIP 的事件通知框架（RFC 6665），用于让一方订阅另一方的状态变化。

### 基本流程

```mermaid
sequenceDiagram
    participant S as Subscriber
    participant N as Notifier

    S->>N: SUBSCRIBE（Event: xxx, Expires: 3600）
    N-->>S: 200 OK
    N->>S: NOTIFY（当前状态）
    Note over S,N: 状态发生变化时...
    N->>S: NOTIFY（新状态）
    S-->>N: 200 OK
    Note over S,N: 订阅到期前续订
    S->>N: SUBSCRIBE（Expires: 3600）
    N-->>S: 200 OK
    N->>S: NOTIFY（当前状态）
```

关键要素：

- **Event 头**：指定订阅的事件类型（如 `reg`、`presence`、`message-summary`）
- **Expires 头**：订阅有效期（秒），到期前需重新 SUBSCRIBE 续订
- **首条 NOTIFY**：服务器接受订阅后必须立即发一条 NOTIFY，告知当前状态
- **取消订阅**：发送 `Expires: 0` 的 SUBSCRIBE 即可

### 在 IMS 中常见的 SUBSCRIBE

在 VoLTE 实验中你看到的 SUBSCRIBE 通常属于以下几种：

| Event 类型 | 谁发起 | 谁响应 | 用途 |
|-----------|--------|--------|------|
| `reg` | UE | S-CSCF | 注册状态订阅：UE 注册成功后订阅自己的注册状态，S-CSCF 在注册变化时发 NOTIFY |
| `presence` | UE | Presence Server | 在线状态：查询联系人是否在线（实验环境中较少用到） |
| `message-summary` | UE | 语音信箱 AS | 语音留言通知（MWI）：有新留言时推送通知 |

其中 **`reg` 事件**是最常见的——VoLTE UE 注册成功后几乎都会立即发一条 `SUBSCRIBE Event: reg`。这是 3GPP 规范要求的：UE 需要知道自己的注册是否仍然有效，如果 S-CSCF 重启导致注册丢失，NOTIFY 会通知 UE 重新注册。

::: tip 实验中的现象
在 Signal6A 或 Kamailio IMS 部署中，S-CSCF 目前对 `reg` SUBSCRIBE 回复 `200 OK` 但不发送完整的 NOTIFY（参见 [Signal6A 已知问题](/ims/signal6a#_12-已知问题与-todo)）。某些 UE 对此容忍，某些可能因未收到 NOTIFY 而掉注册。
:::

## SIP 路由机制：Via 与 Record-Route

上面的流程中，请求经过多个 Proxy 转发，响应又能原路返回——这是靠 SIP 头域中的路由机制实现的。理解这些头域对后续阅读 CSCF 和 Kamailio 配置非常有帮助。

### Via：响应的回程路径

每个 Proxy 转发请求时，会在消息顶部**添加一条自己的 Via 头**。被叫端收到的 INVITE 可能包含多条 Via，从上到下依次是最近的 Proxy 到最远的发起方：

```
Via: SIP/2.0/TCP proxyB.example.com;branch=z9hG4bK-002
Via: SIP/2.0/TCP proxyA.example.com;branch=z9hG4bK-001
Via: SIP/2.0/UDP caller.example.com;branch=z9hG4bK-000
```

当被叫端发送响应（如 `200 OK`）时，每个 Proxy **按最顶部的 Via 找到上一跳**，转发后**移除自己那条 Via**，这样响应就沿原路一跳一跳回到发起方。

```mermaid
sequenceDiagram
    participant C as Caller
    participant A as ProxyA
    participant B as ProxyB
    participant E as Callee

    C->>A: INVITE（Via: Caller）
    Note over A: 添加 Via: ProxyA
    A->>B: INVITE（Via: ProxyA, Caller）
    Note over B: 添加 Via: ProxyB
    B->>E: INVITE（Via: ProxyB, ProxyA, Caller）

    E-->>B: 200 OK（Via: ProxyB, ProxyA, Caller）
    Note over B: 按 Via 转发，移除自己
    B-->>A: 200 OK（Via: ProxyA, Caller）
    Note over A: 按 Via 转发，移除自己
    A-->>C: 200 OK（Via: Caller）
```

`branch` 参数是每条 Via 的事务标识符，Proxy 用它来将响应匹配到对应的请求事务。

### Record-Route 与 Route：对话内请求的路径

Via 只解决"响应怎么回来"。但通话建立后，后续的对话内请求（如 `BYE`、`re-INVITE`）怎么知道还要经过哪些 Proxy？这靠 **Record-Route** 和 **Route** 头域配合完成。

#### 建立阶段：Proxy 插入 Record-Route

Proxy 在转发 INVITE 时可以插入 `Record-Route` 头，声明"后续对话内请求也必须经过我"。经过多个 Proxy 后，被叫收到的 INVITE 中会积累多条：

```
Record-Route: <sip:proxyB.example.com;lr>
Record-Route: <sip:proxyA.example.com;lr>
```

`200 OK` 会把这些 Record-Route 原样带回给主叫。至此双方都知道了完整的 Proxy 链。

#### 对话内：UA 发 Route 头

通话建立后，UA 发送 BYE、re-INVITE 等对话内请求时，会把之前收到的 Record-Route **反转**后作为 `Route` 头放入请求中。这就是你在抓包中看到的 Route 头——它告诉网络"这条请求要依次经过哪些 Proxy"。

以主叫发 BYE 为例：

```
BYE sip:callee@10.0.0.2 SIP/2.0
Route: <sip:proxyA.example.com;lr>
Route: <sip:proxyB.example.com;lr>
```

每个 Proxy 收到后执行 `loose_route()`：检查最上面的 Route 是不是自己，如果是就剥掉自己那条，按下一条 Route（或 R-URI）继续转发。

```mermaid
sequenceDiagram
    participant C as Caller
    participant A as ProxyA
    participant B as ProxyB
    participant E as Callee

    Note over C: 通话已建立，主叫挂机
    C->>A: BYE（Route: ProxyA, ProxyB）
    Note over A: loose_route() 剥离自己的 Route
    A->>B: BYE（Route: ProxyB）
    Note over B: loose_route() 剥离自己的 Route
    B->>E: BYE（无 Route）
    E-->>B: 200 OK
    B-->>A: 200 OK
    A-->>C: 200 OK
```

#### `;lr` 参数

Route/Record-Route URI 中的 `;lr`（loose-routing）表示该 Proxy 支持 RFC 3261 的松散路由。现代 SIP 系统普遍使用 `;lr`，在 Kamailio 中对应 `loose_route()` 函数。

#### IMS 中的 Service-Route

在实验中你可能注意到，手机发 INVITE 时已经带着 Route 头，但这并不是来自之前的 Record-Route——因为 INVITE 是新的对话，还没有 Record-Route 可反转。

这是因为 IMS 引入了 **Service-Route**：UE 注册成功时，S-CSCF 在 `200 OK` 中返回 `Service-Route` 头（指向 S-CSCF 自己），P-CSCF 也可能追加一条。UE 收到后保存下来，在后续所有新请求（INVITE 等）中自动以 Route 头插入，保证新对话的请求也经过完整的 CSCF 链。

```
INVITE sip:bob@ims.example.com SIP/2.0
Route: <sip:pcscf.example.com;lr>
Route: <sip:scscf.example.com;lr>
```

#### 头域总结

| 头域 | 谁添加 | 何时使用 | 作用 |
|------|--------|----------|------|
| **Via** | 每个 Proxy 转发请求时 | 响应回程 | 让响应沿原路返回，每跳剥离一条 |
| **Record-Route** | 希望留在信令路径上的 Proxy | INVITE 建立对话时 | 告知双方 UA "后续请求要经过我" |
| **Route** | UA 根据 Record-Route 或 Service-Route 生成 | 发送请求时 | 指定请求要依次经过的 Proxy 列表 |
| **Service-Route** | S-CSCF（IMS 扩展） | 注册成功的 200 OK 中 | 让 UE 后续所有新请求都经过 CSCF 链 |
| **Contact** | UA 或 Proxy | 建立对话时 | 告知对端自己的直接可达地址 |

::: tip 与 IMS / Kamailio 的联系
在 IMS 中，P-CSCF 和 S-CSCF 都会插入 `Record-Route`（Kamailio 中调用 `record_route()`），这样通话建立后的 BYE、re-INVITE 仍然经过 CSCF 链，CSCF 才能做媒体控制（如 rtpengine 拆除）和计费。收到对话内请求时，Kamailio 调用 `loose_route()` 按 Route 头逐跳转发。这些都是标准 SIP 机制——IMS 只是强制要求 CSCF 必须使用它们，并通过 Service-Route 扩展到新对话。详见 [CSCF 三大网元详解](/ims/cscf)。
:::

## SIP 事务模型：请求、响应与 CANCEL 的路由规则

前面讲了 Via 控制响应回程、Record-Route/Route 控制对话内请求。但在实际排障中，你还需要理解更底层的问题：**不同类型的 SIP 消息到底遵循什么路由规则？** 响应是自动走回来的还是需要路由？CANCEL 是走新路径还是复用已有路径？ACK 为什么有时候经过 Proxy 有时候不经过？

这些问题的答案来自 SIP 的**事务模型**。

### 什么是 SIP 事务

SIP 事务（Transaction）是一次请求-响应的完整交互。一个事务包含：

- 一个请求（如 INVITE、REGISTER、BYE）
- 该请求的所有响应（临时响应 1xx + 最终响应 2xx/3xx/4xx/5xx/6xx）
- 对于 INVITE 事务，还包括对非 2xx 最终响应的 ACK

事务由 Via 头中的 **`branch` 参数**唯一标识。每个 Proxy 转发请求时生成新的 branch，收到响应时通过 branch 匹配到对应的请求事务。

```mermaid
flowchart TB
    subgraph tx ["一个 INVITE 事务"]
        req["INVITE 请求"]
        r100["100 Trying"]
        r180["180 Ringing"]
        r200["200 OK"]
        req --> r100
        req --> r180
        req --> r200
    end
```

### 三类消息的路由规则

SIP 中所有消息可以分为三类，每类有完全不同的路由机制：

| 类别 | 消息 | 路由方式 | 路由依据 |
|------|------|----------|----------|
| **响应** | 100 Trying, 180 Ringing, 200 OK, 486 Busy, ... | 沿 Via 逐跳回退 | Via 头（事务层自动处理） |
| **事务内请求** | CANCEL, ACK（对非 2xx 响应） | 与原始请求走相同路径 | 匹配原请求的事务状态 |
| **对话内请求** | BYE, re-INVITE, ACK（对 2xx 响应）, UPDATE | 按 Route 头独立路由 | Route 头（来自 Record-Route） |

这三类的关键区别是：**谁决定消息往哪发？**

- 响应：由事务层自动按 Via 转发，Proxy 不需要做路由决策
- CANCEL：由事务层匹配到原 INVITE 事务，发往相同目标
- 对话内请求：由 UA 根据 Route 头构造，走正常的路由流程

### 响应的路由：Via 自动回退

这在 [Via 章节](#via-响应的回程路径)已经介绍过基本原理。这里补充几个重要细节：

**响应不经过 `request_route`。** 在 Kamailio 中，`request_route` 只处理请求。响应由 `tm` 模块（事务管理）自动按 Via 转发。你可以用 `onreply_route` 来修改经过的响应（如剥离头域、改写 SDP），但**不需要也不应该手动路由响应**——事务层已经知道该往哪发。

**100 Trying 是特殊的。** Proxy 收到 INVITE 后通常立即向上游发送自己的 `100 Trying`（表示"我收到了，正在处理"），而不是转发下游的 100 Trying。从上游（主叫侧）来看，它收到的 100 Trying 来自直接相邻的 Proxy，而非被叫。

**1xx 临时响应（180 Ringing, 183 Session Progress）正常转发。** 它们沿 Via 逐跳回退到主叫。在多 Proxy 环境中（如 IMS 的 CSCF 链），被叫发出的 180 Ringing 会经过 P-CSCF → S-CSCF → I-CSCF → Gateway → 主叫，每一跳都由 `tm` 模块自动转发。

### CANCEL 的路由：绑定到 INVITE 事务

CANCEL 用于取消一个正在进行中（已发出 INVITE 但未收到最终响应）的呼叫。它的路由规则是 SIP 中最容易误解的部分之一。

**CANCEL 不是一个独立路由的请求。** 它必须匹配到一个已存在的 INVITE 事务。具体来说：

- CANCEL 的 Call-ID、From-tag、CSeq 编号和 R-URI 必须与原 INVITE 相同
- CANCEL 的顶层 Via branch 必须与原 INVITE 相同
- Proxy 收到 CANCEL 后，在事务层查找匹配的 INVITE 事务，将 CANCEL 转发到**与 INVITE 相同的目标**

```mermaid
sequenceDiagram
    participant A as 主叫
    participant P1 as Proxy A
    participant P2 as Proxy B
    participant B as 被叫

    A->>P1: INVITE（branch=abc）
    P1->>P2: INVITE（branch=def）
    P2->>B: INVITE（branch=ghi）

    B-->>P2: 180 Ringing
    P2-->>P1: 180 Ringing
    P1-->>A: 180 Ringing

    Note over A: 主叫取消呼叫

    A->>P1: CANCEL（branch=abc）
    Note over P1: tm 模块匹配 branch=abc<br/>找到对应 INVITE 事务<br/>→ CANCEL 发往与 INVITE 相同目标
    P1->>P2: CANCEL（branch=def）
    Note over P2: 同理匹配 INVITE 事务
    P2->>B: CANCEL（branch=ghi）

    B-->>P2: 200 OK（对 CANCEL）
    P2-->>P1: 200 OK（对 CANCEL）
    P1-->>A: 200 OK（对 CANCEL）

    B-->>P2: 487 Request Terminated（对 INVITE）
    P2-->>P1: 487 Request Terminated
    P1-->>A: 487 Request Terminated

    A->>P1: ACK（对 487）
    P1->>P2: ACK（对 487）
    P2->>B: ACK（对 487）
```

CANCEL 完成后会产生两个响应：
1. `200 OK` — 对 CANCEL 本身的确认（"我收到了你的取消请求"）
2. `487 Request Terminated` — 对原 INVITE 的最终响应（"原来的通话请求已被终止"）

::: warning CANCEL 只能取消未完成的事务
CANCEL 只对正在处理中的 INVITE（已发送但未收到最终响应）有效。如果被叫已经接听（200 OK 已发出），CANCEL 不起作用——此时需要发 BYE 来结束已建立的通话。这是"取消呼叫"和"挂断电话"的本质区别。
:::

### ACK 的两种路由方式

ACK 是 SIP 中路由规则最复杂的消息，因为**对 2xx 和对非 2xx 响应的 ACK 走完全不同的路径**：

#### ACK 对 2xx（通话建立成功）：端到端，走对话路由

当被叫接听（200 OK），主叫发出的 ACK 是一个**新事务**，走对话路由——和 BYE 一样，按 Route 头（来自 200 OK 的 Record-Route 反转）逐跳转发：

```mermaid
sequenceDiagram
    participant A as 主叫
    participant P as Proxy（Record-Route）
    participant B as 被叫

    B-->>P: 200 OK（Record-Route: Proxy）
    P-->>A: 200 OK

    A->>P: ACK（Route: Proxy）
    Note over P: 按 Route 头转发（loose_route）
    P->>B: ACK
```

这个 ACK 经过所有插入了 Record-Route 的 Proxy。这也是为什么 Kamailio 的 WITHINDLG 路由中需要处理 ACK——它和 BYE 一样是对话内请求，经过 `loose_route()` 转发。

#### ACK 对非 2xx（通话失败/拒绝/取消）：事务层自动，逐跳

当 INVITE 收到 4xx/5xx/6xx 最终响应（如 486 Busy、487 Terminated、603 Decline），每个 Proxy **自动在事务层生成 ACK** 发给下游，同时将该错误响应转发给上游。这个 ACK 不需要路由配置，完全由 `tm` 模块处理。

```mermaid
sequenceDiagram
    participant A as 主叫
    participant P as Proxy
    participant B as 被叫

    B-->>P: 486 Busy Here
    Note over P: tm 自动生成 ACK 发给 B<br/>同时转发 486 给 A
    P->>B: ACK（自动生成）
    P-->>A: 486 Busy Here
    A->>P: ACK
```

#### 为什么 ACK 要区分对待？

设计原因是可靠性。2xx 响应表示通话建立成功——这个 ACK 必须端到端送达被叫，确认通话已建立。如果中间 Proxy 不在对话路径上（没有 Record-Route），ACK 就直接从主叫发到被叫。

非 2xx 响应表示通话失败——不需要端到端确认，只需要每一跳逐级确认收到了错误响应。Proxy 自动完成这件事。

### 完整呼叫流程中的消息分类

把以上规则应用到一个完整的呼叫流程中：

```mermaid
sequenceDiagram
    participant A as 主叫
    participant P as SIP Proxy
    participant B as 被叫

    rect rgb(230, 245, 255)
        Note over A,B: INVITE 事务
        A->>P: INVITE
        P->>B: INVITE
        B-->>P: 100 Trying
        P-->>A: 100 Trying
        B-->>P: 180 Ringing
        P-->>A: 180 Ringing
        B-->>P: 200 OK
        P-->>A: 200 OK
    end

    rect rgb(230, 255, 230)
        Note over A,B: ACK（新事务，对话内请求）
        A->>P: ACK（按 Route 头路由）
        P->>B: ACK
    end

    rect rgb(255, 255, 230)
        Note over A,B: RTP 媒体流
        A-->>B: RTP 语音
        B-->>A: RTP 语音
    end

    rect rgb(255, 230, 230)
        Note over A,B: BYE 事务（对话内请求）
        A->>P: BYE（按 Route 头路由）
        P->>B: BYE
        B-->>P: 200 OK
        P-->>A: 200 OK
    end
```

| 消息 | 所属类别 | 路由方式 |
|------|----------|----------|
| INVITE | 初始请求 | Proxy 按路由逻辑决定（`request_route`） |
| 100 Trying | 响应 | Proxy 自动生成，不转发下游的 |
| 180 Ringing | 响应 | 沿 Via 逐跳自动回退 |
| 200 OK | 响应 | 沿 Via 逐跳自动回退 |
| ACK（对 200） | 对话内请求 | 按 Route 头路由（`loose_route()`） |
| BYE | 对话内请求 | 按 Route 头路由（`loose_route()`） |

### 在 IMS CSCF 链中的实际路径

将这些规则应用到 IMS 的 CSCF 链中——以 VoLTE UE 呼叫 WebRTC 用户为例，展示通话建立和取消两种场景中各类消息的路径：

#### 场景 A：正常接听

```mermaid
sequenceDiagram
    participant UE as VoLTE UE
    participant P as P-CSCF
    participant I as I-CSCF
    participant S as S-CSCF
    participant GW as Gateway
    participant B as Browser

    Note over UE,B: ── INVITE 事务 ──
    UE->>P: INVITE
    P->>I: INVITE
    I->>S: INVITE
    S->>GW: INVITE
    GW->>B: INVITE

    Note over UE,B: 响应沿 Via 自动回退
    B-->>GW: 180 Ringing
    GW-->>S: 180 Ringing
    S-->>I: 180 Ringing
    I-->>P: 180 Ringing
    P-->>UE: 180 Ringing

    B-->>GW: 200 OK + SDP
    Note over GW: onreply_route:<br/>rtpengine 处理 SDP Answer
    GW-->>S: 200 OK
    S-->>I: 200 OK
    I-->>P: 200 OK
    P-->>UE: 200 OK

    Note over UE,B: ── ACK 对话内路由 ──
    UE->>P: ACK（Route 头）
    Note over P: loose_route()
    P->>S: ACK
    Note over S: loose_route()
    S->>GW: ACK
    Note over GW: loose_route() + rtpengine
    GW->>B: ACK
```

每个节点的 `onreply_route` 可以修改经过的响应（如 Gateway 剥离 100rel 头、处理 SDP），但**不需要决定响应往哪发**——`tm` 模块自动按 Via 转发。

#### 场景 B：主叫取消

```mermaid
sequenceDiagram
    participant UE as VoLTE UE
    participant P as P-CSCF
    participant I as I-CSCF
    participant S as S-CSCF
    participant GW as Gateway
    participant B as Browser

    UE->>P: INVITE
    P->>I: INVITE
    I->>S: INVITE
    S->>GW: INVITE
    GW->>B: INVITE

    B-->>GW: 180 Ringing
    GW-->>S: 180 Ringing
    S-->>I: 180 Ringing
    I-->>P: 180 Ringing
    P-->>UE: 180 Ringing

    Note over UE: UE 挂断（未接通）

    UE->>P: CANCEL
    Note over P: 匹配 INVITE 事务<br/>转发到与 INVITE 相同目标
    P->>I: CANCEL
    I->>S: CANCEL
    S->>GW: CANCEL
    GW->>B: CANCEL

    B-->>GW: 200 OK（对 CANCEL）
    GW-->>S: 200 OK
    S-->>I: 200 OK
    I-->>P: 200 OK
    P-->>UE: 200 OK

    B-->>GW: 487 Request Terminated（对 INVITE）
    Note over GW: rtpengine_delete()
    GW-->>S: 487
    S-->>I: 487
    I-->>P: 487
    P-->>UE: 487

    Note over UE,B: 每个节点的 tm 自动生成 ACK（对 487）逐跳确认
```

CANCEL 在每个 Proxy 节点上都由 `tm` 模块匹配到对应的 INVITE 事务后自动转发。在 Kamailio 的 `request_route` 中你只需要：

```
if (is_method("CANCEL")) {
    if (t_check_trans())    // 找到匹配的 INVITE 事务
        t_relay();          // 转发 CANCEL
    exit;
}
```

不需要做任何路由决策——目标地址已经由 INVITE 事务决定了。

### 小结：排障思维

理解这三类路由规则后，排障时可以按类型定位问题：

| 症状 | 可能的消息类型问题 | 排查方向 |
|------|-------------------|----------|
| 主叫听不到回铃音 | 180 Ringing 响应未到达 | 检查 Via 路径上每一跳是否有状态转发（`t_relay()`）；检查防火墙是否阻断了响应 |
| CANCEL 后对方仍在响铃 | CANCEL 未匹配到 INVITE 事务 | 检查 CANCEL 是否到达了所有 Proxy；检查 `t_check_trans()` 是否成功 |
| 通话接通但无法挂断 | BYE 路由失败 | 检查 Record-Route 是否正确插入；检查 `loose_route()` 是否成功 |
| ACK 未到达被叫 | ACK（对 2xx）路由失败 | 检查 Route 头是否正确（来自 Record-Route 反转）；检查 WITHINDLG 路由 |


## SDP 与媒体协商（Offer/Answer）

SIP 消息中的媒体参数通常由 SDP 承载：

- `m=`：媒体类型与端口（如音频）
- `c=`：连接地址（IP）
- `a=`：媒体属性（编解码、方向、RTCP、加密参数等）

典型模式是：

1. 主叫在 `INVITE` 携带 SDP Offer
2. 被叫在 `200 OK` 返回 SDP Answer
3. 双方据此确定编解码和媒体端口

## RTP：媒体面

SIP 只管“怎么建立/结束会话”，不直接承载语音流。  
语音通常走 RTP（或加密版 SRTP），并使用与 SIP 不同的端口和路径。

这也是为什么很多系统会出现“信令通了但没声音”：信令面（SIP）和媒体面（RTP）需分别排障。

关于 RTP 的详细工作原理、音频编解码（AMR-WB、Opus 等）、以及 rtpengine 如何作为媒体代理改变通话的媒体路径，请参见 [RTP 与实时音频传输](/ims/rtp)。

## SIP 与 IMS 的关系

IMS 不是替代 SIP，而是在运营商级网络里对 SIP 做体系化增强：

- 增加 CSCF 链路（P-CSCF / I-CSCF / S-CSCF）
- 用 Diameter 对接 HSS 做鉴权和用户资料管理
- 与 PCRF/PCF 联动 QoS 策略
- 增加 IPsec/sec-agree 等移动网络安全机制

```mermaid
flowchart LR
    sipCore[PlainSIPSystem] --> imsCore[IMSSystem]
    sipCore --> sipFeature1[SIPSignaling]
    sipCore --> sipFeature2[RTPMedia]
    imsCore --> imsFeature1[CSCFChain]
    imsCore --> imsFeature2[DiameterCxRx]
    imsCore --> imsFeature3[QoSIntegration]
    imsCore --> imsFeature4[IPsecSecurity]
```

继续阅读：

- [RTP 与实时音频传输](/ims/rtp) — RTP 协议、音频编解码与 rtpengine 媒体代理
- [CSCF 三大网元详解](/ims/cscf)
- [IMS 注册与入网流程](/ims/registration)
