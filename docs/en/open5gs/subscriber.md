# Subscriber Management

This page explains how to add and manage UE subscribers in Open5GS.

## WebUI Management

### Access WebUI

1. Ensure WebUI service is running:
   ```bash
   sudo systemctl status open5gs-webui
   ```

2. Access `http://localhost:9999`

3. Default credentials:
   - Username: `admin`
   - Password: `1423`

### Add Subscriber

1. Click **Subscriber** in the left menu
2. Click the **+** button in the top right
3. Fill in subscriber information:

| Field | Example | Description |
|-------|---------|-------------|
| IMSI | 001010000000001 | International Mobile Subscriber Identity |
| Subscriber Key (K) | 465B5CE8B199B49FAA5F0A2EE238A6BC | Authentication key |
| Operator Key (OPc) | E8ED289DEBA952E4283B54E88E6183CA | Operator key |
| AMF | 8000 | Authentication Management Field |
| SQN | 000000000000 | Sequence Number |

4. Click **SAVE** to save

### Configure APN/DNN

When adding a subscriber, configure data network:

1. Click **+** in the **APN** section
2. Fill in:
   - **APN/DNN**: `internet`
   - **SST**: `1`
   - **SD**: `000001` (optional)
   - **Session Type**: `IPv4`

## MongoDB CLI Management

### View Subscribers

```bash
mongosh
use open5gs
db.subscribers.find().pretty()
```

### Add Subscriber

```javascript
db.subscribers.insertOne({
  imsi: '001010000000001',
  security: {
    k: '465B5CE8B199B49FAA5F0A2EE238A6BC',
    amf: '8000',
    op: null,
    opc: 'E8ED289DEBA952E4283B54E88E6183CA',
    sqn: NumberLong(0)
  },
  ambr: {
    downlink: { value: 1, unit: 3 },  // 1 Gbps
    uplink: { value: 1, unit: 3 }     // 1 Gbps
  },
  slice: [{
    sst: 1,
    default_indicator: true,
    session: [{
      name: 'internet',
      type: 3,  // IPv4
      ambr: {
        downlink: { value: 1, unit: 3 },
        uplink: { value: 1, unit: 3 }
      },
      qos: {
        index: 9,
        arp: {
          priority_level: 8,
          pre_emption_capability: 1,
          pre_emption_vulnerability: 1
        }
      }
    }]
  }],
  access_restriction_data: 32,
  subscriber_status: 0,
  network_access_mode: 0,
  subscribed_rau_tau_timer: 12
})
```

### Delete Subscriber

```javascript
db.subscribers.deleteOne({ imsi: '001010000000001' })
```

## SIM Card Configuration

### Programming SIM with pySim

Install pySim:

```bash
pip install pysim
```

Write parameters:

```bash
pySim-prog.py -p 0 -t sysmoUSIM-SJS1 \
    -i 001010000000001 \
    -k 465B5CE8B199B49FAA5F0A2EE238A6BC \
    -o E8ED289DEBA952E4283B54E88E6183CA \
    --mcc 001 \
    --mnc 01 \
    -a 12345678
```

Parameter description:

| Parameter | Description |
|-----------|-------------|
| `-p` | SIM card reader port |
| `-t` | SIM card type |
| `-i` | IMSI |
| `-k` | Ki (authentication key) |
| `-o` | OPc |
| `--mcc` | Mobile Country Code |
| `--mnc` | Mobile Network Code |
| `-a` | ADM key (SIM admin password) |

## Common Issues

### Authentication Failure

1. Verify IMSI is correct
2. Verify K and OPc match SIM card
3. Check AMF value (usually 8000)

### UE Cannot Get IP

1. Verify DNN configuration is correct
2. Check SMF session configuration
3. Verify UPF TUN interface

## Next Steps

- [srsRAN Overview](/en/srsran/) - Learn about base station configuration
- [gNB Configuration](/en/srsran/gnb-config) - Connect to core network

