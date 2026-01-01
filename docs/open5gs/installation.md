# Open5GS 安装部署

本指南介绍在 Ubuntu 22.04 上安装 Open5GS 核心网。

## 安装方式

Open5GS 提供多种安装方式：

| 方式 | 适用场景 | 难度 |
|------|----------|------|
| APT 包安装 | 快速入门 | ⭐ |
| 源码编译 | 自定义修改 | ⭐⭐⭐ |
| Docker | 容器化部署 | ⭐⭐ |

本文主要介绍 APT 包安装方式。

## APT 包安装

### 1. 添加 Open5GS 仓库

```bash
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:open5gs/latest
sudo apt update
```

### 2. 安装 Open5GS

```bash
sudo apt install -y open5gs
```

这将安装所有 5G 核心网网元。

### 3. 安装 WebUI

WebUI 用于管理用户信息，需要 Node.js：

```bash
# 安装 Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# 安装 WebUI
sudo apt install -y open5gs-webui
```

### 4. 启动 MongoDB

```bash
sudo systemctl start mongod
sudo systemctl enable mongod
```

验证 MongoDB：

```bash
sudo systemctl status mongod
```

### 5. 启动 Open5GS 服务

```bash
# 启动所有服务
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

# 设置开机启动
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

### 6. 启动 WebUI

```bash
sudo systemctl start open5gs-webui
sudo systemctl enable open5gs-webui
```

访问 `http://localhost:9999`，默认账户：
- 用户名: `admin`
- 密码: `1423`

## 网络配置

### 创建 TUN 接口

UPF 需要 TUN 接口处理用户数据：

```bash
sudo ip tuntap add name ogstun mode tun
sudo ip addr add 10.45.0.1/16 dev ogstun
sudo ip link set ogstun up
```

### 配置 NAT

```bash
sudo iptables -t nat -A POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE
```

### 持久化配置

创建 `/etc/systemd/network/99-open5gs.netdev`：

```ini
[NetDev]
Name=ogstun
Kind=tun
```

创建 `/etc/systemd/network/99-open5gs.network`：

```ini
[Match]
Name=ogstun

[Network]
Address=10.45.0.1/16
```

## 验证安装

### 检查服务状态

```bash
# 查看所有 Open5GS 服务状态
sudo systemctl status open5gs-*

# 或者逐个检查
sudo systemctl status open5gs-amfd
sudo systemctl status open5gs-smfd
sudo systemctl status open5gs-upfd
```

### 检查端口监听

```bash
sudo ss -tlnp | grep open5gs
```

应该看到类似输出：

```
LISTEN  0  128  127.0.0.5:7777  *  users:(("open5gs-nrfd",pid=1234,fd=6))
LISTEN  0  128  127.0.0.5:38412 *  users:(("open5gs-amfd",pid=1235,fd=8))
...
```

### 检查日志

```bash
# AMF 日志
sudo tail -f /var/log/open5gs/amf.log

# SMF 日志
sudo tail -f /var/log/open5gs/smf.log
```

## 源码编译安装

如果需要修改源码或使用最新版本：

### 1. 安装依赖

```bash
sudo apt install -y python3-pip python3-setuptools python3-wheel ninja-build build-essential \
    flex bison git cmake meson libsctp-dev libgnutls28-dev libgcrypt20-dev \
    libssl-dev libidn11-dev libmongoc-dev libbson-dev libyaml-dev \
    libnghttp2-dev libmicrohttpd-dev libcurl4-gnutls-dev \
    libnghttp2-dev libtins-dev libtalloc-dev
```

### 2. 克隆源码

```bash
git clone https://github.com/open5gs/open5gs
cd open5gs
```

### 3. 编译安装

```bash
meson build --prefix=/usr/local
ninja -C build
sudo ninja -C build install
```

## Docker 安装

使用 Docker Compose 快速部署：

```bash
git clone https://github.com/open5gs/open5gs
cd open5gs/docker

# 启动所有服务
docker compose up -d
```

## 故障排除

### MongoDB 连接失败

```bash
# 检查 MongoDB 状态
sudo systemctl status mongod

# 查看 MongoDB 日志
sudo journalctl -u mongod
```

### 服务启动失败

```bash
# 查看详细日志
sudo journalctl -u open5gs-amfd -f

# 检查配置文件语法
sudo open5gs-amfd -c /etc/open5gs/amf.yaml -t
```

### 端口冲突

```bash
# 查找占用端口的进程
sudo lsof -i :38412
```

## 下一步

- [配置详解](/open5gs/configuration) - 深入了解各网元配置
- [用户管理](/open5gs/subscriber) - 添加和管理 UE 用户

