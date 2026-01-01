# Open5GS 核心网概述

Open5GS 是一个开源的 5G SA (Standalone) 和 4G LTE 核心网实现，完全符合 3GPP 规范。

## 架构概览

```
                                    ┌─────────────┐
                                    │    NSSF     │
                                    └──────┬──────┘
                                           │
┌─────────────┐    ┌─────────────┐    ┌────┴────┐    ┌─────────────┐
│    gNB      │───▶│    AMF      │───▶│   NRF   │◀───│    UDM      │
└─────────────┘ N2 └──────┬──────┘    └────┬────┘    └──────┬──────┘
                          │                │                │
                          │           ┌────┴────┐    ┌──────┴──────┐
                          │           │   SCP   │    │    UDR      │
                          │           └─────────┘    └─────────────┘
                          │ N11
                    ┌─────▼─────┐
                    │    SMF    │
                    └─────┬─────┘
                          │ N4
                    ┌─────▼─────┐
                    │    UPF    │────▶ Internet
                    └───────────┘ N6
```

## 网元说明

### 控制面网元

| 网元 | 全称 | 功能 |
|------|------|------|
| **AMF** | Access and Mobility Management Function | 接入与移动性管理，处理 N1/N2 信令 |
| **SMF** | Session Management Function | 会话管理，控制 UPF |
| **NRF** | Network Repository Function | 网元注册与发现 |
| **UDM** | Unified Data Management | 用户数据管理 |
| **UDR** | Unified Data Repository | 用户数据存储 |
| **AUSF** | Authentication Server Function | 认证服务 |
| **NSSF** | Network Slice Selection Function | 网络切片选择 |
| **PCF** | Policy Control Function | 策略控制 |
| **BSF** | Binding Support Function | 绑定支持 |
| **SCP** | Service Communication Proxy | 服务通信代理 |

### 用户面网元

| 网元 | 全称 | 功能 |
|------|------|------|
| **UPF** | User Plane Function | 用户面处理，数据包转发 |

## 接口说明

| 接口 | 连接 | 协议 | 说明 |
|------|------|------|------|
| N1 | UE ↔ AMF | NAS | 非接入层信令 |
| N2 | gNB ↔ AMF | NGAP/SCTP | 接入网控制面 |
| N3 | gNB ↔ UPF | GTP-U | 用户数据隧道 |
| N4 | SMF ↔ UPF | PFCP | 会话管理 |
| N6 | UPF ↔ DN | IP | 数据网络连接 |
| N11 | AMF ↔ SMF | HTTP/2 | 会话管理请求 |

## 主要特性

- ✅ **5G SA 核心网**: 完整的 5G 独立组网支持
- ✅ **4G EPC**: 向后兼容 4G LTE
- ✅ **WebUI**: 图形化用户管理界面
- ✅ **MongoDB**: 用户数据持久化存储
- ✅ **容器化**: 支持 Docker 部署
- ✅ **Kubernetes**: 支持云原生部署

## 系统要求

- **操作系统**: Ubuntu 22.04 LTS (推荐)
- **内存**: 4GB+
- **存储**: 10GB+
- **MongoDB**: 4.4+

## 配置文件位置

Open5GS 配置文件位于 `/etc/open5gs/`：

```
/etc/open5gs/
├── amf.yaml
├── smf.yaml
├── upf.yaml
├── nrf.yaml
├── udm.yaml
├── udr.yaml
├── ausf.yaml
├── nssf.yaml
├── pcf.yaml
├── bsf.yaml
└── scp.yaml
```

## 日志文件位置

日志文件位于 `/var/log/open5gs/`：

```bash
# 查看 AMF 日志
sudo tail -f /var/log/open5gs/amf.log

# 查看 UPF 日志
sudo tail -f /var/log/open5gs/upf.log
```

## 下一步

- [安装部署](/open5gs/installation) - 详细安装步骤
- [配置详解](/open5gs/configuration) - 各网元配置说明
- [用户管理](/open5gs/subscriber) - 添加和管理用户

