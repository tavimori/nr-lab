# 快速开始

::: danger ⚠️ 重要法律警告 - 请先阅读！
在使用 SDR 设备进行无线电发射之前，请务必了解相关法律法规。根据 2026 年 1 月 1 日起施行的《中华人民共和国治安管理处罚法》第三十二条规定：

**未经批准设置无线电台（站）或非法使用无线电频率，可处 5-15 日行政拘留！**

请务必使用射频屏蔽箱或线缆直连方式进行实验，详情请阅读 [法律法规与合规要求](/guide/rf-regulations)。
:::

本指南将帮助你快速搭建一个完整的 5G NR 私有网络实验环境。

## 系统架构

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│     UE       │────▶│    gNB       │────▶│   5G Core    │
│  (手机/srsUE) │ 空口 │  (srsRAN)    │ N2/N3│  (Open5GS)   │
└──────────────┘     └──────────────┘     └──────────────┘
                           │
                     ┌─────┴─────┐
                     │   SDR     │
                     │ (USRP等)  │
                     └───────────┘
```

## 准备工作

在开始之前，请确保你已经准备好以下内容：

### 硬件需求

| 设备 | 推荐配置 | 备注 |
|------|----------|------|
| 服务器/PC | Ubuntu 22.04, 16GB+ RAM | 运行核心网和 gNB |
| SDR | USRP B210 / BladeRF x40 | 射频前端 |
| 天线 | 700-2700MHz | 根据频段选择 |
| SIM 卡 | 可编程 SIM | sysmoUSIM-SJS1 推荐 |
| 测试 UE | 支持 5G SA 的手机 | 或使用 srsUE |

### 软件需求

- Ubuntu 22.04 LTS（推荐）
- Open5GS v2.7+
- srsRAN Project 24.04+
- UHD 驱动（USRP 用户）

## 安装步骤概览

### 1. 安装 Open5GS 核心网

```bash
# 添加 Open5GS 仓库
sudo add-apt-repository ppa:open5gs/latest
sudo apt update

# 安装 Open5GS
sudo apt install open5gs
```

详细配置请参考 [Open5GS 安装指南](/open5gs/installation)。

### 2. 安装 srsRAN gNB

```bash
# 安装依赖
sudo apt install cmake make gcc g++ pkg-config \
    libfftw3-dev libmbedtls-dev libsctp-dev libyaml-cpp-dev \
    libgtest-dev libzmq3-dev

# 克隆并编译 srsRAN
git clone https://github.com/srsran/srsRAN_Project.git
cd srsRAN_Project
mkdir build && cd build
cmake ..
make -j$(nproc)
sudo make install
```

详细配置请参考 [srsRAN 安装指南](/srsran/installation)。

### 3. 配置用户信息

在 Open5GS WebUI 中添加用户：

```yaml
IMSI: 001010000000001
Key: 465B5CE8B199B49FAA5F0A2EE238A6BC
OPc: E8ED289DEBA952E4283B54E88E6183CA
```

### 4. 启动服务

```bash
# 启动 Open5GS 服务
sudo systemctl start open5gs-amfd
sudo systemctl start open5gs-smfd
sudo systemctl start open5gs-upfd
# ... 其他服务

# 启动 gNB
sudo gnb -c gnb.yaml
```

## 验证连接

成功启动后，你应该能在 AMF 日志中看到 gNB 连接信息：

```
[amf] INFO: gNB-N2 accepted[192.168.1.100]:38412 in ng-path module (../src/amf/ngap-sctp.c:113)
[amf] INFO: gNB-N2 accepted[192.168.1.100] in master_sm module (../src/amf/amf-sm.c:754)
```

## 下一步

- [环境准备](/guide/prerequisites) - 详细的系统配置
- [Open5GS 配置](/open5gs/configuration) - 核心网参数详解
- [gNB 配置](/srsran/gnb-config) - 基站参数配置

::: danger ⚠️ 射频合规提醒
在进行空口实验前，请**务必**确保：
1. ✅ 已阅读 [法律法规与合规要求](/guide/rf-regulations)
2. ✅ 使用**射频屏蔽箱**或**线缆直连+衰减器**方式
3. ✅ 发射功率设置为最低可用值
4. ✅ 不对公共无线网络造成干扰

**违规后果**：根据 2026 年新规，非法设置基站可处 5-15 日行政拘留！
:::

