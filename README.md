# NR Lab - 5G NR 实验文档

基于 Open5GS + srsRAN + SDR 的 5G 私有网络搭建指南。

5G NR Lab Documentation - Private 5G Network Setup Guide with Open5GS + srsRAN + SDR.

## 🚀 快速开始 / Quick Start

### 安装依赖 / Install Dependencies

```bash
npm install
```

### 本地开发 / Local Development

```bash
npm run docs:dev
```

访问 / Visit: `http://localhost:5173`

### 构建 / Build

```bash
npm run docs:build
```

### 预览构建结果 / Preview Build

```bash
npm run docs:preview
```

## 📖 文档结构 / Documentation Structure

```
docs/
├── index.md                 # 中文首页 / Chinese Home
├── en/
│   └── index.md             # 英文首页 / English Home
├── guide/                   # 入门指南 / Getting Started
│   ├── getting-started.md
│   ├── prerequisites.md
│   └── hardware.md
├── open5gs/                 # Open5GS 核心网 / Core Network
│   ├── index.md
│   ├── installation.md
│   ├── configuration.md
│   └── subscriber.md
└── srsran/                  # srsRAN 基站 / Base Station
    ├── index.md
    ├── installation.md
    ├── gnb-config.md
    └── ue-config.md
```

## 🌐 多语言支持 / Multilingual Support

本文档支持中英双语：
- 简体中文 (默认 / Default)
- English

This documentation supports bilingual:
- Simplified Chinese (Default)
- English

## 📡 技术栈 / Technology Stack

| 组件 / Component | 软件 / Software | 说明 / Description |
|------------------|-----------------|-------------------|
| 核心网 / Core | Open5GS | 开源 5G SA 核心网 / Open source 5G SA core |
| 基站 / RAN | srsRAN Project | 开源 5G gNB / Open source 5G gNB |
| 射频 / RF | USRP B210 | SDR 硬件 / SDR hardware |

## 📄 许可证 / License

MIT License
