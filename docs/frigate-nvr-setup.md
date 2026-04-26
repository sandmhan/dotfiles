# Frigate NVR Setup Guide

## Overview

Frigate is a Network Video Recorder (NVR) that provides real-time object detection for IP cameras. This configuration enables 24/7 recording, motion detection, and object recognition for homelab security monitoring.

## Features

- **Real-time Object Detection**: AI-powered detection of people, vehicles, animals
- **24/7 Recording**: Continuous video recording with configurable retention
- **MQTT Integration**: Home Assistant integration for alerts and automation
- **Web Interface**: Live camera feeds and recorded video playback
- **Mobile Access**: Remote viewing via web interface or mobile apps

## Architecture

```
┌─────────────────┐    RTSP     ┌──────────────────┐    HTTP/WS    ┌─────────────────┐
│   IP Cameras    │◄───────────►│   Frigate NVR    │◄─────────────►│   Web Interface │
│                 │             │                  │               │                 │
│ • Fishtank Cam  │             │ • Object Detection│               │ • Live View     │
│ • Office Cam    │             │ • Recording       │               │ • Playback      │
│ • Additional... │             │ • MQTT Alerts    │               │ • Configuration │
└─────────────────┘             └──────────────────┘               └─────────────────┘
                                          │
                                          │ MQTT
                                          ▼
                                ┌──────────────────┐
                                │ Home Assistant   │
                                │                  │
                                │ • Motion Alerts  │
                                │ • Camera Cards   │
                                │ • Automations    │
                                └──────────────────┘
```

## Configuration

### Camera Configuration

The Frigate module supports multiple cameras with individual settings:

```nix
# In systemModules/frigate.nix
services.frigate.settings = {
  cameras = {
    "fishtank" = {
      ffmpeg.inputs = [{
        path = "rtsp://192.168.50.174:554/ch0_0.h264";
        roles = [ "record" ];
      }];
      # Add detection, motion zones, etc.
    };
    
    "office" = {
      ffmpeg.inputs = [{
        path = "rtsp://192.168.50.210:554/ch0_0.h264";  
        roles = [ "detect" "record" ];
      }];
    };
  };
};
```

### Authentication Setup

For cameras requiring authentication, configure secrets:

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

### Recording Configuration

Configure recording retention and quality:

```nix
services.frigate.settings = {
  record = {
    enabled = true;
    retain = {
      days = 7;           # Keep recordings for 7 days
      mode = "all";       # Record continuously
    };
    events = {
      retain = {
        default = 10;     # Keep event recordings for 10 days
        mode = "active_objects";
      };
    };
  };
  
  # Storage optimization
  birdseye = {
    enabled = true;
    mode = "objects";     # Show cameras with detected objects
  };
};
```

## Deployment

### Prerequisites

1. **Network Setup**: Ensure cameras are accessible from NVR host
2. **Storage**: Adequate disk space for recordings (calculate: cameras × quality × retention)
3. **Compute**: Sufficient CPU for object detection (or GPU passthrough for AI acceleration)

### Storage Calculation

```bash
# Estimate storage needs
# Formula: (Bitrate × 3600 × 24 × Retention Days) / 8 / 1024^3 = GB per camera

# Example: 2 cameras, 2Mbps each, 7 days retention
# (2000000 × 3600 × 24 × 7 × 2) / 8 / 1024^3 ≈ 140GB total
```

### Deployment Steps

1. **Configure Camera Network**:
   ```bash
   # Ensure cameras are on IoT VLAN (10.0.10.0/24)
   # Configure firewall to allow NVR access to cameras
   iptables -A FORWARD -s 10.0.20.0/24 -d 10.0.10.0/24 -p tcp --dport 554 -j ACCEPT
   ```

2. **Deploy NVR Host**:
   ```bash
   # Using VM deployment pattern
   qmrestore /var/lib/vz/dump/vzdump-qemu-nixos-*.vma.zst 105 --storage local-zfs
   qm set 105 --cores 4 --memory 8192 --name nvr
   qm set 105 --net0 virtio,bridge=vmbr0,firewall=1
   
   # Add storage for recordings
   qm set 105 --scsi1 local-zfs:100,size=200G  # 200GB for recordings
   
   # Start and deploy configuration
   qm start 105
   nixos-rebuild switch --target-host sandmhan@[NVR_IP] --flake .#nvr --sudo
   ```

3. **Verify Installation**:
   ```bash
   # Check Frigate service status
   ssh nvr-host "sudo systemctl status frigate"
   
   # Verify web interface
   curl http://[NVR_IP]:5000/api/config
   
   # Test camera connectivity
   curl http://[NVR_IP]:5000/api/stats
   ```

## Camera Integration

### RTSP Stream Discovery

Find camera RTSP URLs:

```bash
# Common RTSP URL patterns:
# Hikvision: rtsp://ip:554/Streaming/Channels/101
# Dahua: rtsp://ip:554/cam/realmonitor?channel=1&subtype=0
# Reolink: rtsp://ip:554/h264Preview_01_main
# Generic: rtsp://ip:554/ch0_0.h264

# Test RTSP connectivity
ffplay rtsp://camera-ip:554/stream-path

# Or use VLC for testing
vlc rtsp://camera-ip:554/stream-path
```

### Camera Configuration Examples

#### Basic Camera (No Detection)
```nix
cameras."garage" = {
  ffmpeg.inputs = [{
    path = "rtsp://192.168.50.180:554/ch0_0.h264";
    roles = [ "record" ];
  }];
  
  record.enabled = true;
  snapshots.enabled = false;  # Recording only
};
```

#### Motion Detection Camera
```nix
cameras."frontdoor" = {
  ffmpeg.inputs = [
    {
      path = "rtsp://192.168.50.181:554/ch0_0.h264";
      roles = [ "detect" "record" ];
    }
    {
      path = "rtsp://192.168.50.181:554/ch0_1.h264";  # Lower quality for detection
      roles = [ "detect" ];
    }
  ];
  
  detect = {
    enabled = true;
    width = 1280;
    height = 720;
    fps = 5;  # Lower FPS for detection to save CPU
  };
  
  # Motion zones (ignore areas with frequent motion)
  motion = {
    mask = [ "0,0,1280,100" ];  # Ignore top area (sky/trees)
  };
  
  # Object zones (only detect in specific areas) 
  zones = {
    driveway = {
      coordinates = "100,720,500,720,500,400,100,400";
      objects = [ "car" "person" ];
    };
  };
};
```

### GPU Acceleration (Advanced)

For AI acceleration with dedicated GPU:

```nix
# In hosts/nvr/default.nix
virtualisation.oci-containers.backend = "docker";

# Pass GPU to container
virtualisation.oci-containers.containers.frigate = {
  image = "ghcr.io/blakeblackshear/frigate:stable";
  volumes = [
    "/var/lib/frigate:/config"
    "/var/lib/frigate/media:/media/frigate"
    "/etc/localtime:/etc/localtime:ro"
  ];
  
  # GPU passthrough for Coral or NVIDIA
  extraOptions = [
    "--device=/dev/apex_0:/dev/apex_0"  # Google Coral TPU
    # OR
    "--runtime=nvidia"                   # NVIDIA GPU
    "--gpus=all"
  ];
  
  ports = [ "5000:5000" ];
};

# Configure GPU detection in Frigate
services.frigate.settings.detectors = {
  coral = {
    type = "edgetpu";
    device = "usb";
  };
  # OR
  tensorrt = {
    type = "tensorrt";
    device = "0";  # GPU device ID
  };
};
```

## Home Assistant Integration

### MQTT Configuration

```nix
# Enable MQTT in Frigate
services.frigate.settings.mqtt = {
  enabled = true;
  host = "homeassistant.homelab.local";
  port = 1883;
  topic_prefix = "frigate";
  client_id = "frigate";
  # user = "frigate";  # Configure if MQTT requires auth
  # password = "password";
};
```

### Home Assistant Configuration

```yaml
# configuration.yaml in Home Assistant
mqtt:
  sensor:
    - name: "Frigate Detection FPS"
      state_topic: "frigate/stats"
      value_template: "{{ value_json.detection_fps }}"
      unit_of_measurement: "FPS"
    
    - name: "Frigate Process FPS"  
      state_topic: "frigate/stats"
      value_template: "{{ value_json.process_fps }}"
      unit_of_measurement: "FPS"

camera:
  - platform: mqtt
    name: "Office Camera"
    topic: "frigate/office/camera"
    
  - platform: mqtt
    name: "Fishtank Camera"
    topic: "frigate/fishtank/camera"

# Automation examples
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
        data:
          image: "http://frigate.homelab.local:5000{{ trigger.payload_json.snapshot }}"
```

## Monitoring & Maintenance

### Performance Monitoring

```bash
# Check Frigate stats
curl http://nvr-host:5000/api/stats | jq

# Monitor resource usage
ssh nvr-host "htop"

# Check storage usage
ssh nvr-host "df -h /var/lib/frigate"

# View Frigate logs
ssh nvr-host "sudo docker logs frigate -f"
```

### Storage Management

```bash
# Configure automatic cleanup
# Frigate automatically manages retention based on configuration

# Manual cleanup if needed
ssh nvr-host "find /var/lib/frigate/recordings -name '*.mp4' -mtime +7 -delete"

# Check camera connectivity
curl http://nvr-host:5000/api/config/cameras | jq '.[] | {name: .name, fps: .fps}'
```

### Backup Configuration

```bash
# Backup Frigate configuration
rsync -av nvr-host:/var/lib/frigate/config/ /backup/frigate-config/

# Backup important recordings (selective)
rsync -av nvr-host:/var/lib/frigate/recordings/important/ /backup/frigate-important/

# Database backup (SQLite)
ssh nvr-host "sqlite3 /var/lib/frigate/frigate.db .backup frigate-backup.db"
```

## Troubleshooting

### Common Issues

#### Camera Connection Issues
```bash
# Test RTSP stream directly
ffmpeg -i rtsp://camera-ip:554/path -t 10 -f null -

# Check network connectivity
ping camera-ip
telnet camera-ip 554

# Verify firewall rules
iptables -L -n | grep 554
```

#### High CPU Usage
```bash
# Check detection FPS vs process FPS
curl http://nvr-host:5000/api/stats

# Optimize detection settings:
# - Reduce detection FPS
# - Use lower resolution stream for detection
# - Adjust motion sensitivity
# - Add detection zones to exclude areas
```

#### Storage Issues
```bash
# Check disk usage
df -h /var/lib/frigate

# Review retention settings
curl http://nvr-host:5000/api/config | jq '.record.retain'

# Check for failed recordings
find /var/lib/frigate -name "*.tmp" -o -name "*.part"
```

### Log Analysis

```bash
# Frigate application logs
ssh nvr-host "sudo docker logs frigate --tail 100"

# System resource logs
ssh nvr-host "sudo journalctl -u frigate -f"

# Check for FFmpeg errors
ssh nvr-host "sudo docker logs frigate 2>&1 | grep ffmpeg"
```

## Security Considerations

### Network Isolation

```bash
# Cameras on isolated IoT VLAN
# NVR on services VLAN with controlled access

# Firewall rules example:
iptables -A FORWARD -s 10.0.20.0/24 -d 10.0.10.0/24 -p tcp --dport 554 -j ACCEPT
iptables -A FORWARD -s 10.0.10.0/24 -d 10.0.20.0/24 -m state --state RELATED,ESTABLISHED -j ACCEPT
```

### Access Control

```nix
# Configure authentication if exposing publicly
services.frigate.settings.auth = {
  enabled = true;
  secret_key = "your-secret-key";
};

# Use reverse proxy for external access
services.nginx.virtualHosts."nvr.your-domain.com" = {
  enableACME = true;
  forceSSL = true;
  locations."/" = {
    proxyPass = "http://127.0.0.1:5000";
    proxyWebsockets = true;
  };
};
```

### Privacy Considerations

- **Local Processing**: All AI detection happens locally
- **No Cloud**: Video data never leaves your network
- **Encryption**: Use HTTPS/WSS for remote access
- **Access Logs**: Monitor who accesses camera feeds
- **Retention Limits**: Automatically delete old recordings

This Frigate NVR setup provides a comprehensive security monitoring solution while maintaining privacy and local control over all video data.