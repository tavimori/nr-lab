# UE 配置

本页面介绍 srsRAN UE 的配置和使用方法。

## 概述

srsUE 是一个软件 5G 用户终端实现，可用于：

- 无需真实手机进行端到端测试
- 自动化测试场景
- 调试和分析

## 硬件需求

srsUE 需要独立的 SDR 设备：

| 设备 | 说明 |
|------|------|
| USRP B210 | 推荐，支持完整 5G |
| ZMQ | 虚拟射频，与 gNB 配合测试 |

## 配置文件示例

### 真实 SDR 配置

```yaml
# ue.yaml
rat: nr                      # 网络类型

nas:
  apn: internet              # APN/DNN
  type: ipv4                 # PDN 类型

usim:
  mode: soft                 # 软 USIM
  algo: milenage             # 认证算法
  imsi: '001010000000001'    # IMSI
  k: 465B5CE8B199B49FAA5F0A2EE238A6BC      # K
  opc: E8ED289DEBA952E4283B54E88E6183CA    # OPc
  amf: 8000

cell_search:
  dl_arfcn: 632628           # 下行 ARFCN
  band: 78                   # NR 频段
  subcarrier_spacing: 30     # 子载波间隔

# SDR 配置
rf:
  device_name: uhd
  device_args: type=b200
  rx_gain: 40
  tx_gain: 50
  srate: 23.04e6

log:
  filename: /tmp/ue.log
  all_level: info
  phy_level: info
  nas_level: debug
  rrc_level: debug
```

### ZMQ 仿真配置

用于与 ZMQ 模式的 gNB 配合：

```yaml
# ue_zmq.yaml
rat: nr

nas:
  apn: internet
  type: ipv4

usim:
  mode: soft
  algo: milenage
  imsi: '001010000000001'
  k: 465B5CE8B199B49FAA5F0A2EE238A6BC
  opc: E8ED289DEBA952E4283B54E88E6183CA
  amf: 8000

cell_search:
  dl_arfcn: 368500
  band: 3
  subcarrier_spacing: 15

rf:
  device_name: zmq
  device_args: tx_port=tcp://127.0.0.1:2001,rx_port=tcp://127.0.0.1:2000,base_srate=23.04e6
  rx_gain: 40
  tx_gain: 50
  srate: 23.04e6

log:
  filename: /tmp/ue.log
  all_level: info
```

## 关键参数说明

### USIM 参数

| 参数 | 说明 |
|------|------|
| `imsi` | 国际移动用户识别码，需与 Open5GS 一致 |
| `k` | 认证密钥，需与 Open5GS 一致 |
| `opc` | 运营商密钥，需与 Open5GS 一致 |
| `amf` | 认证管理字段，通常为 8000 |
| `algo` | 认证算法，milenage 或 xor |

### 小区搜索参数

| 参数 | 说明 |
|------|------|
| `dl_arfcn` | 需与 gNB 配置一致 |
| `band` | NR 频段号 |
| `subcarrier_spacing` | 子载波间隔 (kHz) |

## 启动 srsUE

### 基本启动

```bash
sudo srsue -c ue.yaml
```

### 后台运行

```bash
sudo srsue -c ue.yaml > /tmp/ue.log 2>&1 &
```

## 注册流程

成功的 UE 注册流程日志：

```
[NAS    ] 5GMM State: MM-DEREGISTERED -> MM-REGISTERED-INITIATED
[RRC    ] RRC Connected
[NAS    ] 5GMM State: MM-REGISTERED-INITIATED -> MM-REGISTERED
[NAS    ] PDU Session Establishment successful
[IP     ] Interface tun_srsue created, IP: 10.45.0.2
```

## 数据测试

### 检查 TUN 接口

```bash
ip addr show tun_srsue
```

### Ping 测试

```bash
# 通过 UE TUN 接口 ping
ping -I tun_srsue 8.8.8.8
```

### 速率测试

```bash
# 安装 iperf3
sudo apt install iperf3

# 服务器端 (在有公网的机器上)
iperf3 -s

# 客户端 (通过 UE 接口)
iperf3 -c <server_ip> -B 10.45.0.2
```

## ZMQ 端到端测试

这是无需 SDR 硬件的完整测试方法。

### 1. 启动 Open5GS

```bash
sudo systemctl start open5gs-nrfd
sudo systemctl start open5gs-amfd
sudo systemctl start open5gs-smfd
sudo systemctl start open5gs-upfd
# ... 其他服务
```

### 2. 启动 gNB (ZMQ 模式)

```bash
sudo gnb -c gnb_zmq.yaml
```

### 3. 启动 UE (ZMQ 模式)

```bash
sudo srsue -c ue_zmq.yaml
```

### 4. 验证连接

```bash
# 检查 UE 获取的 IP
ip addr show tun_srsue

# Ping 测试
ping -I tun_srsue 10.45.0.1
```

## 多 UE 测试

运行多个 UE 实例（需要多个 ZMQ 端口）：

```yaml
# ue1.yaml
rf:
  device_args: tx_port=tcp://127.0.0.1:3001,rx_port=tcp://127.0.0.1:3000,base_srate=23.04e6

# ue2.yaml  
rf:
  device_args: tx_port=tcp://127.0.0.1:4001,rx_port=tcp://127.0.0.1:4000,base_srate=23.04e6
```

## 日志分析

### 关键日志消息

| 消息 | 含义 |
|------|------|
| `RRC Connected` | RRC 连接建立 |
| `Registration Accept` | 注册成功 |
| `PDU Session Establishment successful` | 数据会话建立 |
| `Authentication Failure` | 认证失败 |

### 调试级别

```yaml
log:
  all_level: debug
  nas_level: debug
  rrc_level: debug
  phy_level: warning  # PHY 日志太多，可降级
```

## 故障排除

### 小区搜索失败

```
[PHY    ] Cell search failed
```

检查：
1. `dl_arfcn` 和 `band` 是否正确
2. SDR 是否正常工作
3. gNB 是否正在广播

### 认证失败

```
[NAS    ] Authentication Failure
```

检查：
1. IMSI, K, OPc 是否与 Open5GS 一致
2. 用户是否已添加到核心网
3. AMF 值是否正确

### PDU Session 建立失败

```
[NAS    ] PDU Session Establishment rejected
```

检查：
1. APN/DNN 是否正确
2. SMF/UPF 配置是否正确
3. TUN 接口是否已创建

## COTS UE 配置

如果使用商用手机而非 srsUE：

### Android 手机设置

1. 插入编程好的 SIM 卡
2. 进入设置 → 网络和互联网 → 移动网络
3. 选择首选网络类型为 "5G"
4. 创建 APN：
   - 名称: Open5GS
   - APN: internet
   - MCC: 001
   - MNC: 01
   - APN 类型: default

### 强制 5G SA 模式

不同厂商有不同方法：

**Samsung**:
- 拨号 `*#2263#` 进入频段选择
- 选择 NR only 或 NR/LTE

**Google Pixel**:
- 开发者选项 → 5G 网络模式 → SA only

## 下一步

- [快速开始](/guide/getting-started) - 完整实验流程
- [Open5GS 用户管理](/open5gs/subscriber) - 管理 UE 用户

