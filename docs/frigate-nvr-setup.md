# Frigate NVR Setup Guide

## Overview

Frigate is a Network Video Recorder (NVR) that provides real-time object detection for IP cameras. This module uses an option-based configuration system where cameras, detectors, recording, and MQTT settings are defined declaratively via NixOS options and translated into `services.frigate.settings`.

## Architecture

```
                    IoT VLAN (10.0.10.0/24)          Services VLAN (10.0.20.0/24)
                    +-----------------------+         +---------------------------+
                    |   IP Cameras          |  RTSP   |   Frigate NVR VM          |
                    |   - fishtank          |-------->|   - Object Detection      |
                    |   - office            |         |   - 24/7 Recording        |
                    |   - (additional...)   |         |   - Web UI (:5000)        |
                    +-----------------------+         |   - go2rtc (:8554)        |
                                                      |   - RTSP relay (:1935)    |
                                                      +---------------------------+
                                                                |
                                          MQTT                  |  HTTP/WS
                                  +----------------+    +------------------+
                                  | Home Assistant |    | Web Interface    |
                                  | - Alerts       |    | - Live View      |
                                  | - Automations  |    | - Playback       |
                                  +----------------+    +------------------+
```

## Module Options

The Frigate module is defined in `systemModules/frigate.nix` and provides the following options under `homelab.frigate`:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable Frigate NVR |
| `deploymentType` | enum | "vm" | "vm" or "container" |
| `resourceProfile` | enum | "standard" | "minimal", "standard", or "high" |
| `cameras` | attrsOf camera | {} | Camera definitions (see below) |
| `mqtt.enabled` | bool | true | Enable MQTT integration |
| `mqtt.host` | str | "localhost" | MQTT broker host |
| `mqtt.port` | port | 1883 | MQTT broker port |
| `detector.type` | enum | "cpu" | "cpu" or "http" (for AI server) |
| `detector.httpUrl` | str | "" | URL for HTTP detector API |
| `recording.enabled` | bool | true | Enable recording |
| `recording.retainDays` | int | 7 | Days to retain recordings |
| `recording.retainMode` | enum | "all" | "all", "motion", or "active_objects" |
| `storage.path` | str | "/var/lib/frigate" | Storage path |
| `nfs.enable` | bool | false | Mount NFS share for storage |
| `sops.enableCameraSecrets` | bool | true | Create SOPS secrets for camera URLs |

### Camera Options

Each camera in `homelab.frigate.cameras` supports:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rtspUrl` | str | (required) | RTSP stream URL |
| `roles` | list of enum | ["record"] | "detect" and/or "record" |
| `detect.enabled` | bool | false | Enable object detection |
| `detect.width` | int | 1280 | Detection width |
| `detect.height` | int | 720 | Detection height |
| `detect.fps` | int | 5 | Detection FPS |
| `zones` | attrsOf zone | {} | Detection zones |
| `motionMask` | list of str | [] | Motion mask coordinates |

## Configuration Examples

### Basic Host Config (hosts/nvr/default.nix)

```nix
homelab.frigate = {
  enable = true;
  deploymentType = "vm";
  resourceProfile = "standard";

  cameras = {
    fishtank = {
      rtspUrl = "rtsp://192.168.50.174:554/ch0_0.h264";
      roles = [ "record" ];
      detect.enabled = false;
    };

    office = {
      rtspUrl = "rtsp://192.168.50.210:554/ch0_0.h264";
      roles = [ "detect" "record" ];
      detect = {
        enabled = true;
        width = 1280;
        height = 720;
        fps = 5;
      };
    };
  };

  mqtt = {
    enabled = true;
    host = "homeassistant.homelab.local";
    port = 1883;
  };

  detector.type = "cpu";

  recording = {
    enabled = true;
    retainDays = 7;
  };
};
```

### Adding a Camera with Detection Zones

```nix
homelab.frigate.cameras.frontdoor = {
  rtspUrl = "rtsp://192.168.50.181:554/ch0_0.h264";
  roles = [ "detect" "record" ];
  detect = {
    enabled = true;
    width = 1280;
    height = 720;
    fps = 5;
  };
  zones = {
    driveway = {
      coordinates = "100,720,500,720,500,400,100,400";
      objects = [ "car" "person" ];
    };
  };
  motionMask = [ "0,0,1280,100" ]; # Ignore sky/trees
};
```

### Using HTTP Detector (AI Server)

```nix
homelab.frigate.detector = {
  type = "http";
  httpUrl = "http://ai-server.homelab.local:5000/v1/vision/detection";
};
```

### NFS Storage (when NAS is deployed)

```nix
homelab.frigate.nfs = {
  enable = true;
  server = "nas.homelab.local";
  path = "/export/frigate";
  mountPoint = "/mnt/nas-frigate";
};
```

## Authentication Setup

Camera RTSP URLs containing credentials are managed via SOPS secrets. The module automatically creates a secret at `cameras/<name>/rtsp_url` for each camera when `sops.enableCameraSecrets = true`.

```bash
# Add camera credentials to secrets/nvr/secrets.yaml
cat > secrets/nvr/secrets.yaml << EOF
cameras:
  fishtank:
    rtsp_url: rtsp://username:password@192.168.50.174:554/ch0_0.h264
  office:
    rtsp_url: rtsp://username:password@192.168.50.210:554/ch0_0.h264
EOF

# Encrypt with sops
sops -e -i secrets/nvr/secrets.yaml
```

Note: Since `services.frigate` generates config at build time, switching to authenticated cameras at runtime requires using `virtualisation.oci-containers` with a sops-templated config file mounted as `/config/config.yml`.

## Deployment

### Prerequisites

1. Proxmox VM created from base VMA image
2. Camera network accessible from NVR VM (IoT VLAN routing configured)
3. Adequate disk space for recordings

### Storage Calculation

```
Formula: (Bitrate x 3600 x 24 x RetentionDays) / 8 / 1024^3 = GB per camera
Example: 2 cameras, 2Mbps each, 7 days = ~140GB total
```

### Deploy Steps

```bash
# 1. Create VM from base image
qmrestore /var/lib/vz/dump/vzdump-qemu-nixos-*.vma.zst 105 --storage local-zfs
qm set 105 --cores 4 --memory 8192 --name nvr

# 2. Add recording storage
qm set 105 --scsi1 local-zfs:100,size=200G

# 3. Start and deploy
qm start 105
nixos-rebuild switch --target-host sandmhan@[NVR_IP] --flake .#nvr --sudo
```

### Build Command

```bash
# Dry-run to check for errors
nix build --dry-run .#nixosConfigurations.nvr.config.system.build.toplevel

# Note: requires hardware-configuration.nix for full build (present on deployed VM)
```

### Verify

```bash
# Check service status
ssh nvr "sudo systemctl status frigate"

# Check web UI
curl http://[NVR_IP]:5000/api/version

# Check camera stats
curl http://[NVR_IP]:5000/api/stats
```

## Firewall Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 5000 | TCP | Frigate web UI |
| 1935 | TCP | RTSP relay |
| 8554 | TCP | go2rtc WebRTC/RTSP |
| 9100 | TCP | Prometheus node exporter |

## Integration

### Home Assistant (MQTT)

Configure MQTT in Frigate to publish events to Home Assistant:

```yaml
# Home Assistant configuration.yaml
automation:
  - alias: "Motion Alert"
    trigger:
      platform: mqtt
      topic: "frigate/events"
    condition:
      condition: template
      value_template: "{{ trigger.payload_json.type == 'new' }}"
    action:
      service: notify.mobile_app
      data:
        message: "Motion detected: {{ trigger.payload_json.label }}"
```

### Monitoring

The NVR includes a Prometheus node exporter on port 9100. A health check timer runs every 5 minutes to verify the Frigate API is responsive.

## Troubleshooting

### Camera Connection Issues

```bash
# Test RTSP stream
ffmpeg -i rtsp://camera-ip:554/path -t 10 -f null -

# Check network connectivity
ping camera-ip
```

### High CPU Usage

- Reduce detection FPS in camera options
- Use lower resolution for detection stream
- Add motion masks to exclude high-activity areas
- Switch to HTTP detector with dedicated AI server

### Storage Issues

```bash
# Check disk usage
df -h /var/lib/frigate

# Review retention
curl http://[NVR_IP]:5000/api/config | jq '.record.retain'
```

### Service Not Starting

```bash
# Check logs
journalctl -u frigate -f

# Verify config
cat /var/lib/frigate/config/config.yml
```
