# srsRAN Installation

This guide covers compiling and installing srsRAN Project on Ubuntu 22.04.

## Install Dependencies

### Basic Dependencies

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

### Optional Dependencies

```bash
# ZeroMQ (for virtual RF)
sudo apt install -y libzmq3-dev

# USRP driver
sudo apt install -y libuhd-dev uhd-host

# Debug tools
sudo apt install -y libdw-dev
```

## Download UHD FPGA Images

For USRP users, download FPGA images:

```bash
sudo uhd_images_downloader
```

Verify USRP connection:

```bash
uhd_find_devices
```

## Compile srsRAN

### Clone Source

```bash
cd ~
git clone https://github.com/srsran/srsRAN_Project.git
cd srsRAN_Project
```

### Create Build Directory

```bash
mkdir build
cd build
```

### Configure CMake

Basic configuration:

```bash
cmake ..
```

With optional features:

```bash
cmake .. \
    -DENABLE_EXPORT=ON \
    -DENABLE_ZEROMQ=ON \
    -DENABLE_UHD=ON \
    -DAUTO_DETECT_ISA=ON
```

### Build

```bash
make -j$(nproc)
```

::: tip
Compilation may take 10-30 minutes depending on CPU performance.
:::

### Install

```bash
sudo make install
sudo ldconfig
```

## Verify Installation

### Check Executables

```bash
which gnb
gnb --help
```

### Check Sample Configs

```bash
ls /usr/local/share/srsran/
```

## ZMQ Virtual RF Testing

Test without SDR hardware using ZMQ.

### Start gNB (ZMQ Mode)

Create `gnb_zmq.yaml`:

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

Start gNB:

```bash
sudo gnb -c gnb_zmq.yaml
```

## Performance Optimization

### CPU Governor

```bash
# Set to performance mode
sudo cpupower frequency-set -g performance

# Or
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

### Real-time Priority

Edit `/etc/security/limits.conf`:

```
*    soft    rtprio    99
*    hard    rtprio    99
```

### Kernel Parameters

Edit `/etc/sysctl.conf`:

```
# Increase network buffers
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
```

Apply changes:

```bash
sudo sysctl -p
```

## Troubleshooting

### UHD Cannot Find Device

```bash
# Check USB permissions
sudo uhd_find_devices

# Add udev rules if permission issues
sudo cp /usr/lib/uhd/utils/uhd-usrp.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Runtime Performance Warnings

```
[PHY   ] Late: 100 events
```

Solutions:
1. Increase TX power
2. Check antenna connections
3. Use performance CPU governor
4. Reduce system load

## Next Steps

- [gNB Configuration](/en/srsran/gnb-config) - Detailed base station config
- [UE Configuration](/en/srsran/ue-config) - Configure software terminal

