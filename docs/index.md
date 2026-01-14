---
layout: home

hero:
  name: "NR Lab"
  text: "5G NR 实验文档"
  tagline: 基于 Open5GS + srsRAN + SDR 的 5G 私有网络搭建指南
  image:
    src: /hero-image.svg
    alt: 5G NR Lab
  actions:
    - theme: brand
      text: 快速开始
      link: /guide/getting-started
    - theme: alt
      text: 查看 GitHub
      link: https://github.com/tavimori/nr-lab
    - theme: alt
      text: 查看 GitCode
      link: https://gitcode.com/tavimori/nr-lab


features:
  - icon: 📚
    title: 5G 基础知识
    details: 了解 5G 网络架构、RAN/核心网组成、频段分配、基站类型等基础概念
    link: /guide/5g-architecture
  - icon: ⚖️
    title: 法律法规
    details: 无线电管理法规、《治安管理处罚法》2026年新规、合法实验方法
    link: /guide/rf-regulations
  - icon: 🌐
    title: Open5GS 核心网
    details: 完整的 5G SA 核心网部署，包含 AMF、SMF、UPF 等网元配置
    link: /open5gs/
  - icon: 📡
    title: srsRAN 基站
    details: 使用 srsRAN Project 搭建 5G gNB，支持多种 SDR 硬件
    link: /srsran/
  - icon: 🔧
    title: SDR 硬件
    details: USRP、BladeRF、LimeSDR 等软件定义无线电设备配置指南
    link: /guide/hardware
  - icon: 📊
    title: 频谱分析
    details: 使用 SDR 观察和分析蜂窝网络、WiFi 等无线信号
    link: /guide/spectrum-analysis
  - icon: 📱
    title: 端到端测试
    details: 从 UE 注册到数据传输的完整测试流程
    link: /guide/getting-started
---

## 项目简介

本文档旨在提供一个完整的 5G NR 私有网络搭建指南，使用开源软件和软件定义无线电（SDR）硬件实现。

### 技术栈

| 组件 | 软件/硬件 | 说明 |
|------|-----------|------|
| 核心网 | Open5GS | 开源 5G SA 核心网实现 |
| 基站 | srsRAN Project | 开源 5G gNB 实现 |
| 射频 | USRP B210 / BladeRF | SDR 硬件 |
| 终端 | COTS UE / srsUE | 商用手机或软件 UE |

### 快速链接

- 📚 [5G 系统架构](/guide/5g-architecture) - 先了解 5G 网络的基本概念
- ⚖️ [法律法规](/guide/rf-regulations) - **必读！** 了解无线电合规要求
- 📖 [环境准备](/guide/prerequisites) - 系统要求与软件安装
- 🔧 [Open5GS 安装](/open5gs/installation) - 核心网部署步骤
- 📡 [srsRAN 配置](/srsran/gnb-config) - gNB 参数配置

::: tip 提示
本项目仅供学习和研究目的，请确保在合法的频段和功率范围内进行实验。
:::

