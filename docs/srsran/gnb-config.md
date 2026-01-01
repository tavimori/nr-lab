# gNB 配置

本页面详细介绍 srsRAN gNB 的配置参数。

## 配置文件结构

gNB 使用 YAML 格式配置文件：

```yaml
gnb_id: 411
gnb_id_bit_length: 22

cell_cfg:
  # 小区配置
  
cu_cp:
  # CU-CP 配置
  
ru_sdr:
  # SDR 配置
  
log:
  # 日志配置
```

## 完整配置示例

### USRP B210 配置

```yaml
# gNB 标识
gnb_id: 411
gnb_id_bit_length: 22

# 小区配置
cell_cfg:
  dl_arfcn: 632628          # n78 频段中心频率
  band: 78                   # NR 频段
  channel_bandwidth_MHz: 20  # 带宽
  common_scs: 30             # 子载波间隔 (kHz)
  plmn: "00101"              # PLMN
  tac: 1                     # 跟踪区码

  pdcch:
    common:
      ss0_index: 0
      coreset0_index: 12
    dedicated:
      ss2_type: common
      dci_format_0_1_and_1_1: false

  prach:
    prach_config_index: 1

# CU-CP 配置 (连接核心网)
cu_cp:
  amf:
    addr: 192.168.1.10       # AMF 地址
    port: 38412              # NGAP 端口
    bind_addr: 192.168.1.20  # gNB 本地地址
    n2_bind_addr: 192.168.1.20
    n2_bind_interface: eth0  # 可选

  upf:
    bind_addr: 192.168.1.20  # N3 接口地址

# SDR 配置
ru_sdr:
  device_driver: uhd         # USRP 驱动
  device_args: type=b200     # 设备参数
  srate: 23.04               # 采样率 (MHz)
  tx_gain: 50                # 发射增益 (dB)
  rx_gain: 40                # 接收增益 (dB)
  
  # 时钟配置
  clock: internal            # internal/external/gpsdo
  sync: internal

# 日志配置
log:
  filename: /tmp/gnb.log
  all_level: info            # debug/info/warning/error
  phy_level: info
  mac_level: info
  rlc_level: info
  pdcp_level: info
  rrc_level: info
  ngap_level: info

# 性能配置
expert:
  phy:
    threads:
      pdsch:
        nof_threads: 2
      pusch:
        nof_threads: 2
```

## 关键参数说明

### 小区参数

| 参数 | 说明 | 常用值 |
|------|------|--------|
| `dl_arfcn` | 下行绝对射频信道号 | 见频段表 |
| `band` | NR 频段号 | 78, 41, 3 等 |
| `channel_bandwidth_MHz` | 信道带宽 | 10, 20, 40, 100 |
| `common_scs` | 子载波间隔 | 15, 30 kHz |
| `plmn` | 公共陆地移动网络 | 需与 Open5GS 一致 |
| `tac` | 跟踪区码 | 需与 Open5GS 一致 |

### 频段与 ARFCN

常用 n78 频段 ARFCN：

| 中心频率 | ARFCN | SCS |
|----------|-------|-----|
| 3.5 GHz | 632628 | 30 kHz |
| 3.6 GHz | 636666 | 30 kHz |
| 3.7 GHz | 640704 | 30 kHz |

计算公式：
```
f = 3000 MHz + (ARFCN - 600000) × 0.005 MHz (SCS 30 kHz)
```

### 核心网连接

| 参数 | 说明 |
|------|------|
| `amf.addr` | Open5GS AMF 的 IP 地址 |
| `amf.port` | NGAP 端口，默认 38412 |
| `amf.bind_addr` | gNB 的本地 IP |
| `upf.bind_addr` | N3 接口绑定地址 |

### SDR 配置

| 参数 | 说明 |
|------|------|
| `device_driver` | uhd/zmq/bladerf |
| `device_args` | 设备特定参数 |
| `srate` | 采样率 (MHz) |
| `tx_gain` | 发射增益 (0-90 dB) |
| `rx_gain` | 接收增益 (0-90 dB) |

## 多小区配置

```yaml
cells:
  - cell_id: 1
    dl_arfcn: 632628
    band: 78
    channel_bandwidth_MHz: 20
    common_scs: 30
    plmn: "00101"
    tac: 1

  - cell_id: 2
    dl_arfcn: 636666
    band: 78
    channel_bandwidth_MHz: 20
    common_scs: 30
    plmn: "00101"
    tac: 1
```

## 不同场景配置

### 实验室低功率测试

```yaml
ru_sdr:
  device_driver: uhd
  device_args: type=b200
  srate: 23.04
  tx_gain: 20      # 低功率
  rx_gain: 50
```

### 外部时钟同步

```yaml
ru_sdr:
  device_driver: uhd
  device_args: type=n310
  srate: 30.72
  tx_gain: 50
  rx_gain: 40
  clock: external   # 外部 10 MHz 时钟
  sync: external    # 外部 PPS
```

### ZMQ 仿真测试

```yaml
ru_sdr:
  device_driver: zmq
  device_args: tx_port=tcp://127.0.0.1:2000,rx_port=tcp://127.0.0.1:2001,base_srate=23.04e6
  srate: 23.04
  tx_gain: 50
  rx_gain: 40
```

## 启动 gNB

```bash
# 前台运行
sudo gnb -c gnb.yaml

# 后台运行
sudo gnb -c gnb.yaml > /tmp/gnb.log 2>&1 &
```

## 验证连接

### 检查 AMF 连接

成功连接后，gNB 日志会显示：

```
[NGAP   ] NG Setup procedure successful
[NGAP   ] AMF connected
```

Open5GS AMF 日志会显示：

```
[amf] INFO: gNB-N2 accepted[192.168.1.20]:38412
```

### 监控指标

```bash
# 查看实时日志
tail -f /tmp/gnb.log

# 过滤特定模块
tail -f /tmp/gnb.log | grep -E "(RRC|NGAP)"
```

## 故障排除

### NGAP 连接失败

```
[NGAP   ] Failed to connect to AMF
```

检查：
1. AMF 地址和端口是否正确
2. 网络连通性 `ping 192.168.1.10`
3. AMF 服务是否运行
4. 防火墙规则

### 射频问题

```
[PHY   ] Late: 100 events
```

解决方案：
1. 增加发射功率
2. 检查天线连接
3. 使用 performance CPU 调度器
4. 减少系统负载

### PLMN 不匹配

```
[NGAP   ] NGAP Setup Failure - Unknown PLMN
```

确保 `plmn` 与 Open5GS 配置一致。

## 下一步

- [UE 配置](/srsran/ue-config) - 配置软件终端
- [Open5GS 用户管理](/open5gs/subscriber) - 添加用户

