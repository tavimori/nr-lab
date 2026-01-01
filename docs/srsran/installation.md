# srsRAN 安装部署

本指南介绍在 Ubuntu 22.04 上编译安装 srsRAN Project。

## 安装依赖

### 基础依赖

```bash
sudo apt update
sudo apt install -y \
    build-essential \
    cmake \
    make \
    gcc \
    g++ \
    pkg-config \
    libfftw3-dev \
    libmbedtls-dev \
    libsctp-dev \
    libyaml-cpp-dev \
    libgtest-dev
```

### 可选依赖

```bash
# ZeroMQ (用于虚拟射频)
sudo apt install -y libzmq3-dev

# USRP 驱动
sudo apt install -y libuhd-dev uhd-host

# 调试工具
sudo apt install -y libdw-dev
```

## 下载 UHD FPGA 镜像

如果使用 USRP，需要下载 FPGA 镜像：

```bash
sudo uhd_images_downloader
```

验证 USRP 连接：

```bash
uhd_find_devices
```

## 编译 srsRAN

### 克隆源码

```bash
cd ~
git clone https://github.com/srsran/srsRAN_Project.git
cd srsRAN_Project
```

### 创建构建目录

```bash
mkdir build
cd build
```

### 配置 CMake

基础配置：

```bash
cmake ..
```

带可选功能的配置：

```bash
cmake .. \
    -DENABLE_EXPORT=ON \
    -DENABLE_ZEROMQ=ON \
    -DENABLE_UHD=ON \
    -DAUTO_DETECT_ISA=ON
```

### 编译

```bash
make -j$(nproc)
```

::: tip 提示
编译可能需要 10-30 分钟，取决于 CPU 性能。
:::

### 安装

```bash
sudo make install
sudo ldconfig
```

## 验证安装

### 检查可执行文件

```bash
which gnb
gnb --help
```

### 检查示例配置

```bash
ls /usr/local/share/srsran/
```

## ZMQ 虚拟射频测试

在没有 SDR 硬件的情况下，可以使用 ZMQ 进行测试。

### 启动 gNB (ZMQ 模式)

创建 `gnb_zmq.yaml`：

```yaml
gnb_id: 411
gnb_id_bit_length: 22

cell_cfg:
  dl_arfcn: 368500
  band: 3
  channel_bandwidth_MHz: 20
  common_scs: 15
  plmn: "00101"
  tac: 1

cu_cp:
  amf:
    addr: 127.0.0.5
    port: 38412
    bind_addr: 127.0.0.1

ru_sdr:
  device_driver: zmq
  device_args: tx_port=tcp://127.0.0.1:2000,rx_port=tcp://127.0.0.1:2001,base_srate=23.04e6
  srate: 23.04
  tx_gain: 50
  rx_gain: 40
```

启动 gNB：

```bash
sudo gnb -c gnb_zmq.yaml
```

## Docker 安装

### 使用预构建镜像

```bash
docker pull srsran/srsran_project

docker run -it --rm \
    --privileged \
    --net=host \
    srsran/srsran_project \
    gnb -c /path/to/config.yaml
```

### 构建本地镜像

```bash
cd srsRAN_Project
docker build -t srsran-local .
```

## 性能优化

### CPU 调度器

```bash
# 设置为 performance 模式
sudo cpupower frequency-set -g performance

# 或者
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

### 实时优先级

编辑 `/etc/security/limits.conf`：

```
*    soft    rtprio    99
*    hard    rtprio    99
```

### 禁用 CPU 节能

```bash
# 禁用 C-states
sudo cpupower idle-set -D 0
```

### 内核参数

编辑 `/etc/sysctl.conf`：

```
# 增加网络缓冲区
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
```

应用更改：

```bash
sudo sysctl -p
```

## 故障排除

### UHD 找不到设备

```bash
# 检查 USB 权限
sudo uhd_find_devices

# 如果权限问题，添加 udev 规则
sudo cp /usr/lib/uhd/utils/uhd-usrp.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### 编译错误

```bash
# 清理并重新编译
cd build
make clean
cmake ..
make -j$(nproc)
```

### 运行时性能警告

```
[PHY     ] [   0.0] Late: 15 events
```

这表示实时性能不足：

1. 检查 CPU 调度器设置
2. 使用低延迟内核
3. 增加 SDR 缓冲区大小
4. 减少系统负载

## 下一步

- [gNB 配置](/srsran/gnb-config) - 详细配置基站
- [UE 配置](/srsran/ue-config) - 配置软件终端

