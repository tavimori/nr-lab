# 环境准备

本页面详细介绍搭建 5G NR 实验环境所需的系统配置和软件安装。

## 操作系统

推荐使用 **Ubuntu 22.04 LTS**，这是 Open5GS 和 srsRAN 官方测试的系统版本。

### 系统更新

```bash
sudo apt update && sudo apt upgrade -y
```

### 内核配置

为了获得最佳的实时性能，建议安装低延迟内核：

```bash
sudo apt install linux-lowlatency
```

重启后验证：

```bash
uname -r
# 应显示类似 5.15.0-xx-lowlatency
```

## 网络配置

### 配置 TUN 接口

Open5GS UPF 需要 TUN 接口来处理用户数据：

```bash
sudo ip tuntap add name ogstun mode tun
sudo ip addr add 10.45.0.1/16 dev ogstun
sudo ip link set ogstun up
```

### 配置 NAT

允许 UE 访问互联网：

```bash
sudo iptables -t nat -A POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE
```

### 启用 IP 转发

```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

永久生效：

```bash
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
```

## 依赖安装

### 基础工具

```bash
sudo apt install -y \
    build-essential \
    cmake \
    git \
    pkg-config \
    python3 \
    python3-pip
```

### Open5GS 依赖

```bash
sudo apt install -y \
    mongodb \
    libsctp-dev \
    libyaml-dev \
    libmicrohttpd-dev \
    libcurl4-gnutls-dev \
    libtalloc-dev \
    libgnutls28-dev \
    libgcrypt20-dev \
    libidn11-dev \
    libmongoc-dev \
    libbson-dev \
    flex \
    bison
```

### srsRAN 依赖

```bash
sudo apt install -y \
    libfftw3-dev \
    libmbedtls-dev \
    libsctp-dev \
    libyaml-cpp-dev \
    libgtest-dev \
    libzmq3-dev \
    libuhd-dev \    # USRP 用户
    uhd-host
```

## SDR 驱动配置

### USRP (UHD)

```bash
# 安装 UHD
sudo apt install -y libuhd-dev uhd-host

# 下载 FPGA 镜像
sudo uhd_images_downloader

# 配置 USB 权限
sudo cp /usr/lib/uhd/utils/uhd-usrp.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
```

验证连接：

```bash
uhd_find_devices
```

### BladeRF

```bash
# 添加仓库
sudo add-apt-repository ppa:nuandllc/bladerf
sudo apt update

# 安装驱动
sudo apt install -y bladerf libbladerf-dev bladerf-fpga-hostedx40
```

## 性能优化

### CPU 调度器

设置为 performance 模式：

```bash
sudo apt install -y cpufrequtils
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils
sudo systemctl restart cpufrequtils
```

### 实时优先级

编辑 `/etc/security/limits.conf`：

```
*    soft    rtprio    99
*    hard    rtprio    99
```

## 验证环境

运行以下命令验证环境配置：

```bash
# 检查 MongoDB
sudo systemctl status mongod

# 检查 TUN 接口
ip addr show ogstun

# 检查 SDR 连接
uhd_find_devices  # USRP
bladeRF-cli -p    # BladeRF
```

## 下一步

环境准备完成后，继续以下步骤：

- [硬件需求](/guide/hardware) - 详细的硬件选型指南
- [Open5GS 安装](/open5gs/installation) - 核心网安装配置

