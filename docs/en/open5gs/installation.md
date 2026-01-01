# Open5GS Installation

This guide covers installing Open5GS core network on Ubuntu 22.04.

## Installation Methods

Open5GS provides multiple installation options:

| Method | Use Case | Difficulty |
|--------|----------|------------|
| APT Package | Quick start | ⭐ |
| Source Build | Custom modifications | ⭐⭐⭐ |
| Docker | Containerized deployment | ⭐⭐ |

This guide primarily covers APT package installation.

## APT Package Installation

### 1. Add Open5GS Repository

```bash
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:open5gs/latest
sudo apt update
```

### 2. Install Open5GS

```bash
sudo apt install -y open5gs
```

This installs all 5G core network functions.

### 3. Install WebUI

WebUI is used for subscriber management and requires Node.js:

```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install WebUI
sudo apt install -y open5gs-webui
```

### 4. Start MongoDB

```bash
sudo systemctl start mongod
sudo systemctl enable mongod
```

Verify MongoDB:

```bash
sudo systemctl status mongod
```

### 5. Start Open5GS Services

```bash
# Start all services
sudo systemctl start open5gs-nrfd
sudo systemctl start open5gs-scpd
sudo systemctl start open5gs-amfd
sudo systemctl start open5gs-smfd
sudo systemctl start open5gs-upfd
sudo systemctl start open5gs-ausfd
sudo systemctl start open5gs-udmd
sudo systemctl start open5gs-udrd
sudo systemctl start open5gs-pcfd
sudo systemctl start open5gs-nssfd
sudo systemctl start open5gs-bsfd

# Enable on boot
sudo systemctl enable open5gs-nrfd
sudo systemctl enable open5gs-scpd
sudo systemctl enable open5gs-amfd
sudo systemctl enable open5gs-smfd
sudo systemctl enable open5gs-upfd
sudo systemctl enable open5gs-ausfd
sudo systemctl enable open5gs-udmd
sudo systemctl enable open5gs-udrd
sudo systemctl enable open5gs-pcfd
sudo systemctl enable open5gs-nssfd
sudo systemctl enable open5gs-bsfd
```

### 6. Start WebUI

```bash
sudo systemctl start open5gs-webui
sudo systemctl enable open5gs-webui
```

Access `http://localhost:9999` with default credentials:
- Username: `admin`
- Password: `1423`

## Network Configuration

### Create TUN Interface

UPF requires a TUN interface for user data:

```bash
sudo ip tuntap add name ogstun mode tun
sudo ip addr add 10.45.0.1/16 dev ogstun
sudo ip link set ogstun up
```

### Configure NAT

```bash
sudo iptables -t nat -A POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE
```

### Persistent Configuration

Create `/etc/systemd/network/99-open5gs.netdev`:

```ini
[NetDev]
Name=ogstun
Kind=tun
```

Create `/etc/systemd/network/99-open5gs.network`:

```ini
[Match]
Name=ogstun

[Network]
Address=10.45.0.1/16
```

## Verify Installation

### Check Service Status

```bash
# View all Open5GS service status
sudo systemctl status open5gs-*

# Or check individually
sudo systemctl status open5gs-amfd
sudo systemctl status open5gs-smfd
sudo systemctl status open5gs-upfd
```

### Check Listening Ports

```bash
sudo ss -tlnp | grep open5gs
```

Expected output:

```
LISTEN  0  128  127.0.0.5:7777  *  users:(("open5gs-nrfd",pid=1234,fd=6))
LISTEN  0  128  127.0.0.5:38412 *  users:(("open5gs-amfd",pid=1235,fd=8))
...
```

### Check Logs

```bash
# AMF logs
sudo tail -f /var/log/open5gs/amf.log

# SMF logs
sudo tail -f /var/log/open5gs/smf.log
```

## Source Build Installation

For source code modifications or latest versions:

### 1. Install Dependencies

```bash
sudo apt install -y python3-pip python3-setuptools python3-wheel ninja-build build-essential \
    flex bison git cmake meson libsctp-dev libgnutls28-dev libgcrypt20-dev \
    libssl-dev libidn11-dev libmongoc-dev libbson-dev libyaml-dev \
    libnghttp2-dev libmicrohttpd-dev libcurl4-gnutls-dev \
    libnghttp2-dev libtins-dev libtalloc-dev
```

### 2. Clone Source

```bash
git clone https://github.com/open5gs/open5gs
cd open5gs
```

### 3. Build and Install

```bash
meson build --prefix=/usr/local
ninja -C build
sudo ninja -C build install
```

## Docker Installation

Quick deployment with Docker Compose:

```bash
git clone https://github.com/open5gs/open5gs
cd open5gs/docker

# Start all services
docker compose up -d
```

## Troubleshooting

### MongoDB Connection Failed

```bash
# Check MongoDB status
sudo systemctl status mongod

# View MongoDB logs
sudo journalctl -u mongod
```

### Service Startup Failed

```bash
# View detailed logs
sudo journalctl -u open5gs-amfd -f

# Validate config syntax
sudo open5gs-amfd -c /etc/open5gs/amf.yaml -t
```

### Port Conflict

```bash
# Find process using port
sudo lsof -i :38412
```

## Next Steps

- [Configuration](/en/open5gs/configuration) - Deep dive into NF configuration
- [Subscriber Management](/en/open5gs/subscriber) - Add and manage UE subscribers

