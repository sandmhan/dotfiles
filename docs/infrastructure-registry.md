# Infrastructure Registry

Single source of truth for all deployed and planned infrastructure. **Update this file in the same commit as any host change.**

## Quick Reference

> **IMPORTANT**: All systemModules follow new standardized architecture patterns as of April 2026. See [SystemModules Architecture Guide](./systemModules-architecture.md) for implementation details and [SystemModules Overview](./systemModules-overview.md) for service documentation.

### Deployment Commands
```bash
# Build VMA base image
nixos-rebuild build-image --image-variant proxmox --flake .#initialProxmoxVMA

# Deploy to existing VM
nixos-rebuild switch --target-host user@[HOST_IP] --flake .#[CONFIG_NAME] --sudo

# Test configuration build
nixos-rebuild dry-build --flake .#[CONFIG_NAME]
```

### Access Methods
- **SSH**: `ssh user@[HOST_IP]` or `ssh user@[HOSTNAME].homelab.local`
- **Web Services**: `http://[HOST_IP]:[PORT]` or `https://[SERVICE].homelab.local`
- **VPN Access**: Connect via WireGuard VPN for remote access to all services

---

## Proxmox Nodes

| Node | Hardware | CPU | RAM | Storage | IP Address | Web UI | SSH Access | Status |
|------|----------|-----|-----|---------|------------|--------|------------|--------|
| **Dell Laptop** | Dell Latitude | i7-3520M (2C/4T) | 15GB | 500GB HDD | `10.0.0.4` | `https://10.0.0.4:8006` | `ssh root@10.0.0.4` | `deployed` |
| **Gaming PC** | Custom | i7-10700K (8C/16T) | 32GB | 1TB + 500GB SSD | `TBD` | `TBD` | `TBD` | `not yet repurposed` |

---

## Infrastructure Services

### Templates & Base Images

| Name | Flake Config | Type | Purpose | Build Command | Status |
|------|--------------|------|---------|---------------|--------|
| **Base VMA** | `initialProxmoxVMA` | VMA Template | Base image for new VMs | `nixos-rebuild build-image --image-variant proxmox --flake .#initialProxmoxVMA` | `ready` |
| **Generic VM** | `proxmoxVM` | VM Template | Standard Proxmox VM config | `nixos-rebuild dry-build --flake .#proxmoxVM` | `ready` |
| **LXC Base** | `lxc-base` | LXC Template | Container base configuration | `nixos-rebuild dry-build --flake .#lxc-monitor` | `ready` |

### Foundation Services (Dell Node)

| Service | Hostname | VM/CT ID | IP Address | Cores | RAM | Disk | Ports | Status | Access |
|---------|----------|----------|------------|-------|-----|------|-------|---------|--------|
| **Desktop** | gaia | — | `[Laptop IP]` | 8 | 16GB | 500GB | — | `deployed` | Direct access |
| **Agent Sandbox** | agent-sandbox | 105 | `10.0.0.163` | 4 | 8GB | 24GB | 22 | `deployed` | `ssh agent@10.0.0.163` |
| **NixOS Builder** | nixos-builder | 200 | `[TBD]` | 6 | 12GB | 100GB | 22 | `deployed` | `ssh sandmhan@[BUILDER_IP]` |
| **Matrix Server** | matrix | 102 | `10.0.0.6` | 2 | 4GB | 40GB | 80,443,8448,9800 | `deployed` | `https://matrix.sandmhan.dev` |
| **Matrix Agent Bridge** | matrix (co-located) | 102 | `10.0.0.6` | — | — | — | 9800 | `configured` | Webhook: `http://10.0.0.6:9800/health` |

**Deployment Commands**:
```bash
# Agent Sandbox (deployed)
nixos-rebuild switch --target-host agent@10.0.0.163 --flake .#agent-sandbox --sudo

# NixOS Builder (deployed) 
nixos-rebuild switch --target-host sandmhan@[BUILDER_IP] --flake .#nixos-builder --sudo

# Matrix Server (deployed)
nixos-rebuild switch --target-host sandmhan@10.0.0.6 --flake .#matrix --sudo
```

---

## Planned VM Services (Gaming PC Node)

| Service | Hostname | VM ID | IP (Planned) | Cores | RAM | Disk | GPU | Ports | Deployment |
|---------|----------|-------|--------------|-------|-----|------|-----|-------|------------|
| **Monitoring** | monitor | 107 | `10.0.20.107` | 2 | 4GB | 50GB | — | 3000,9090,9100 | `qmrestore [VMA] 107; qm set 107 --cores 2 --memory 4096; nixos-rebuild switch --target-host sandmhan@10.0.20.107 --flake .#monitor` |
| **Git Server** | git | 109 | `10.0.20.109` | 2 | 2GB | 30GB | — | 80,443,3022,9187 | `qmrestore [VMA] 109; qm set 109 --cores 2 --memory 2048; nixos-rebuild switch --target-host sandmhan@10.0.20.109 --flake .#git` |
| **WireGuard VPN** | vpn | 106 | `10.0.20.106` | 1 | 1GB | 20GB | — | 51820 | `qmrestore [VMA] 106; qm set 106 --cores 1 --memory 1024; nixos-rebuild switch --target-host sandmhan@10.0.20.106 --flake .#vpn` |
| **AI Server** | llama | 108 | `10.0.20.108` | 6 | 14GB | 100GB | RTX 3060 | 8080 | `qmrestore [VMA] 108; qm set 108 --cores 6 --memory 14336 --hostpci0 [GPU_ID]; nixos-rebuild switch --target-host sandmhan@10.0.20.108 --flake .#llama` |
| **NVR** | nvr | 105 | `10.0.20.105` | 4 | 8GB | 200GB | — | 5000 | `qmrestore [VMA] 105; qm set 105 --cores 4 --memory 8192; nixos-rebuild switch --target-host sandmhan@10.0.20.105 --flake .#nvr` |
| **Home Assistant** | homeassistant | 103 | `10.0.20.103` | 2 | 4GB | 50GB | — | 80,8123,1883,1884,9100 | `qmrestore [VMA] 103; qm set 103 --cores 2 --memory 4096; nixos-rebuild switch --target-host sandmhan@10.0.20.103 --flake .#homeassistant` |

---

## LXC Container Services (Dell Node - Resource Efficient)

| Service | Hostname | CT ID | IP (Planned) | Cores | RAM | Disk | Ports | Status | Deployment |
|---------|----------|-------|--------------|-------|-----|------|-------|--------|------------|
| **Monitoring** | lxc-monitor | 207 | `10.0.0.164` (DHCP) | 1 | 1GB | 10GB | 3000,9090,9100 | `deployed` | `nixos-rebuild switch --target-host monitor@10.0.0.164 --flake .#lxc-monitor --sudo` |
| **Matrix Chat** | lxc-matrix | 204 | `10.0.20.204` | 1 | 2GB | 30GB | 80,443,8448 | `planned` | `[Create LXC]; nixos-rebuild switch --target-host matrix@10.0.20.204 --flake .#lxc-matrix` |
| **Git Server** | lxc-git | 206 | `10.0.20.206` | 1 | 1GB | 20GB | 80,443,3022 | `planned` | `[Create LXC]; nixos-rebuild switch --target-host git@10.0.20.206 --flake .#lxc-git` |
| **NAS** | lxc-nas | 201 | `10.0.20.201` | 1 | 2GB | 100GB | 2049,445 | `planned` | `[Create LXC]; nixos-rebuild switch --target-host nas@10.0.20.201 --flake .#lxc-nas` |
| **Home Assistant** | lxc-homeassistant | 203 | `10.0.20.203` | 1 | 2GB | 20GB | 80,8123,1883,1884,9100 | `planned` | `[Create LXC]; nixos-rebuild switch --target-host hass@10.0.20.203 --flake .#lxc-homeassistant` |

---

## Service Access & Web Interfaces

| Service | Internal URL | External URL (via VPN) | Default Credentials | Documentation |
|---------|-------------|-------------------------|-------------------|---------------|
| **Proxmox** | `https://10.0.0.126:8006` | `https://10.0.0.126:8006` | `root` / `[proxmox_password]` | Proxmox docs |
| **Matrix** | `http://10.0.0.6:80` | `https://matrix.sandmhan.dev` | Registration required | [Matrix Setup](../SOPS-SETUP.md) |
| **Grafana** | `http://10.0.20.107:3000` | `http://grafana.homelab.local:3000` | `admin` / `[sops_encrypted]` | [Monitoring Setup](./monitoring-setup.md) |
| **Prometheus** | `http://10.0.20.107:9090` | `http://prometheus.homelab.local:9090` | No auth | [Monitoring Setup](./monitoring-setup.md) |
| **Frigate NVR** | `http://10.0.20.105:5000` | `http://nvr.homelab.local:5000` | No auth (local only) | [Frigate Setup](./frigate-nvr-setup.md) |
| **AI Server** | `http://10.0.20.108:8080` | `http://ai.homelab.local:8080` | No auth (API only) | [AI Setup](./llama-ai-server-setup.md) |
| **Forgejo Git (VM)** | `http://10.0.20.109:3000` | `https://git.homelab.local` | `admin` / `[sops_encrypted]` | [Git Setup](./forgejo-setup.md) |
| **Forgejo Git (LXC)** | `http://10.0.20.206:3000` | `https://git.homelab.local` | `admin` / `[sops_encrypted]` | [Git Setup](./forgejo-setup.md) |
| **Matrix Agent Bridge** | `http://10.0.0.6:9800/health` | N/A (internal only) | Bearer token (webhook) | [Agent Bridge Setup](./matrix-agent-bridge-setup.md) |
| **Home Assistant** | `http://10.0.20.103:8123` | `http://homeassistant.homelab.local` | Onboarding required | [HA Setup](./homeassistant-setup.md) |
| **MQTT Broker** | `mqtt://10.0.20.103:1883` | N/A (internal only) | Anonymous (homelab) | [HA Setup](./homeassistant-setup.md) |

---

## Network Configuration

### VLAN Structure

| VLAN ID | Subnet | Purpose | Firewall Rules | DNS |
|---------|--------|---------|----------------|-----|
| **1** | `10.0.0.0/24` | Management VLAN | Full access to all VLANs | `*.homelab.local` |
| **10** | `10.0.10.0/24` | IoT VLAN | Restricted: NVR access only, no internet except NTP | Camera hostnames |
| **20** | `10.0.20.0/24` | Services VLAN | Inter-service communication, internet access | Service hostnames |
| **30** | `10.0.30.0/24` | Guest VLAN | Internet only, no homelab access | No internal DNS |

### Port Mappings

| Service | Internal Port | External Port | Protocol | Purpose |
|---------|---------------|---------------|----------|---------|
| **SSH** | 22 | 22 | TCP | Remote management |
| **HTTP** | 80 | 80 | TCP | Web services |
| **HTTPS** | 443 | 443 | TCP | Secure web services |
| **Matrix Federation** | 8448 | 8448 | TCP | Matrix server federation |
| **WireGuard** | 51820 | 51820 | UDP | VPN access |
| **Grafana** | 3000 | — | TCP | Monitoring dashboard (VPN only) |
| **Prometheus** | 9090 | — | TCP | Metrics API (VPN only) |
| **Node Exporter** | 9100 | — | TCP | System metrics (internal only) |
| **Frigate** | 5000 | — | TCP | NVR interface (VPN only) |
| **AI Server** | 8080 | — | TCP | AI API (VPN only) |
| **Forgejo Web** | 3000 | — | TCP | Git web interface (VPN only) |
| **Forgejo SSH** | 3022 | — | TCP | Git SSH operations (VPN only) |
| **PG Exporter** | 9187 | — | TCP | PostgreSQL metrics (internal only) |
| **Matrix Bot Webhook** | 9800 | — | TCP | Agent bridge webhook receiver (internal only) |
| **Home Assistant** | 8123 | — | TCP | Smart home dashboard (VPN only) |
| **MQTT** | 1883 | — | TCP | IoT device message broker (internal only) |
| **MQTT WebSocket** | 1884 | — | TCP | MQTT browser clients (internal only) |

---

## Secret Management

### SOPS Configuration

| Service | Secret File | Keys Required | Contains |
|---------|-------------|---------------|----------|
| **Matrix** | `secrets/matrix/secrets.yaml` | admin, matrix_key | Registration secret, postgres password, bot-access-token, webhook-secret |
| **Monitoring** | `secrets/monitoring/secrets.yaml` | admin, monitor_key | Grafana admin password, SMTP credentials |
| **Forgejo** | `secrets/forgejo/secrets.yaml` | admin, git_key | Admin password, Forgejo secret key |
| **Home Assistant** | `secrets/homeassistant/secrets.yaml` | admin, homeassistant_key | HA secrets, MQTT password, PostgreSQL password |
| **WireGuard** | `secrets/wireguard/secrets.yaml` | admin, vpn_key | Server private key, client configurations |
| **Shared** | `secrets/shared/secrets.yaml` | admin, all_host_keys | Cross-service credentials, certificates |
| **Personal** | `secrets/user/personal.yaml` | admin, gaia_key | Git config, API keys, personal tokens |

### Secret Population Commands

```bash
# Matrix secrets
MATRIX_REG_SECRET=$(openssl rand -base64 32)
POSTGRES_PASSWORD=$(openssl rand -base64 24)
sops --set 'secrets/matrix/secrets.yaml' '["registration_shared_secret"]' "$MATRIX_REG_SECRET"
sops --set 'secrets/matrix/secrets.yaml' '["postgres_password"]' "$POSTGRES_PASSWORD"

# Monitoring secrets  
GRAFANA_PASSWORD=$(openssl rand -base64 24)
sops --set 'secrets/monitoring/secrets.yaml' '["grafana-admin-password"]' "$GRAFANA_PASSWORD"

# WireGuard secrets
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo $SERVER_PRIVATE_KEY | wg pubkey)
sops --set 'secrets/wireguard/secrets.yaml' '["server-private-key"]' "$SERVER_PRIVATE_KEY"

# Verify secrets
for file in secrets/*/secrets.yaml; do
  echo "Testing $file..."
  sops -d "$file" >/dev/null && echo "✓ OK" || echo "✗ FAILED"
done
```

---

## Deployment Procedures

### New VM Deployment

1. **Create VM from VMA**:
   ```bash
   # Deploy base VMA image
   qmrestore /var/lib/vz/dump/vzdump-qemu-nixos-*.vma.zst [VM_ID] --storage local-zfs
   
   # Configure resources
   qm set [VM_ID] --cores [CORES] --memory [MEMORY_MB] --name [HOSTNAME]
   qm set [VM_ID] --net0 virtio,bridge=vmbr0,firewall=1
   
   # Add additional storage if needed
   qm set [VM_ID] --scsi1 local-zfs:vm-[VM_ID]-disk-1,size=[SIZE]G
   
   # Start VM
   qm start [VM_ID]
   ```

2. **Deploy Configuration**:
   ```bash
   # Wait for VM to boot and get IP
   # Deploy service configuration
   nixos-rebuild switch --target-host [USER]@[VM_IP] --flake .#[CONFIG] --sudo
   ```

3. **Verify Deployment**:
   ```bash
   # Test SSH access
   ssh [USER]@[VM_IP]
   
   # Check service status
   ssh [USER]@[VM_IP] "sudo systemctl status [SERVICE]"
   
   # Test service endpoints
   curl http://[VM_IP]:[PORT]/health
   ```

### LXC Container Deployment

1. **Create LXC Container** (method varies by setup):
   ```bash
   # Note: LXC deployment requires additional setup - see LXC documentation
   # This is a placeholder for the actual LXC creation process
   ```

2. **Deploy Configuration**:
   ```bash
   nixos-rebuild switch --target-host [USER]@[CONTAINER_IP] --flake .#[LXC_CONFIG] --sudo
   ```

---

## Monitoring & Health Checks

### Service Health Endpoints

| Service | Health Check URL | Expected Response |
|---------|------------------|------------------|
| **Prometheus** | `http://[HOST]:9090/-/ready` | `200 OK` |
| **Grafana** | `http://[HOST]:3000/api/health` | `{"database": "ok", "version": "..."}` |
| **Matrix** | `http://[HOST]:8008/_matrix/client/versions` | `{"versions": [...]}` |
| **Frigate** | `http://[HOST]:5000/api/config` | JSON config response |
| **AI Server** | `http://[HOST]:8080/v1/models` | JSON models list |
| **Forgejo** | `http://[HOST]:3000/api/v1/version` | JSON version response |
| **Node Exporter** | `http://[HOST]:9100/metrics` | Prometheus metrics format |
| **Matrix Bot** | `http://10.0.0.6:9800/health` | `{"status": "ok", "uptime_seconds": ...}` |
| **Home Assistant** | `http://[HOST]:8123/api/` | `{"message": "API running."}` |
| **MQTT Broker** | `mosquitto_sub -h [HOST] -t '$SYS/broker/version' -C 1 -W 5` | Mosquitto version string |

### Automated Health Check Script

```bash
#!/bin/bash
# health-check.sh - Check all homelab services

check_service() {
    local name="$1"
    local url="$2"
    local expected_code="${3:-200}"
    
    echo -n "Checking $name... "
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "^$expected_code$"; then
        echo "✓"
    else
        echo "✗ FAILED"
    fi
}

# Check deployed services
check_service "Agent Sandbox SSH" "tcp://10.0.0.163:22"
check_service "Matrix Server" "http://10.0.0.6:8008/_matrix/client/versions"

# Add checks for other services as they're deployed
# check_service "Grafana" "http://10.0.20.107:3000/api/health"
# check_service "Prometheus" "http://10.0.20.107:9090/-/ready"
```

---

## Troubleshooting Reference

### Common Issues

| Issue | Symptoms | Solution |
|-------|----------|----------|
| **VM Won't Boot** | Stuck at boot, no network | Check VMA integrity, verify VM settings, ensure MAC address is not 00:00:00:00:00:00 |
| **SSH Access Denied** | Connection refused/timeout | Verify firewall rules, check SSH service status, confirm user exists |
| **Service Not Starting** | systemctl shows failed | Check logs: `journalctl -u [service] -f`, verify secrets are accessible |
| **Secret Decryption Failed** | sops error, file not found | Verify age key exists at `/var/lib/sops-nix/key.txt`, check `.sops.yaml` configuration |
| **Network Connectivity** | Can't reach service | Check firewall rules, verify VLAN configuration, test with `curl` |

### Debug Commands

```bash
# Check VM status
qm status [VM_ID]
qm config [VM_ID]

# SSH and systemd debugging  
ssh [HOST] "sudo systemctl status [SERVICE]"
ssh [HOST] "sudo journalctl -u [SERVICE] --since '5 minutes ago'"

# Network debugging
ssh [HOST] "sudo iptables -L -n"
ssh [HOST] "ss -tlnp"
nmap -p [PORT] [HOST_IP]

# SOPS debugging
sops -d secrets/[service]/secrets.yaml
ssh [HOST] "sudo ls -la /run/secrets/"
```

---

## Update Log

| Date | Change | Commit | Notes |
|------|--------|--------|-------|
| 2026-04-24 | Add Home Assistant systemModule with MQTT, PostgreSQL, nginx, USB passthrough | — | VM and LXC host configs, secrets, documentation |
| 2026-04-24 | Add Matrix Agent Bridge for bot control and webhook notifications | — | New systemModule, bot script, co-located on matrix host (port 9800) |
| 2026-04-24 | Add Forgejo Git server (VM and LXC) to infrastructure registry | — | New systemModule, VM/LXC host configs, secrets, and documentation |
| 2026-04-24 | Complete infrastructure registry overhaul with deployment commands, access methods, and troubleshooting | — | Added comprehensive host information, build commands, and operational procedures |
| 2026-04-23 | Initial registry created from flake.nix inventory | — | Basic structure |
| 2026-04-23 | Updated agent-sandbox IP to 10.0.0.163, deployed latest config | — | IP assignment |
| 2026-04-23 | Marked nixos-builder as deployed, updated roadmap for incremental config development approach | — | Status update |

---

**Note**: Replace placeholder values (TBD, [BRACKETS]) with actual values as infrastructure is deployed. Keep this registry updated with every infrastructure change.
