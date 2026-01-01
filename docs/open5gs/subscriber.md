# 用户管理

本页面介绍如何在 Open5GS 中添加和管理 UE 用户信息。

## WebUI 管理

### 访问 WebUI

1. 确保 WebUI 服务运行：
   ```bash
   sudo systemctl status open5gs-webui
   ```

2. 访问 `http://localhost:9999`

3. 默认登录信息：
   - 用户名: `admin`
   - 密码: `1423`

### 添加用户

1. 点击左侧菜单 **Subscriber**
2. 点击右上角 **+** 按钮
3. 填写用户信息：

| 字段 | 示例值 | 说明 |
|------|--------|------|
| IMSI | 001010000000001 | 国际移动用户识别码 |
| Subscriber Key (K) | 465B5CE8B199B49FAA5F0A2EE238A6BC | 认证密钥 |
| Operator Key (OPc) | E8ED289DEBA952E4283B54E88E6183CA | 运营商密钥 |
| AMF | 8000 | 认证管理字段 |
| SQN | 000000000000 | 序列号 |

4. 点击 **SAVE** 保存

### 配置 APN/DNN

在添加用户时，配置数据网络：

1. 在 **APN** 部分点击 **+**
2. 填写：
   - **APN/DNN**: `internet`
   - **SST**: `1`
   - **SD**: `000001` (可选)
   - **Session Type**: `IPv4`

## MongoDB 命令行管理

### 查看用户

```bash
mongosh
use open5gs
db.subscribers.find().pretty()
```

### 添加用户

```javascript
db.subscribers.insertOne({
  imsi: '001010000000001',
  msisdn: [],
  imeisv: [],
  security: {
    k: '465B5CE8B199B49FAA5F0A2EE238A6BC',
    amf: '8000',
    op: null,
    opc: 'E8ED289DEBA952E4283B54E88E6183CA',
    sqn: NumberLong(0)
  },
  ambr: {
    downlink: { value: 1, unit: 3 },  // 1 Gbps
    uplink: { value: 1, unit: 3 }     // 1 Gbps
  },
  slice: [{
    sst: 1,
    default_indicator: true,
    session: [{
      name: 'internet',
      type: 3,  // IPv4
      ambr: {
        downlink: { value: 1, unit: 3 },
        uplink: { value: 1, unit: 3 }
      },
      qos: {
        index: 9,
        arp: {
          priority_level: 8,
          pre_emption_capability: 1,
          pre_emption_vulnerability: 1
        }
      }
    }]
  }],
  access_restriction_data: 32,
  subscriber_status: 0,
  network_access_mode: 0,
  subscribed_rau_tau_timer: 12
})
```

### 删除用户

```javascript
db.subscribers.deleteOne({ imsi: '001010000000001' })
```

### 修改用户

```javascript
db.subscribers.updateOne(
  { imsi: '001010000000001' },
  { $set: { 'ambr.downlink.value': 2 } }
)
```

## 批量添加用户

### 使用脚本

创建 `add_subscribers.js`：

```javascript
const subscribers = [
  { imsi: '001010000000001', k: '465B5CE8B199B49FAA5F0A2EE238A6BC', opc: 'E8ED289DEBA952E4283B54E88E6183CA' },
  { imsi: '001010000000002', k: '465B5CE8B199B49FAA5F0A2EE238A6BD', opc: 'E8ED289DEBA952E4283B54E88E6183CB' },
  { imsi: '001010000000003', k: '465B5CE8B199B49FAA5F0A2EE238A6BE', opc: 'E8ED289DEBA952E4283B54E88E6183CC' },
];

subscribers.forEach(sub => {
  db.subscribers.insertOne({
    imsi: sub.imsi,
    security: {
      k: sub.k,
      amf: '8000',
      op: null,
      opc: sub.opc,
      sqn: NumberLong(0)
    },
    ambr: {
      downlink: { value: 1, unit: 3 },
      uplink: { value: 1, unit: 3 }
    },
    slice: [{
      sst: 1,
      default_indicator: true,
      session: [{
        name: 'internet',
        type: 3,
        ambr: {
          downlink: { value: 1, unit: 3 },
          uplink: { value: 1, unit: 3 }
        },
        qos: {
          index: 9,
          arp: {
            priority_level: 8,
            pre_emption_capability: 1,
            pre_emption_vulnerability: 1
          }
        }
      }]
    }],
    access_restriction_data: 32,
    subscriber_status: 0,
    network_access_mode: 0,
    subscribed_rau_tau_timer: 12
  });
});
```

执行脚本：

```bash
mongosh open5gs add_subscribers.js
```

## SIM 卡参数配置

### 使用 pySim 编程 SIM 卡

安装 pySim：

```bash
pip install pysim
```

写入参数：

```bash
pySim-prog.py -p 0 -t sysmoUSIM-SJS1 \
    -i 001010000000001 \
    -k 465B5CE8B199B49FAA5F0A2EE238A6BC \
    -o E8ED289DEBA952E4283B54E88E6183CA \
    --mcc 001 \
    --mnc 01 \
    -a 12345678
```

参数说明：

| 参数 | 说明 |
|------|------|
| `-p` | SIM 卡读卡器端口 |
| `-t` | SIM 卡类型 |
| `-i` | IMSI |
| `-k` | Ki (认证密钥) |
| `-o` | OPc |
| `--mcc` | 移动国家码 |
| `--mnc` | 移动网络码 |
| `-a` | ADM 密钥 (SIM 卡管理密码) |

### 计算 OPc

如果只有 OP 而没有 OPc：

```python
from pysim.utils import calculate_opc

k = bytes.fromhex('465B5CE8B199B49FAA5F0A2EE238A6BC')
op = bytes.fromhex('E8ED289DEBA952E4283B54E88E6183CA')
opc = calculate_opc(k, op)
print(opc.hex().upper())
```

## 测试密钥生成

用于测试目的的密钥生成：

```python
import secrets

# 生成 K
k = secrets.token_hex(16).upper()
print(f"K: {k}")

# 生成 OPc
opc = secrets.token_hex(16).upper()
print(f"OPc: {opc}")
```

::: warning 安全提示
测试密钥仅用于实验环境。生产环境中应使用安全的密钥生成和管理流程。
:::

## 常见问题

### 认证失败

1. 检查 IMSI 是否正确
2. 检查 K 和 OPc 是否与 SIM 卡一致
3. 检查 AMF 值 (通常为 8000)

### UE 无法获取 IP

1. 检查 DNN 配置是否正确
2. 检查 SMF 的 session 配置
3. 检查 UPF 的 TUN 接口

## 下一步

- [srsRAN 概述](/srsran/) - 了解基站配置
- [gNB 配置](/srsran/gnb-config) - 连接核心网

