# 硬件需求

本页面介绍搭建 5G NR 实验环境所需的硬件设备。

## 计算平台

### 推荐配置

| 配置项 | 最低要求 | 推荐配置 |
|--------|----------|----------|
| CPU | 4 核 x86_64 | 8+ 核, 支持 AVX2 |
| 内存 | 8 GB | 16+ GB |
| 存储 | 50 GB SSD | 100+ GB NVMe |
| 网卡 | 1 Gbps | 10 Gbps |
| USB | USB 3.0 | USB 3.0 (SDR 用) |

::: tip 提示
实时性能对于基站非常重要。建议禁用 CPU 节能功能，使用低延迟内核。
:::

## SDR 设备

### USRP B210 (推荐)

**Ettus Research USRP B210** 是最常用的 5G 实验 SDR：

| 参数 | 规格 |
|------|------|
| 频率范围 | 70 MHz - 6 GHz |
| 带宽 | 56 MHz (2x2 MIMO) |
| ADC/DAC | 12-bit, 61.44 MS/s |
| 接口 | USB 3.0 |
| 价格 | ~$1,500 USD |

适用场景：
- n78 (3.5 GHz) 频段实验
- 20 MHz 带宽 5G NR

#### SDR 架构解析

理解 SDR 的内部架构有助于调试和优化：

```
┌─────────────────────────────────────────────────────────────┐
│                        USRP B210                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │
│  │   USB 3.0    │◄──►│    FPGA      │◄──►│   AD9361     │◄──► RF
│  │  Interface   │    │  Spartan 6   │    │  Transceiver │   │
│  └──────────────┘    └──────────────┘    └──────────────┘   │
│         ▲                   │                               │
│         │              Sample Rate                          │
│         │              Conversion                           │
│         └───────── USB 3.0 ~30 MB/s ────────────────────────│
└─────────────────────────────────────────────────────────────┘
```

**核心组件：**

| 组件 | USRP B210 | 功能 |
|------|-----------|------|
| **FPGA** | Xilinx Spartan 6 | 数字信号处理、采样率转换、USB 接口控制 |
| **RF 芯片** | AD9361 | 射频收发器，支持 70MHz-6GHz，2x2 MIMO |
| **USB 芯片** | Cypress FX3 | USB 3.0 SuperSpeed 接口 |

**AD9361 射频芯片** 是这类 SDR 的核心：
- 集成 ADC/DAC、混频器、滤波器、PLL
- 可编程带宽 200kHz - 56MHz
- 支持 TDD 和 FDD 模式

### LibreSDR B210 (开源替代品)

[LibreSDR B210](https://github.com/lmesserStep/LibreSDRB210) 是 USRP B210 的开源硬件克隆，价格更低：

| 参数 | 规格 |
|------|------|
| 频率范围 | 70 MHz - 6 GHz |
| 带宽 | 56 MHz (2x2 MIMO) |
| FPGA | **Xilinx Artix 7 (XC7A100T)** |
| RF 芯片 | AD9361 |
| 接口 | USB 3.0 |
| 价格 | ~$300-500 USD |

::: warning 重要差异
LibreSDR 使用 **Artix 7 FPGA**，而非原版 B210 的 Spartan 6。这意味着需要使用专门编译的固件！
:::

#### 为什么需要不同的固件？

```
原版 USRP B210:  Spartan 6 FPGA  →  usrp_b210_fpga.bin (官方)
LibreSDR B210:   Artix 7 FPGA    →  usrp_b210_fpga.bin (LibreSDR 定制)
```

FPGA 固件包含：
- **时钟管理逻辑** - 不同 FPGA 系列的 PLL 原语不同
- **I/O 引脚配置** - 引脚映射可能不同
- **DSP 核心** - 数字下变频、滤波器等

由于 Artix 7 和 Spartan 6 的架构差异，官方固件无法直接使用。LibreSDR 社区提供了重新编译的固件。

#### 驱动架构 (UHD)

**UHD (USRP Hardware Driver)** 是 Ettus Research 开发的开源驱动框架：

```
┌─────────────────────────────────────────────────────────┐
│                    应用层 (srsRAN, GNU Radio)            │
├─────────────────────────────────────────────────────────┤
│                    UHD API (C++/Python)                  │
├─────────────────────────────────────────────────────────┤
│              UHD 核心 (设备发现、流控制)                  │
├─────────────────────────────────────────────────────────┤
│         USB 传输层 (libusb)  │  网络传输层 (UDP)         │
├─────────────────────────────────────────────────────────┤
│              FPGA 固件  │  固件加载器                    │
└─────────────────────────────────────────────────────────┘
```

| 组件 | 许可证 | 说明 |
|------|--------|------|
| UHD 驱动 | GPLv3 | 开源，可自由使用和修改 |
| FPGA 源码 | 部分开源 | Ettus 提供部分源码 |
| AD9361 驱动 | GPLv2 | ADI 官方开源驱动 |

#### LibreSDR 设置步骤

1. **安装 UHD 驱动**

```bash
# Ubuntu/Debian
sudo add-apt-repository ppa:ettusresearch/uhd
sudo apt update
sudo apt install libuhd-dev uhd-host
```

2. **下载 UHD 镜像**

```bash
sudo /usr/lib/uhd/utils/uhd_images_downloader.py
```

3. **替换为 LibreSDR 固件**

```bash
# 下载 LibreSDR 专用固件
wget https://github.com/lmesserStep/LibreSDRB210/raw/main/usrp_b210_fpga.bin
```

**方法 A：替换系统固件文件**

```bash
# 备份原文件
sudo cp /usr/share/uhd/images/usrp_b210_fpga.bin \
        /usr/share/uhd/images/usrp_b210_fpga.bin.bak

# 替换为 LibreSDR 固件
sudo cp usrp_b210_fpga.bin /usr/share/uhd/images/
```

**方法 B：直接烧写 FPGA (推荐)**

```bash
# 直接将固件烧写到设备，不修改系统文件
sudo uhd_image_loader --args="type=b200" --no-fw --fpga-path="./usrp_b210_fpga.bin"
```

| 方法 | 优点 | 缺点 |
|------|------|------|
| 方法 A | 一次替换，永久生效 | 需要 root 权限修改系统文件 |
| 方法 B | 不修改系统文件，便于切换 | 每次重启设备后需重新加载 |

::: tip 提示
`--no-fw` 参数表示只烧写 FPGA 镜像，不更新 FX3 固件。对于 LibreSDR 克隆设备，通常只需要更换 FPGA 固件。
:::

4. **验证设备**

```bash
uhd_usrp_probe
```

预期输出：
```
[INFO] [B200] Detected Device: B210
[INFO] [B200] Loading FPGA image: /usr/share/uhd/images/usrp_b210_fpga.bin...
[INFO] [B200] Operating over USB 3.
[INFO] [B200] Register loopback test passed
```

::: tip 兼容性
LibreSDR 固件已在 UHD 4.0-7.0 版本上测试通过。
:::

#### 许可证与法律注意事项

| 方面 | 说明 |
|------|------|
| **硬件设计** | LibreSDR 是开源硬件，可自由复制 |
| **UHD 驱动** | GPLv3，可商业使用但需开源修改 |
| **FPGA 固件** | 社区编译，基于开源 USRP FPGA 代码 |
| **RF 使用** | ⚠️ 需遵守当地无线电法规 |

::: danger 射频合规
无论使用哪种 SDR，发射信号前必须：
- 获得适当的无线电执照
- 使用屏蔽箱进行实验
- 确保发射功率和频率合规
:::

### USRP N310

高性能版本，适合更大带宽实验：

| 参数 | 规格 |
|------|------|
| 频率范围 | 10 MHz - 6 GHz |
| 带宽 | 100 MHz (4x4 MIMO) |
| ADC/DAC | 14-bit, 153.6 MS/s |
| 接口 | 10 Gbps Ethernet |
| 价格 | ~$8,000 USD |

### BladeRF x40/xA4

性价比较高的选择：

| 参数 | BladeRF x40 | BladeRF xA4 |
|------|-------------|-------------|
| 频率范围 | 300 MHz - 3.8 GHz | 47 MHz - 6 GHz |
| 带宽 | 40 MHz | 56 MHz |
| 接口 | USB 3.0 | USB 3.0 |
| 价格 | ~$420 USD | ~$480 USD |

### LimeSDR

开源社区选择：

| 参数 | 规格 |
|------|------|
| 频率范围 | 100 kHz - 3.8 GHz |
| 带宽 | 61.44 MHz |
| MIMO | 2x2 |
| 接口 | USB 3.0 |
| 价格 | ~$300 USD |

## 天线

### 频段选择

常用 5G NR 频段：

| 频段 | 频率范围 | 带宽 | 说明 |
|------|----------|------|------|
| n78 | 3300-3800 MHz | 100 MHz | Sub-6 主力频段 |
| n77 | 3300-4200 MHz | 100 MHz | 覆盖 n78 |
| n41 | 2496-2690 MHz | 194 MHz | TDD 频段 |
| n1 | 1920-2170 MHz | 60 MHz | FDD 频段 |

### 推荐天线

- **全向天线**: 适合实验室测试
- **定向天线**: 适合特定方向覆盖
- **PCB 天线**: 适合短距离测试

::: warning 注意
确保天线频率范围覆盖你的实验频段。阻抗应为 50Ω。
:::

## SIM 卡

### 可编程 SIM

推荐使用 **sysmoUSIM-SJS1**：

| 特性 | 规格 |
|------|------|
| 类型 | USIM (4G/5G) |
| 算法 | Milenage, TUAK |
| 接口 | PC/SC 编程 |
| 价格 | ~$10 USD |

### SIM 卡编程

使用 `pySim` 工具写入参数：

```bash
pip install pysim

# 写入 IMSI 和 Key
pySim-prog.py -p 0 -t sysmoUSIM-SJS1 \
    -i 001010000000001 \
    -k 465B5CE8B199B49FAA5F0A2EE238A6BC \
    -o E8ED289DEBA952E4283B54E88E6183CA \
    -a 12345678
```

## 测试终端

### COTS 手机

支持 5G SA 的商用手机：

- Samsung Galaxy S21+ 及以上
- Google Pixel 5 及以上
- OnePlus 8T 及以上

::: tip 提示
确保手机支持你使用的频段，并且可以强制 5G SA 模式。
:::

### srsUE

软件 UE 方案，需要额外一套 SDR：

- 无需真实手机和 SIM 卡
- 便于自动化测试
- 可查看详细日志

## 屏蔽箱

为避免干扰，强烈建议使用 RF 屏蔽箱：

| 类型 | 隔离度 | 用途 |
|------|--------|------|
| 小型屏蔽箱 | 60-80 dB | 手机 + 天线 |
| 中型屏蔽箱 | 80-100 dB | 完整测试台 |

## 采购清单

### 基础实验环境

| 设备 | 数量 | 预算 |
|------|------|------|
| USRP B210 | 1 | $1,500 |
| 天线 (n78) | 2 | $100 |
| SIM 卡 | 5 | $50 |
| SIM 读卡器 | 1 | $20 |
| 小型屏蔽箱 | 1 | $500 |
| **合计** | - | **~$2,200** |

### 进阶实验环境

| 设备 | 数量 | 预算 |
|------|------|------|
| USRP N310 | 1 | $8,000 |
| USRP B210 (UE 用) | 1 | $1,500 |
| 天线套装 | 1 | $300 |
| 中型屏蔽箱 | 1 | $2,000 |
| **合计** | - | **~$12,000** |

## 下一步

- [快速开始](/guide/getting-started) - 开始搭建实验环境
- [Open5GS 安装](/open5gs/installation) - 核心网部署

