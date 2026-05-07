# Home Assistant Setup Guide

## Architecture Overview

The Home Assistant deployment consists of several integrated services:

```
                    +-------------------+
                    |   nginx (port 80) |
                    |  reverse proxy    |
                    +--------+----------+
                             |
                    +--------v----------+
                    | Home Assistant     |
                    | (port 8123)        |
                    |                    |
                    | - Automations      |
                    | - Integrations     |
                    | - Dashboard        |
                    +---+----------+----+
                        |          |
              +---------v--+  +---v-----------+
              | PostgreSQL  |  | Mosquitto MQTT|
              | (recorder)  |  | (port 1883)   |
              | unix socket |  | (WS: 1884)    |
              +-------------+  +-------+-------+
                                       |
                               +-------v-------+
                               | IoT Devices   |
                               | (future VLAN) |
                               | Zigbee/Z-Wave |
                               | ESPHome       |
                               +---------------+
```

### Components

| Component | Purpose | Port | Notes |
|-----------|---------|------|-------|
| **Home Assistant** | Core automation engine | 8123 | NixOS native service |
| **Mosquitto MQTT** | IoT device message broker | 1883 (TCP), 1884 (WS) | Anonymous access on homelab network |
| **PostgreSQL** | Recorder database backend | unix socket | Replaces default SQLite for better performance |
| **nginx** | Reverse proxy with WebSocket support | 80 | Handles HA frontend WebSocket connections |
| **Node Exporter** | System metrics for Prometheus | 9100 | Scraped by monitoring stack |

## Deployment Options

### VM Deployment (Recommended)

The VM deployment supports USB passthrough for Zigbee/Z-Wave dongles.

```bash
# 1. Build base VMA image (if not already done)
nixos-rebuild build-image --image-variant proxmox --flake .#initialProxmoxVMA

# 2. Create VM from VMA on Proxmox
qmrestore /var/lib/vz/dump/vzdump-qemu-nixos-*.vma.zst 103 --storage local-zfs --force

# 3. Configure VM resources
qm set 103 --cores 2 --memory 4096 --name homeassistant
qm set 103 --net0 virtio,bridge=vmbr0,firewall=1

# 4. (Optional) USB passthrough for Zigbee/Z-Wave
# Find device IDs: lsusb | grep -i "silicon labs\|aeotec\|conbee"
qm set 103 --usb0 host=10c4:ea60  # Example: SONOFF Zigbee dongle
qm set 103 --usb1 host=0658:0200  # Example: Aeotec Z-Stick

# 5. Start VM and deploy
qm start 103
nixos-rebuild switch --target-host sandmhan@10.0.0.TBD --flake .#homeassistant --sudo
```

### LXC Container Deployment

Lighter alternative without USB passthrough. Use network-based Zigbee bridges (e.g., Zigbee2MQTT via ser2net) instead.

```bash
# Create LXC container on Proxmox, then deploy:
nixos-rebuild switch --target-host hass@10.0.0.TBD --flake .#lxc-homeassistant --sudo
```

## USB Device Passthrough Setup

### Finding Device IDs

On the Proxmox host:

```bash
# List all USB devices
lsusb

# Common Zigbee dongles:
# Bus 001 Device 003: ID 10c4:ea60 Silicon Labs CP210x (SONOFF Zigbee 3.0 USB Dongle Plus)
# Bus 001 Device 004: ID 1cf1:0030 Dresden Elektronik (ConBee II)

# Common Z-Wave sticks:
# Bus 001 Device 005: ID 0658:0200 Sigma Designs (Aeotec Z-Stick Gen5+)
```

### Proxmox USB Configuration

```bash
# Pass USB device to VM (use vendor:product IDs from lsusb)
qm set 103 --usb0 host=10c4:ea60
qm set 103 --usb1 host=0658:0200

# Verify passthrough
qm config 103 | grep usb
```

### Verify in VM

After booting, SSH into the VM:

```bash
# Check devices are visible
ls -la /dev/ttyUSB*
ls -la /dev/serial/by-id/

# The hass user should have dialout group access
groups hass
```

### Update Device Paths

Update `hosts/homeassistant/default.nix` with the actual device paths:

```nix
usb = {
  enable = true;
  zigbeeDevice = "/dev/serial/by-id/usb-Silicon_Labs_Sonoff_Zigbee_3.0_USB_Dongle_Plus-if00-port0";
  zwaveDevice = "/dev/serial/by-id/usb-0658_0200-if00";
};
```

## IoT VLAN Integration (Future)

> **Note:** VLANs are planned but not yet implemented. All services currently run on the flat `10.0.0.0/24` network. The VLAN structure below describes the future target architecture.

### Network Requirements

When VLANs are implemented, Home Assistant will need to communicate with IoT devices on VLAN 10 (10.0.10.0/24). This will require:

1. **Protectli Router Configuration**: Enable inter-VLAN routing between Services VLAN (20) and IoT VLAN (10)
2. **Firewall Rules**: The systemModule automatically adds iptables rules for:
   - IoT VLAN -> MQTT broker (port 1883)
   - Home Assistant -> IoT VLAN (outbound for device control/discovery)
   - Management VLAN -> MQTT (for debugging)

### Router Firewall Rules (Protectli/OPNsense) — Future

These rules will be needed when VLANs are implemented:

```
# Allow HA (Services VLAN) to reach IoT devices
Source: [HA_IP]  Destination: 10.0.10.0/24  Action: ALLOW

# Allow IoT devices to reach MQTT broker
Source: 10.0.10.0/24  Destination: [HA_IP]  Port: 1883  Action: ALLOW

# Block IoT from reaching other services
Source: 10.0.10.0/24  Destination: [Services_Subnet]  Action: DENY (except above)
```

### mDNS/Discovery

For device discovery across VLANs, you may need an mDNS repeater (avahi) or static device configuration in Home Assistant.

## Frigate Camera Integration

When the NVR VM is deployed, enable Frigate integration:

1. Update `hosts/homeassistant/default.nix`:
   ```nix
   frigate = {
     enable = true;
     url = "http://10.0.0.TBD:5000";
   };
   ```

2. In Home Assistant UI, add the Frigate integration:
   - Settings -> Devices & Services -> Add Integration -> Frigate
   - URL: `http://10.0.0.TBD:5000`

3. Frigate provides:
   - Camera feeds in HA dashboard
   - Object detection events as HA events
   - Person/pet/vehicle detection for automations

## Monitoring Integration

### Prometheus Metrics

Home Assistant exposes Prometheus metrics at `/api/prometheus`. To scrape them:

1. Generate a long-lived access token in HA UI:
   - Profile -> Long-Lived Access Tokens -> Create Token

2. Add scrape target to monitoring module (`hosts/monitor/default.nix`):
   ```nix
   homelab.monitoring.prometheus.additionalScrapeConfigs = [
     {
       job_name = "homeassistant";
       static_configs = [{ targets = [ "10.0.0.TBD:8123" ]; }];
       metrics_path = "/api/prometheus";
       bearer_token_file = "/path/to/ha-token";
       scrape_interval = "30s";
     }
   ];
   ```

### Grafana Dashboard

Import the Home Assistant community Grafana dashboard:
- Dashboard ID: 15832 (Home Assistant Overview)
- Data source: Prometheus

### Node Exporter

System-level metrics (CPU, memory, disk) are automatically exported on port 9100. Add `10.0.0.TBD:9100` to the monitoring module's node exporter targets.

## Mobile App Setup

1. Install "Home Assistant" app from App Store / Play Store
2. Connect via local URL: `http://10.0.0.TBD:8123`
3. For remote access (via WireGuard VPN):
   - Connect to homelab VPN first
   - App will automatically reconnect to HA

## Common Automations

### Presence Detection
```yaml
automation:
  - alias: "Arrive Home"
    trigger:
      - platform: state
        entity_id: person.sandmhan
        to: "home"
    action:
      - service: light.turn_on
        target:
          area_id: living_room
```

### Pet Care (Pet Feeder Timer)
```yaml
automation:
  - alias: "Feed Cats Morning"
    trigger:
      - platform: time
        at: "07:00:00"
    action:
      - service: switch.turn_on
        target:
          entity_id: switch.cat_feeder
```

### Camera Motion Alerts
```yaml
automation:
  - alias: "Motion Detected Outside"
    trigger:
      - platform: state
        entity_id: binary_sensor.frigate_front_door_motion
        to: "on"
    action:
      - service: notify.mobile_app
        data:
          title: "Motion Detected"
          message: "Motion at front door"
```

## SOPS Secrets

### Populate Secrets

```bash
# Generate secrets
HA_SECRET=$(openssl rand -base64 32)
MQTT_PASSWORD=$(openssl rand -base64 24)
POSTGRES_PASSWORD=$(openssl rand -base64 24)

# Set secrets in SOPS file
sops --set '["ha-secrets"]' "\"$HA_SECRET\"" secrets/homeassistant/secrets.yaml
sops --set '["mqtt-password"]' "\"$MQTT_PASSWORD\"" secrets/homeassistant/secrets.yaml
sops --set '["postgres-password"]' "\"$POSTGRES_PASSWORD\"" secrets/homeassistant/secrets.yaml

# Verify
sops -d secrets/homeassistant/secrets.yaml
```

### Age Key Setup

The VM/container needs an age key to decrypt secrets at boot:

```bash
# On the target host, derive age key from SSH host key
ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key > /var/lib/sops-nix/key.txt
chmod 600 /var/lib/sops-nix/key.txt

# Get the public age key for .sops.yaml
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

Add the public age key to `.sops.yaml` in the repo root.

## Troubleshooting

### Home Assistant Won't Start

```bash
# Check service status
sudo systemctl status home-assistant
sudo journalctl -u home-assistant -f

# Check configuration validity
sudo -u hass hass --script check_config -c /var/lib/hass

# Check for port conflicts
ss -tlnp | grep 8123
```

### MQTT Broker Issues

```bash
# Check Mosquitto status
sudo systemctl status mosquitto
sudo journalctl -u mosquitto -f

# Test MQTT connectivity
mosquitto_sub -h localhost -t '#' -v  # Subscribe to all topics
mosquitto_pub -h localhost -t test -m "hello"  # Publish test message

# Check MQTT from IoT VLAN
mosquitto_sub -h 10.0.0.TBD -p 1883 -t '#' -v
```

### PostgreSQL Issues

```bash
# Check PostgreSQL status
sudo systemctl status postgresql
sudo journalctl -u postgresql -f

# Check database
sudo -u postgres psql -c "SELECT 1;" hass
sudo -u postgres psql hass -c "\dt"  # List tables

# Check recorder is using PostgreSQL (not SQLite)
grep -i "db_url" /var/lib/hass/configuration.yaml
```

### USB Device Not Found

```bash
# Check USB devices in VM
lsusb
ls -la /dev/ttyUSB*
ls -la /dev/serial/by-id/

# Check Proxmox USB passthrough
# On Proxmox host:
qm config 103 | grep usb

# Check udev rules
udevadm info --name=/dev/ttyUSB0 --attribute-walk

# Check hass user has dialout group
id hass
```

### Firewall Issues

```bash
# Check iptables rules
sudo iptables -L -n -v

# Test connectivity from IoT VLAN
# From an IoT device:
nc -zv 10.0.0.TBD 1883  # Test MQTT
nc -zv 10.0.0.TBD 8123  # Test HA
```

### Health Check

```bash
# Run the built-in health check
sudo systemctl start homeassistant-health-check
sudo journalctl -u homeassistant-health-check

# Manual checks
curl -f http://localhost:8123/api/ && echo "HA OK"
curl -f http://localhost:80/ && echo "nginx OK"
mosquitto_sub -h localhost -t '$SYS/broker/version' -C 1 -W 5 && echo "MQTT OK"
sudo -u postgres psql -c "SELECT 1;" hass && echo "PostgreSQL OK"
```
