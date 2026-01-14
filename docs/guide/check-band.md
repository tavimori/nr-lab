# 查看手机连接的频段

这是一个简单的小实验：查看你的手机当前连接到哪个基站、使用什么频段。通过这个实验，你可以直观地了解运营商在你所在位置部署的网络情况，并验证我们之前学习的频段知识。

::: tip 实验目标
- 了解如何查看手机的网络连接信息
- 识别当前连接的频段和频率
- 理解 ARFCN/NR-ARFCN 与实际频率的对应关系
:::

## iOS 设备

### 进入 Field Test 模式

在 iPhone 上，你可以通过拨打特殊代码进入 Field Test（场测）模式：

1. 打开**电话**应用
2. 拨打 `*3001#12345#*`
3. 点击拨号键

你将看到一个隐藏的诊断界面，显示当前的网络连接信息。

### 界面解读

<figure>
  <img src="/images/5g-architecture/ios-field-test-cu.jpg" alt="iOS Field Test 模式 - 中国联通 5G" style="max-width: 400px;" />
  <figcaption>iOS Field Test 模式显示中国联通 5G SA 网络信息</figcaption>
</figure>

从上图可以看到：

| 参数 | 值 | 说明 |
|------|-----|------|
| Carrier | 中国联通 | 当前运营商 |
| Network Capabilities | SA | 5G 独立组网模式 |
| PLMN | 460 01 | 移动国家码(460=中国) + 网络码(01=联通) |
| TAC | 8493400 | 跟踪区域码 |
| PCI | 927 | 物理小区标识 |
| RSRP | -67 dBm | 参考信号接收功率（信号强度） |
| SNR | 21.5 | 信噪比（信号质量） |
| 带宽 | 100 | 100 MHz 带宽 |
| **频段** | **78** | **n78 频段 (3.5 GHz)** |

::: info RSRP 信号强度参考
| RSRP 范围 | 信号质量 |
|-----------|----------|
| > -80 dBm | 极好 |
| -80 ~ -90 dBm | 好 |
| -90 ~ -100 dBm | 中等 |
| -100 ~ -110 dBm | 差 |
| < -110 dBm | 很差 |
:::

## Android 设备

Android 系统没有内置的 Field Test 模式，但可以通过第三方应用查看详细的网络信息。

### 推荐应用

| 应用名称 | 说明 | 下载 |
|----------|------|------|
| **网络信号大师 (NSG)** | 功能强大，显示详细的 5G NR 信息 | 应用商店搜索 |
| **Cellularz** | 界面简洁，支持多种网络制式 | Google Play |
| **NetMonster** | 开源应用，功能全面 | Google Play / F-Droid |

### NSG 界面解读

#### 示例 1：中国移动 5G (n41 频段)

<figure>
  <img src="/images/5g-architecture/androd-nsg-cm.jpg" alt="NSG 显示中国移动 5G" style="max-width: 400px;" />
  <figcaption>NSG 应用显示中国移动 5G SA 网络 - n41 频段</figcaption>
</figure>

关键信息解读：

| 参数 | 值 | 说明 |
|------|-----|------|
| PLMN | 460/00 | 中国移动 (MNC=00) |
| Band | N41 | n41 频段 |
| **SSB-ARFCN** | **504990** | 同步信号块的 NR-ARFCN |
| Freq. | 2524.95 MHz | 中心频率 |
| Band | TDD 2600+ | TDD 模式，2.6 GHz 频段 |
| PCI | 853 | 物理小区标识 |
| SS-RSRP | -78.0 dBm | 信号强度 |
| SS-SINR | 31.0 dB | 信噪比 |

**验证频率计算：**
```
ARFCN 504990 属于 0-3000 MHz 范围
F = 0.005 × 504990 = 2524.95 MHz ✓
```

#### 示例 2：中国联通 5G (n78 频段)

<figure>
  <img src="/images/5g-architecture/android-nsg-cu.jpg" alt="NSG 显示中国联通 5G" style="max-width: 400px;" />
  <figcaption>NSG 应用显示中国联通 5G SA 网络 - n78 频段</figcaption>
</figure>

关键信息解读：

| 参数 | 值 | 说明 |
|------|-----|------|
| PLMN | 460/01 | 中国联通 (MNC=01) |
| Band | N78 | n78 频段 |
| **SSB-ARFCN** | **627264** | 同步信号块的 NR-ARFCN |
| Freq. | 3408.96 MHz | 中心频率 |
| Band | TDD 3500 | TDD 模式，3.5 GHz 频段 |
| PCI | 927 | 物理小区标识 |
| SS-RSRP | -60.0 dBm | 信号强度（非常好） |
| SS-SINR | 27.0 dB | 信噪比 |

**验证频率计算：**
```
ARFCN 627264 属于 600000-2016666 范围
F = 3000 + 0.015 × (627264 - 600000)
F = 3000 + 408.96 = 3408.96 MHz ✓
```

## 实验练习

现在轮到你来尝试了！

### 步骤 1：查看当前网络

使用上述方法查看你手机当前连接的网络信息，记录以下参数：

- [ ] 运营商名称
- [ ] 网络类型 (4G/5G, SA/NSA)
- [ ] 频段 (Band)
- [ ] ARFCN/EARFCN
- [ ] 频率 (如果显示)
- [ ] RSRP (信号强度)

### 步骤 2：验证频率

根据记录的 ARFCN，使用 [频率计算公式](/guide/china-spectrum#频率计算公式) 计算中心频率，验证是否与显示的频率一致。

### 步骤 3：对照频段表

查阅 [中国运营商频段分配](/guide/china-spectrum) 页面，确认你当前使用的频段是否在该运营商的分配范围内。

## 常见问题

### 为什么我看到的是 4G 而不是 5G？

可能的原因：
1. **手机不支持 5G**：检查手机是否支持 5G
2. **5G 开关未开启**：在设置中检查是否启用了 5G
3. **所在位置无 5G 覆盖**：5G 覆盖不如 4G 广泛
4. **套餐限制**：部分套餐可能限制 5G 使用

### 为什么 RSRP 值是负数？

RSRP 以 dBm 为单位表示信号功率，由于无线信号经过传播后功率非常小（通常在微瓦级别），所以用 dBm 表示时总是负数。数值越大（越接近 0）表示信号越强。

### NSA 和 SA 有什么区别？

| 模式 | 全称 | 说明 |
|------|------|------|
| NSA | Non-Standalone | 非独立组网，5G 依赖 4G 核心网 |
| SA | Standalone | 独立组网，完整的 5G 网络 |

SA 模式能提供更低的延迟和更完整的 5G 特性。

## 延伸阅读

- [中国运营商频段分配](/guide/china-spectrum) - 了解各运营商的频段详情
- [5G 系统架构](/guide/5g-architecture) - 了解 5G 网络的组成
- [频谱分析](/guide/spectrum-analysis) - 使用 SDR 设备分析频谱
