# Prerequisites

This page details the system configuration and software installation required for the 5G NR lab environment.

## Operating System

**Ubuntu 22.04 LTS** is recommended as it's the officially tested version for Open5GS and srsRAN.

### System Update

```bash
sudo apt update && sudo apt upgrade -y
```

### Kernel Configuration

For optimal real-time performance, install the low-latency kernel:

```bash
sudo apt install linux-lowlatency
```

Verify after reboot:

```bash
uname -r
# Should show something like 5.15.0-xx-lowlatency
```

## Network Configuration

### Configure TUN Interface

Open5GS UPF requires a TUN interface for user data:

```bash
sudo ip tuntap add name ogstun mode tun
sudo ip addr add 10.45.0.1/16 dev ogstun
sudo ip link set ogstun up
```

### Configure NAT

Allow UE to access the internet:

```bash
sudo iptables -t nat -A POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE
```

### Enable IP Forwarding

```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

Make it permanent:

```bash
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
```

## Dependency Installation

### Basic Tools

```bash
sudo apt install -y \
    build-essential \
    cmake \
    git \
    pkg-config \
    python3 \
    python3-pip
```

### Open5GS Dependencies

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

### srsRAN Dependencies

```bash
sudo apt install -y \
    libfftw3-dev \
    libmbedtls-dev \
    libsctp-dev \
    libyaml-cpp-dev \
    libgtest-dev \
    libzmq3-dev \
    libuhd-dev \    # For USRP users
    uhd-host
```

## SDR Driver Configuration

### USRP (UHD)

```bash
# Install UHD
sudo apt install -y libuhd-dev uhd-host

# Download FPGA images
sudo uhd_images_downloader

# Configure USB permissions
sudo cp /usr/lib/uhd/utils/uhd-usrp.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Verify connection:

```bash
uhd_find_devices
```

### BladeRF

```bash
# Add repository
sudo add-apt-repository ppa:nuandllc/bladerf
sudo apt update

# Install driver
sudo apt install -y bladerf libbladerf-dev bladerf-fpga-hostedx40
```

## Performance Optimization

### CPU Governor

Set to performance mode:

```bash
sudo apt install -y cpufrequtils
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils
sudo systemctl restart cpufrequtils
```

### Real-time Priority

Edit `/etc/security/limits.conf`:

```
*    soft    rtprio    99
*    hard    rtprio    99
```

## Verify Environment

Run the following commands to verify your setup:

```bash
# Check MongoDB
sudo systemctl status mongod

# Check TUN interface
ip addr show ogstun

# Check SDR connection
uhd_find_devices  # USRP
bladeRF-cli -p    # BladeRF
```

## Next Steps

After completing environment setup, proceed to:

- [Hardware Requirements](/en/guide/hardware) - Detailed hardware selection guide
- [Open5GS Installation](/en/open5gs/installation) - Core network installation

