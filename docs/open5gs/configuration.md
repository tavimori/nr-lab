# Open5GS 配置详解

本页面详细介绍 Open5GS 各网元的配置参数。

## 配置文件概述

所有配置文件位于 `/etc/open5gs/`，使用 YAML 格式。

## AMF 配置

AMF (Access and Mobility Management Function) 是 5G 核心网的入口，处理来自 gNB 的 N2 连接。

配置文件: `/etc/open5gs/amf.yaml`

```yaml
amf:
  sbi:
    server:
      - address: 127.0.0.5
        port: 7777
    client:
      nrf:
        - uri: http://127.0.0.10:7777

  ngap:
    server:
      - address: 192.168.1.10  # gNB 连接的地址
        port: 38412

  metrics:
    server:
      - address: 127.0.0.5
        port: 9090

  guami:
    - plmn_id:
        mcc: 001
        mnc: 01
      amf_id:
        region: 2
        set: 1
        pointer: 0

  tai:
    - plmn_id:
        mcc: 001
        mnc: 01
      tac: 1

  plmn_support:
    - plmn_id:
        mcc: 001
        mnc: 01
      s_nssai:
        - sst: 1
          sd: 000001

  security:
    integrity_order: [NIA2, NIA1, NIA0]
    ciphering_order: [NEA0, NEA1, NEA2]

  network_name:
    full: Open5GS
    short: O5GS

  amf_name: open5gs-amf0
```

### 关键参数说明

| 参数 | 说明 |
|------|------|
| `ngap.server.address` | gNB 连接的 IP 地址，需要 gNB 可达 |
| `guami` | 全局唯一 AMF 标识 |
| `tai` | 跟踪区标识，需与 gNB 配置一致 |
| `plmn_support` | 支持的 PLMN 和切片信息 |
| `s_nssai` | 网络切片选择辅助信息 |

## SMF 配置

SMF (Session Management Function) 管理 PDU 会话。

配置文件: `/etc/open5gs/smf.yaml`

```yaml
smf:
  sbi:
    server:
      - address: 127.0.0.4
        port: 7777
    client:
      nrf:
        - uri: http://127.0.0.10:7777

  pfcp:
    server:
      - address: 127.0.0.4
    client:
      upf:
        - address: 127.0.0.7

  gtpc:
    server:
      - address: 127.0.0.4

  gtpu:
    server:
      - address: 127.0.0.4

  metrics:
    server:
      - address: 127.0.0.4
        port: 9090

  session:
    - subnet: 10.45.0.1/16
      gateway: 10.45.0.1
      dnn: internet
```

### 关键参数说明

| 参数 | 说明 |
|------|------|
| `pfcp.client.upf` | UPF 的 PFCP 地址 |
| `session.subnet` | 分配给 UE 的 IP 地址池 |
| `session.dnn` | 数据网络名称 |

## UPF 配置

UPF (User Plane Function) 处理用户数据转发。

配置文件: `/etc/open5gs/upf.yaml`

```yaml
upf:
  pfcp:
    server:
      - address: 127.0.0.7

  gtpu:
    server:
      - address: 192.168.1.10  # gNB 连接的地址

  session:
    - subnet: 10.45.0.1/16
      gateway: 10.45.0.1
      dnn: internet
      dev: ogstun

  metrics:
    server:
      - address: 127.0.0.7
        port: 9090
```

### 关键参数说明

| 参数 | 说明 |
|------|------|
| `gtpu.server.address` | 接收 gNB GTP-U 数据的地址 |
| `session.dev` | TUN 接口名称 |

## NRF 配置

NRF (Network Repository Function) 提供服务发现。

配置文件: `/etc/open5gs/nrf.yaml`

```yaml
nrf:
  serving:
    - plmn_id:
        mcc: 001
        mnc: 01
  sbi:
    server:
      - address: 127.0.0.10
        port: 7777
```

## 常用配置场景

### 修改 PLMN

PLMN (Public Land Mobile Network) 由 MCC 和 MNC 组成：

```yaml
# 所有网元都需要修改
plmn_id:
  mcc: 460    # 中国
  mnc: 00     # 运营商代码
```

需要修改的文件：
- `amf.yaml`
- `smf.yaml`
- `nrf.yaml`
- `ausf.yaml`
- `udm.yaml`
- `pcf.yaml`
- `nssf.yaml`

### 配置多个切片

```yaml
# amf.yaml
plmn_support:
  - plmn_id:
      mcc: 001
      mnc: 01
    s_nssai:
      - sst: 1        # eMBB
        sd: 000001
      - sst: 2        # URLLC
        sd: 000002
      - sst: 3        # mMTC
        sd: 000003
```

### 配置外部 gNB 连接

如果 gNB 在不同机器上：

```yaml
# amf.yaml
ngap:
  server:
    - address: 0.0.0.0  # 监听所有接口
      port: 38412

# upf.yaml
gtpu:
  server:
    - address: 0.0.0.0  # 监听所有接口
```

### 配置 IPv6

```yaml
# smf.yaml
session:
  - subnet: 10.45.0.1/16
    gateway: 10.45.0.1
    dnn: internet
  - subnet: 2001:db8:cafe::1/48
    gateway: 2001:db8:cafe::1
    dnn: internet6

# upf.yaml
session:
  - subnet: 10.45.0.1/16
    gateway: 10.45.0.1
    dnn: internet
    dev: ogstun
  - subnet: 2001:db8:cafe::1/48
    gateway: 2001:db8:cafe::1
    dnn: internet6
    dev: ogstun6
```

## 配置验证

修改配置后，验证语法：

```bash
# 测试 AMF 配置
sudo open5gs-amfd -c /etc/open5gs/amf.yaml -t

# 测试 SMF 配置
sudo open5gs-smfd -c /etc/open5gs/smf.yaml -t
```

重启服务使配置生效：

```bash
sudo systemctl restart open5gs-amfd
sudo systemctl restart open5gs-smfd
sudo systemctl restart open5gs-upfd
```

## 下一步

- [用户管理](/open5gs/subscriber) - 添加 UE 用户信息
- [srsRAN 配置](/srsran/gnb-config) - 配置 gNB 连接核心网

