# NR Lab - 5G NR 实验文档

基于 Open5GS + srsRAN + SDR 的 5G 私有网络搭建指南。

5G NR Lab Documentation - Private 5G Network Setup Guide with Open5GS + srsRAN + SDR.

## 🚀 快速开始 / Quick Start

### 使用 Nix (推荐) / Using Nix (Recommended)

本项目提供多种开发环境：

| 命令 | 环境 | 用途 |
|------|------|------|
| `nix develop` | 📖 Documentation | 文档开发 (Node.js) |
| `nix develop .#sdr` | 📡 SDR | 频谱分析实验 (UHD, GQRX, GNU Radio) |
| `nix develop .#5g` | 📶 5G | 5G 网络实验 (srsRAN gNB) |
| `nix develop .#full` | 🚀 Full | 完整环境 (文档 + SDR + 5G) |

```bash
# 进入文档开发环境
nix develop

# 或进入 SDR 实验环境
nix develop .#sdr

# 或进入 5G 网络环境 (首次需要 --accept-flake-config)
nix develop .#5g --accept-flake-config

# 或进入完整环境
nix develop .#full --accept-flake-config
```

> **Note**: `--accept-flake-config` 用于信任项目的二进制缓存配置，可从 [Cachix](https://nr-lab.cachix.org) 下载预编译的 srsRAN，避免本地编译（约需 30 分钟）。

### 文档开发 / Documentation Development

```bash
# 安装依赖
npm install

# 本地开发
npm run docs:dev
```

访问 / Visit: `http://localhost:5173`

### 构建 / Build

```bash
npm run docs:build
```

### 预览构建结果 / Preview Build

```bash
npm run docs:preview
```

### SDR 工具 / SDR Tools

进入 SDR 环境后可使用以下工具：

```bash
# 检测 USRP 设备
uhd_usrp_probe

# 频谱分析
uhd_fft -f 2.45e9 -s 20e6

# GUI 工具
gqrx
sdrpp
gnuradio-companion
```

## 📖 文档结构 / Documentation Structure

```
docs/
├── index.md                 # 中文首页 / Chinese Home
├── en/
│   └── index.md             # 英文首页 / English Home
├── guide/                   # 入门指南 / Getting Started
│   ├── getting-started.md
│   ├── prerequisites.md
│   ├── hardware.md
│   └── spectrum-analysis.md # 频谱分析实验 / Spectrum Analysis
├── open5gs/                 # Open5GS 核心网 / Core Network
│   ├── index.md
│   ├── installation.md
│   ├── configuration.md
│   └── subscriber.md
├── ims/                     # IMS 语音系统 / IMS Voice System
│   ├── index.md
│   ├── cscf.md
│   ├── registration.md
│   └── volte.md
└── srsran/                  # srsRAN 基站 / Base Station
    ├── index.md
    ├── installation.md
    ├── gnb-config.md
    └── ue-config.md
```

## 🌐 多语言支持 / Multilingual Support

本文档支持中英双语：
- 简体中文 (默认 / Default)
- English

This documentation supports bilingual:
- Simplified Chinese (Default)
- English

## 📡 技术栈 / Technology Stack

| 组件 / Component | 软件 / Software | 说明 / Description |
|------------------|-----------------|-------------------|
| 核心网 / Core | Open5GS | 开源 5G SA 核心网 / Open source 5G SA core |
| 基站 / RAN | srsRAN Project | 开源 5G gNB / Open source 5G gNB |
| 射频 / RF | USRP B210 | SDR 硬件 / SDR hardware |

## 🔧 NixOS Module

本项目提供 NixOS module，可声明式配置 Open5GS 5G/LTE 核心网。

This project provides NixOS modules for declarative Open5GS 5G/LTE core network configuration.

### 基本用法 / Basic Usage

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nr-lab.url = "github:your-username/nr-lab";
  };

  outputs = { nixpkgs, nr-lab, ... }: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      modules = [
        nr-lab.nixosModules.open5gs
        {
          services.open5gs = {
            enable = true;
            mode = "5g-sa";  # or "lte" or "both"
            
            # PLMN configuration
            plmn = {
              mcc = "001";  # Test MCC
              mnc = "01";   # Test MNC
            };
            
            # Network name shown on devices
            networkName = "My 5G Lab";
            
            # User plane configuration
            userPlane = {
              subnet = "10.45.0.0/16";
              gateway = "10.45.0.1";
              dnn = "internet";
            };
            
            # gNB connection (NGAP/N2 interface)
            ngap.address = "192.168.1.100";  # AMF address for gNB
            
            # User plane (GTP-U/N3 interface)
            gtpu.address = "192.168.1.100";  # UPF address for gNB
          };
        }
      ];
    };
  };
}
```

### 配置选项 / Configuration Options

| 选项 / Option | 默认值 / Default | 说明 / Description |
|---------------|------------------|-------------------|
| `enable` | `false` | 启用 Open5GS / Enable Open5GS |
| `mode` | `"5g-sa"` | 网络模式: `5g-sa`, `lte`, `both` |
| `plmn.mcc` | `"001"` | 移动国家码 / Mobile Country Code |
| `plmn.mnc` | `"01"` | 移动网络码 / Mobile Network Code |
| `networkName` | `"NR Lab"` | 网络名称 / Network name |
| `tac` | `1` | 跟踪区码 / Tracking Area Code |
| `userPlane.subnet` | `"10.45.0.0/16"` | UE IP 池 / UE IP pool |
| `userPlane.dnn` | `"internet"` | 数据网络名 / Data Network Name |
| `mongodb.enable` | `true` | 启用 MongoDB / Enable MongoDB |
| `tun.enable` | `true` | 创建 ogstun 接口 / Create ogstun interface |
| `nat.enable` | `true` | 启用 NAT / Enable NAT for UE traffic |

#### 外部接口配置 / External Interface Options

连接外部基站（小基站、RRU）时，需要将相关接口绑定到外部 IP。

When connecting external base stations (small cells, RRU), you need to bind interfaces to external IPs.

| 选项 / Option | 默认值 / Default | 说明 / Description |
|---------------|------------------|-------------------|
| `ngap.address` | `"127.0.0.5"` | 5G NGAP (N2) 接口，gNB 连接此地址 |
| `gtpu.address` | `"127.0.0.7"` | 5G GTP-U (N3) 接口，用户面数据 |
| `s1ap.address` | `"127.0.0.2"` | 4G S1AP 接口，eNB 连接此地址 |
| `sgwuGtpu.address` | `"127.0.0.6"` | 4G SGWU GTP-U 接口，用户面数据 |

### 连接外部基站示例 / External Base Station Examples

#### 5G SA 模式 - 连接外部 gNB

```nix
# 假设服务器 IP 为 192.168.1.100
services.open5gs = {
  enable = true;
  mode = "5g-sa";
  
  plmn = { mcc = "001"; mnc = "01"; };
  tac = 1;
  networkName = "My 5G Lab";
  
  # 外部 gNB 连接的 NGAP (N2) 接口 - AMF
  ngap.address = "192.168.1.100";
  
  # 外部 gNB 连接的 GTP-U (N3) 接口 - UPF
  gtpu.address = "192.168.1.100";
  
  userPlane = {
    subnet = "10.45.0.0/16";
    gateway = "10.45.0.1";
    dnn = "internet";
  };
};
```

gNB 配置（srsRAN 或其他）中需要设置：
- AMF 地址: `192.168.1.100:38412` (SCTP)
- 确保 PLMN 和 TAC 匹配

#### 4G LTE 模式 - 连接外部 eNB / 小基站

```nix
# 假设服务器 IP 为 192.168.1.100
services.open5gs = {
  enable = true;
  mode = "lte";
  
  plmn = { mcc = "001"; mnc = "01"; };
  tac = 1;
  networkName = "My LTE Lab";
  
  # 外部 eNB 连接的 S1AP 接口 - MME
  s1ap.address = "192.168.1.100";
  
  # 外部 eNB 连接的 GTP-U 接口 - SGWU
  sgwuGtpu.address = "192.168.1.100";
  
  userPlane = {
    subnet = "10.45.0.0/16";
    gateway = "10.45.0.1";
    dnn = "internet";  # APN for LTE
  };
};
```

eNB / 小基站配置中需要设置：
- MME 地址: `192.168.1.100:36412` (SCTP)
- 确保 PLMN 和 TAC 匹配

#### 同时支持 4G 和 5G (NSA/SA)

```nix
services.open5gs = {
  enable = true;
  mode = "both";  # 启用 4G EPC + 5G Core
  
  plmn = { mcc = "001"; mnc = "01"; };
  tac = 1;
  networkName = "My Dual-Mode Lab";
  
  # 5G 接口
  ngap.address = "192.168.1.100";
  gtpu.address = "192.168.1.100";
  
  # 4G 接口
  s1ap.address = "192.168.1.100";
  sgwuGtpu.address = "192.168.1.100";
  
  userPlane = {
    subnet = "10.45.0.0/16";
    gateway = "10.45.0.1";
    dnn = "internet";
  };
};
```

> **参考 / Reference**: [Open5GS Quickstart Guide](https://open5gs.org/open5gs/docs/guide/01-quickstart/)

### 服务管理 / Service Management

```bash
# 查看所有 Open5GS 服务状态
systemctl status 'open5gs-*'

# 重启 AMF
sudo systemctl restart open5gs-amf

# 查看日志
journalctl -u open5gs-amf -f
```

## 📄 许可证 / License

MIT License
