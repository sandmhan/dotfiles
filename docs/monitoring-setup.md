# Monitoring Stack Setup Guide

## Overview

The homelab monitoring stack provides comprehensive observability for all infrastructure components using Prometheus for metrics collection and Grafana for visualization.

## Architecture

### Components

- **Prometheus**: Metrics collection, storage, and alerting engine
- **Grafana**: Visualization dashboards and alerting interface  
- **Node Exporters**: System metrics from all homelab hosts
- **Service Exporters**: Application-specific metrics (Matrix, WireGuard, etc.)

### Deployment Options

| Option | Resource Usage | Use Case |
|--------|----------------|----------|
| **VM** (`hosts/monitor/`) | 2 cores, 4GB RAM | Full-featured monitoring on dedicated hardware |
| **LXC** (`hosts/lxc-monitor/`) | 1 core, 1GB RAM | Resource-efficient deployment on constrained hardware |

## Prerequisites

### 1. Secrets Configuration

Generate and configure monitoring secrets:

```bash
# Generate Grafana admin password
GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 32)

# Create unencrypted secrets file
cat > secrets/monitoring/secrets.yaml << EOF
grafana-admin-password: $GRAFANA_ADMIN_PASSWORD
# smtp-password: your_smtp_password_here  # Optional for email alerts
EOF

# Encrypt with sops
sops -e -i secrets/monitoring/secrets.yaml

# Verify encryption
sops -d secrets/monitoring/secrets.yaml
```

### 2. Age Key Setup

Ensure monitoring host has age key for secret decryption:

```bash
# Generate age key on monitoring host
ssh user@monitoring-host "sudo mkdir -p /var/lib/sops-nix"
ssh user@monitoring-host "sudo age-keygen -o /var/lib/sops-nix/key.txt"

# Get public key for .sops.yaml
ssh user@monitoring-host "sudo age-keygen -y /var/lib/sops-nix/key.txt"

# Update .sops.yaml with the public key
# Replace age1... with actual public key:
# - &monitor_key age1your_actual_public_key_here
```

## Deployment

### Option A: VM Deployment (Recommended for Dedicated Hardware)

```bash
# 1. Deploy base VM using proven VMA pattern
qmrestore /var/lib/vz/dump/vzdump-qemu-nixos-*.vma.zst 107 --storage local-zfs

# 2. Configure VM resources
qm set 107 --cores 2 --memory 4096 --name monitor
qm set 107 --net0 virtio,bridge=vmbr0,firewall=1

# 3. Start VM and get IP
qm start 107
# Note the assigned IP address

# 4. Deploy monitoring configuration
nixos-rebuild switch --target-host sandmhan@[VM_IP] --flake .#monitor --sudo

# 5. Verify services
curl http://[VM_IP]:9090/-/ready  # Prometheus health
curl http://[VM_IP]:3000/api/health  # Grafana health
```

### Option B: LXC Deployment (Resource-Efficient)

```bash
# 1. Create LXC container (method depends on Proxmox setup)
# This requires LXC template creation - see LXC documentation

# 2. Deploy monitoring configuration to container
nixos-rebuild switch --target-host monitor@[CONTAINER_IP] --flake .#lxc-monitor --sudo

# 3. Verify services (same as VM)
```

## Configuration

### Prometheus Targets

The monitoring configuration automatically scrapes metrics from:

```yaml
# Default scrape targets (configured in systemModules/monitoring.nix)
node-exporters:
  - 10.0.0.6:9100      # matrix server
  - 10.0.0.5:9100      # agent-sandbox  
  - 10.0.0.7:9100      # nixos-builder
  - 10.0.0.167:9100    # fitness (wger VM)
  - localhost:9100      # monitoring host itself

matrix-services:
  - 10.0.0.6:8008      # Matrix Synapse metrics endpoint

# Matrix also has an additionalScrapeConfigs job named matrix-synapse
# with metrics_path = /_synapse/metrics.

wger-app:                               # django-prometheus (30s interval)
  - 10.0.0.167:8000                     # path: /prometheus/metrics

wger-fitness:                           # Custom Python exporter (5m interval)
  - 10.0.0.167:9101                     # Fitness business metrics

wireguard:
  # VPN server metrics (populated when VPN is deployed)
```

### Adding New Targets

To monitor additional services, update the monitoring configuration:

```nix
# In hosts/monitor/default.nix or hosts/lxc-monitor/default.nix
homelab.monitoring.prometheus.staticTargets = {
  "node-exporters" = [
    # ... existing targets
    "10.0.0.TBD:9100"  # New service host (assign IP when deployed)
  ];
  
  "matrix-services" = [
    "10.0.0.6:8008"  # Matrix Synapse metrics endpoint
  ];

  "homelab-services" = [
    # Non-Matrix service metrics endpoints go here after deployment.
    "10.0.0.TBD:8080"  # New service metrics endpoint (assign IP when deployed)
  ];
};

# Or add complex scrape configurations
homelab.monitoring.prometheus.additionalScrapeConfigs = [
  {
    job_name = "custom-service";
    static_configs = [
      {
        targets = [ "10.0.0.TBD:9091" ];
        labels = {
          service = "custom-app";
          environment = "production";
        };
      }
    ];
    metrics_path = "/custom/metrics";
    scrape_interval = "30s";
  }
];
```

### Grafana Configuration

#### Default Dashboards

The monitoring stack includes pre-configured dashboards (auto-provisioned from `systemModules/grafana-dashboards/`):

- **Fleet Overview**: System metrics summary across all hosts
- **Node Overview**: Detailed per-host system metrics
- **Prometheus Stats**: Monitoring system health
- **Infrastructure Health**: Service availability and network overview
- **Fitness Overview**: Body weight trends, workout tracking, nutrition macros, body measurements (from wger exporter)

#### Adding Custom Dashboards

1. **Via Web Interface**:
   - Access Grafana at `http://[monitoring-host]:3000`
   - Login: `admin` / `[encrypted-password-from-secrets]`
   - Create dashboards in the "Homelab" folder

2. **Via Configuration**:
   ```nix
   # Add to monitoring configuration
   systemd.tmpfiles.rules = [
     "L+ /var/lib/grafana/dashboards/homelab/custom.json - - - - ${./path/to/dashboard.json}"
   ];
   ```

#### Notification Channels

Configure alerting channels (requires SMTP setup):

```nix
# In monitoring configuration
homelab.monitoring.grafana.smtp = {
  enable = true;
  host = "smtp.gmail.com";
  user = "alerts@yourdomain.com";
  # passwordFile managed by sops-nix
};
```

## Network Access

### Firewall Configuration

The monitoring stack is accessible on these ports:

| Service | Port | Access |
|---------|------|--------|
| Grafana Web UI | 3000 | Homelab network (10.0.0.0/24) |
| Prometheus Web UI | 9090 | Homelab network (10.0.0.0/24) |
| Node Exporter | 9100 | Monitoring host only |

### Remote Access via VPN

Once WireGuard VPN is deployed, access monitoring remotely:

```bash
# Connect to homelab VPN
sudo wg-quick up homelab

# Access services
curl http://10.0.0.10:3000  # Grafana (via VPN)
curl http://10.0.0.10:9090  # Prometheus (via VPN)
```

### DNS Configuration (Optional)

Add DNS entries for easier access:

```bash
# Add to your DNS server or /etc/hosts
10.0.0.10 grafana.homelab.local
10.0.0.10 prometheus.homelab.local
```

## Monitoring Integration

### Enable Metrics on Services

For services to appear in monitoring, ensure they expose metrics:

#### Matrix Synapse
```nix
# In Matrix configuration
services.matrix-synapse.settings.enable_metrics = true;
services.matrix-synapse.settings.listeners = [
  {
    port = 8008;
    bind_addresses = [ "0.0.0.0" ];
    type = "http";
    tls = false;
    x_forwarded = true;
    resources = [
      { names = [ "metrics" ]; }
    ];
  }
];
```

#### Custom Applications
```nix
# Expose Prometheus metrics endpoint
networking.firewall.allowedTCPPorts = [ 9090 ];

# Add to Prometheus scrape targets in monitoring config
```

### Service Discovery

For dynamic service discovery (advanced):

```nix
# In Prometheus configuration
homelab.monitoring.prometheus.additionalScrapeConfigs = [
  {
    job_name = "consul-services";
    consul_sd_configs = [
      {
        server = "consul.homelab.local:8500";
        services = [ "homelab" ];
      }
    ];
  }
];
```

## Alerting

### Basic Alert Rules

Create alert rules for critical conditions:

```nix
# Add to monitoring configuration
services.prometheus.rules = [
  ''
    groups:
    - name: homelab-alerts
      rules:
      - alert: HostDown
        expr: up == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Host {{ $labels.instance }} is down"
          
      - alert: HighCPUUsage
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          
      - alert: LowDiskSpace
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 10
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
  ''
];
```

### Notification Integration

#### Matrix Notifications
```nix
# Configure Matrix webhook for alerts
services.prometheus.alertmanager.configuration = {
  route = {
    group_by = [ "alertname" ];
    group_wait = "10s";
    group_interval = "10s";
    repeat_interval = "1h";
    receiver = "matrix-webhook";
  };
  
  receivers = [
    {
      name = "matrix-webhook";
      webhook_configs = [
        {
          url = "http://matrix.homelab.local:8080/_matrix/push/v1/notify";
          send_resolved = true;
        }
      ];
    }
  ];
};
```

## Maintenance

### Data Retention

Configure retention policies based on available storage:

```nix
# In monitoring configuration
homelab.monitoring.prometheus.retention = "365d";  # VM: 1 year
# homelab.monitoring.prometheus.retention = "180d"; # LXC: 6 months
```

### Backup Configuration

```bash
# Backup Grafana dashboards and configuration
rsync -av monitoring-host:/var/lib/grafana/ /backup/grafana/

# Backup Prometheus data (large - consider retention strategy)
rsync -av monitoring-host:/var/lib/prometheus/ /backup/prometheus/

# Backup configuration (already in git)
git push origin main
```

### System Updates

```bash
# Update monitoring stack
nixos-rebuild switch --target-host user@monitoring-host --flake .#monitor --upgrade

# Restart services if needed
ssh user@monitoring-host "sudo systemctl restart prometheus grafana"
```

## Troubleshooting

### Common Issues

#### Grafana Login Failed
```bash
# Check admin password in secrets
sops -d secrets/monitoring/secrets.yaml

# Reset Grafana admin password
ssh monitoring-host "sudo grafana-cli admin reset-admin-password NEW_PASSWORD"
```

#### Prometheus Targets Down
```bash
# Check target connectivity
curl http://target-host:9100/metrics

# Verify firewall rules
ssh target-host "sudo iptables -L | grep 9100"

# Check node exporter service
ssh target-host "sudo systemctl status prometheus-node-exporter"
```

#### Missing Metrics
```bash
# Verify Prometheus configuration
curl http://monitoring-host:9090/api/v1/targets

# Check scrape errors
curl http://monitoring-host:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'

# Validate Prometheus config
ssh monitoring-host "sudo promtool check config /etc/prometheus/prometheus.yml"
```

### Log Analysis

```bash
# Prometheus logs
ssh monitoring-host "sudo journalctl -u prometheus -f"

# Grafana logs  
ssh monitoring-host "sudo journalctl -u grafana -f"

# Node exporter logs
ssh monitoring-host "sudo journalctl -u prometheus-node-exporter -f"
```

### Performance Tuning

For high-metric environments:

```nix
# Increase Prometheus resources
homelab.monitoring.prometheus.extraFlags = [
  "--storage.tsdb.retention.size=50GB"
  "--query.max-concurrency=20"
  "--query.timeout=30s"
  "--web.max-connections=512"
];

# Optimize Grafana
services.grafana.settings.database = {
  type = "postgres";  # Use PostgreSQL instead of SQLite
  host = "postgres.homelab.local";
  name = "grafana";
  user = "grafana";
  # password via sops
};
```

## Integration with Other Services

### Home Assistant
```nix
# Add Home Assistant metrics to monitoring
homelab.monitoring.prometheus.additionalScrapeConfigs = [
  {
    job_name = "home-assistant";
    static_configs = [
      {
        targets = [ "homeassistant.homelab.local:8123" ];
      }
    ];
    metrics_path = "/api/prometheus";
    authorization = {
      credentials_file = "/var/lib/secrets/hass-token";
    };
  }
];
```

### Router/Network Monitoring
```nix
# Add SNMP monitoring for network devices
homelab.monitoring.prometheus.additionalScrapeConfigs = [
  {
    job_name = "snmp-devices";
    static_configs = [
      {
        targets = [ "router.homelab.local" "switch.homelab.local" ];
      }
    ];
    metrics_path = "/snmp";
    params = {
      module = [ "if_mib" ];
    };
    relabel_configs = [
      {
        source_labels = [ "__address__" ];
        target_label = "__param_target";
      }
      {
        source_labels = [ "__param_target" ];
        target_label = "instance";
      }
      {
        target_label = "__address__";
        replacement = "snmp-exporter.homelab.local:9116";
      }
    ];
  }
];
```

This comprehensive monitoring stack provides the observability foundation needed to manage your growing homelab infrastructure effectively.