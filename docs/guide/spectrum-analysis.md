# 频谱分析实验

本指南介绍如何使用 SDR 设备观察和分析附近的无线电频谱，包括蜂窝网络和 WiFi 信号。

## 前置条件

- LibreSDR B210 或 USRP B210 已正确安装
- UHD 驱动已安装并通过 `uhd_usrp_probe` 验证
- 连接合适的天线

::: warning 注意
本指南仅用于**接收**和**观察**频谱，不涉及任何发射操作。被动接收在大多数国家是合法的，但请确认当地法规。
:::

## 软件工具概览

| 软件 | 用途 | 实时显示 | 难度 |
|------|------|----------|------|
| **uhd_fft** | 快速频谱查看 | ✅ | ⭐ 简单 |
| **GQRX** | 通用 SDR 接收器 | ✅ | ⭐ 简单 |
| **SDR++** | 现代 SDR 接收器 | ✅ | ⭐ 简单 |
| **GNU Radio** | 自定义信号处理 | ✅ | ⭐⭐⭐ 进阶 |
| **Inspectrum** | 离线信号分析 | ❌ | ⭐⭐ 中等 |

## 实验 1：使用 uhd_fft 快速查看频谱

`uhd_fft` 是 UHD 自带的简单频谱分析工具，无需额外安装。

### 安装

```bash
# Ubuntu/Debian - uhd_fft 包含在 uhd-host 中
sudo apt install uhd-host
```

### 基本用法

```bash
# 查看 2.4 GHz WiFi 频段
uhd_fft -f 2.45e9 -s 20e6

# 查看 5 GHz WiFi 频段  
uhd_fft -f 5.5e9 -s 40e6

# 查看 n78 频段 (3.5 GHz 5G)
uhd_fft -f 3.5e9 -s 40e6
```

### 参数说明

| 参数 | 说明 | 示例 |
|------|------|------|
| `-f` | 中心频率 (Hz) | `-f 2.45e9` = 2.45 GHz |
| `-s` | 采样率/带宽 (Hz) | `-s 20e6` = 20 MHz |
| `-g` | 增益 (dB) | `-g 40` |
| `--args` | UHD 设备参数 | `--args="type=b200"` |

### 观察 WiFi 信号

```bash
# 2.4 GHz WiFi (信道 1-13: 2412-2472 MHz)
uhd_fft -f 2.437e9 -s 30e6 -g 40
```

你应该能看到：
- **突发性的宽带信号** - WiFi 使用 OFDM，带宽 20/40 MHz
- **信道间隔** - 每个信道间隔 5 MHz
- **信号强度变化** - WiFi 是突发传输的

## 实验 2：使用 GQRX 进行交互式频谱分析

GQRX 是一个功能丰富的 SDR 接收器，带有漂亮的瀑布图显示。

### 安装

```bash
# Ubuntu/Debian
sudo apt install gqrx-sdr

# Arch Linux
sudo pacman -S gqrx

# Nix
nix-shell -p gqrx
```

### 配置 GQRX

1. 启动 GQRX：`gqrx`

2. 在设备配置对话框中：
   - **Device**: `uhd,type=b200`
   - **Sample rate**: `20000000` (20 MHz)
   - **Bandwidth**: `0` (自动)

3. 点击 **OK** 然后点击 **播放按钮** 开始接收

### 探索蜂窝频段

| 频段 | 频率范围 | 技术 | GQRX 设置 |
|------|----------|------|-----------|
| LTE Band 3 (DL) | 1805-1880 MHz | 4G LTE | 中心 1842 MHz, 40 MHz 带宽 |
| LTE Band 7 (DL) | 2620-2690 MHz | 4G LTE | 中心 2655 MHz, 40 MHz 带宽 |
| n78 | 3300-3800 MHz | 5G NR | 中心 3500 MHz, 56 MHz 带宽 |
| n41 | 2496-2690 MHz | 5G NR | 中心 2593 MHz, 56 MHz 带宽 |

### GQRX 快捷操作

- **鼠标滚轮** - 调整频率
- **Ctrl + 滚轮** - 调整 FFT 缩放
- **点击瀑布图** - 跳转到该频率

## 实验 3：使用 SDR++ 现代化频谱分析

SDR++ 是一个现代化的跨平台 SDR 接收器，界面美观，性能优秀。

### 安装

```bash
# 从源码构建 (Ubuntu)
sudo apt install libfftw3-dev libglfw3-dev libvolk2-dev libsoapysdr-dev
git clone https://github.com/AlexandreRouworworma/SDRPlusPlus.git
cd SDRPlusPlus
mkdir build && cd build
cmake .. -DOPT_BUILD_SOAPY_SOURCE=ON
make -j$(nproc)

# Nix
nix-shell -p sdrpp
```

### 配置 SDR++

1. 启动 SDR++
2. 在左侧面板选择 **Source** → **SoapySDR** 或 **UHD**
3. 选择你的设备
4. 设置采样率和增益
5. 点击 **Start**

### SDR++ 优势

- 🎨 现代化深色主题界面
- 📊 高性能 FFT 渲染
- 🔌 模块化插件系统
- 💾 支持录制 IQ 数据

## 实验 4：GNU Radio 自定义频谱分析器

使用 GNU Radio Companion 创建自定义频谱分析工具。

### 安装

```bash
# Ubuntu/Debian
sudo apt install gnuradio gr-uhd

# Nix
nix-shell -p gnuradio
```

### 创建流程图

创建文件 `spectrum_analyzer.grc`：

```
[UHD: USRP Source] → [QT GUI Frequency Sink]
                   → [QT GUI Waterfall Sink]
                   → [QT GUI Time Sink]
```

### 命令行快速启动

```bash
# 使用 GNU Radio 内置示例
gnuradio-companion /usr/share/gnuradio/examples/uhd/uhd_fft.grc
```

### Python 脚本示例

```python
#!/usr/bin/env python3
"""Simple spectrum analyzer using GNU Radio"""

from gnuradio import gr, uhd, qtgui
from PyQt5 import Qt
import sys

class SpectrumAnalyzer(gr.top_block):
    def __init__(self, center_freq=2.45e9, samp_rate=20e6, gain=40):
        gr.top_block.__init__(self, "Spectrum Analyzer")
        
        # UHD Source
        self.usrp = uhd.usrp_source(
            device_addr="type=b200",
            stream_args=uhd.stream_args(cpu_format="fc32")
        )
        self.usrp.set_samp_rate(samp_rate)
        self.usrp.set_center_freq(center_freq)
        self.usrp.set_gain(gain)
        
        # FFT Sink
        self.fft_sink = qtgui.freq_sink_c(
            1024,           # FFT size
            5,              # Window type (Blackman-Harris)
            center_freq,    # Center frequency
            samp_rate,      # Sample rate
            "Spectrum"      # Title
        )
        
        # Waterfall Sink
        self.waterfall = qtgui.waterfall_sink_c(
            1024,
            5,
            center_freq,
            samp_rate,
            "Waterfall"
        )
        
        # Connect blocks
        self.connect(self.usrp, self.fft_sink)
        self.connect(self.usrp, self.waterfall)

if __name__ == '__main__':
    app = Qt.QApplication(sys.argv)
    tb = SpectrumAnalyzer()
    tb.start()
    app.exec_()
    tb.stop()
```

## 实验 5：观察 LTE 信号特征

### LTE 信号识别

LTE 信号有独特的频谱特征：

```
┌─────────────────────────────────────────────────────────────┐
│  ▁▂▃▄▅▆▇█▇▆▅▄▃▂▁                                            │
│  └──────────────┘                                           │
│     10/15/20 MHz                                            │
│   典型 LTE 信号带宽                                          │
│                                                             │
│  特征:                                                       │
│  • 平坦的顶部 (OFDM)                                         │
│  • 陡峭的边缘                                                │
│  • 中心直流子载波可能有凹陷                                   │
└─────────────────────────────────────────────────────────────┘
```

### 扫描 LTE 频段

```bash
# 中国移动 LTE Band 41 (2575-2635 MHz)
uhd_fft -f 2.605e9 -s 40e6 -g 50

# 中国联通 LTE Band 3 (1805-1880 MHz)
uhd_fft -f 1.8425e9 -s 40e6 -g 50

# 中国电信 LTE Band 1 (2110-2170 MHz)
uhd_fft -f 2.14e9 -s 40e6 -g 50
```

### 使用 LTE-Cell-Scanner (可选)

```bash
# 安装
git clone https://github.com/JiaoXianjun/LTE-Cell-Scanner.git
cd LTE-Cell-Scanner
mkdir build && cd build
cmake ..
make

# 扫描 LTE 小区
./CellSearch --freq-start 1805e6 --freq-end 1880e6
```

## 实验 6：观察 5G NR 信号

### 5G NR 信号特征

5G NR 使用更宽的带宽和不同的子载波间隔：

| 子载波间隔 (SCS) | 带宽选项 | 典型用途 |
|------------------|----------|----------|
| 15 kHz | 5-50 MHz | FR1 低频 |
| 30 kHz | 10-100 MHz | FR1 主流 |
| 60 kHz | 10-100 MHz | FR1/FR2 |
| 120 kHz | 50-400 MHz | FR2 毫米波 |

### 扫描 n78 频段

```bash
# n78 频段全览 (3300-3800 MHz)
uhd_fft -f 3.55e9 -s 56e6 -g 50

# 注意: B210 最大带宽 56 MHz，无法一次看到完整 n78
```

### 信号识别技巧

| 信号类型 | 频谱特征 | 时域特征 |
|----------|----------|----------|
| LTE | 平坦 OFDM，10-20 MHz | 连续传输 |
| 5G NR | 更宽带宽，可能有 SSB 突发 | 周期性 SSB |
| WiFi | 20/40/80 MHz 突发 | 短脉冲 |
| 蓝牙 | 1 MHz 窄带跳频 | 快速跳频 |

## 实验 7：录制和离线分析

### 录制 IQ 数据

```bash
# 使用 uhd_rx_cfile 录制 (GNU Radio)
uhd_rx_cfile -f 2.45e9 -r 20e6 -g 40 -N 20000000 wifi_capture.cf32

# 参数说明
# -f: 中心频率
# -r: 采样率  
# -g: 增益
# -N: 采样点数 (20M samples = 1 秒 @ 20 MS/s)
```

### 使用 Inspectrum 分析

```bash
# 安装
sudo apt install inspectrum

# 打开录制文件
inspectrum wifi_capture.cf32
```

Inspectrum 功能：
- 🔍 时频分析 (瀑布图)
- 📏 光标测量
- 📊 符号同步可视化
- 🎛️ 可调 FFT 大小和重叠

## 常见问题

### 信号太弱看不到？

1. **检查天线** - 确保天线频率匹配
2. **增加增益** - 使用 `-g 60` 或更高 (注意不要饱和)
3. **靠近信号源** - 走近窗户或室外

### 频谱全是噪声？

1. **检查 USB 连接** - USB 3.0 端口更稳定
2. **降低采样率** - 先用 `-s 10e6` 测试
3. **检查设备** - 运行 `uhd_usrp_probe`

### 如何识别不同信号？

| 观察点 | 分析方法 |
|--------|----------|
| 带宽 | 测量 -3dB 带宽 |
| 调制 | 观察星座图 (需要解调) |
| 时域特征 | 使用 Time Sink 观察 |
| 周期性 | 瀑布图中的重复模式 |

## 下一步

- [硬件需求](/guide/hardware) - SDR 设备详细介绍
- [srsRAN 安装](/srsran/installation) - 搭建自己的基站
- [Open5GS 配置](/open5gs/configuration) - 核心网部署

::: tip 进阶学习
掌握频谱分析后，可以尝试使用 srsRAN 的 `cell_search` 工具解析 LTE/NR 小区信息。
:::

