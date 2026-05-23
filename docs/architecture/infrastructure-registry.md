# Infrastructure Registry

Single source of truth for all deployed and planned infrastructure. **Update this file in the same commit as any host change.**

## Quick Reference

> **IMPORTANT**: All systemModules follow new standardized architecture patterns as of April 2026. See [SystemModules Architecture Guide](./systemmodules-architecture.md) for implementation details and [SystemModules Overview](./systemmodules-overview.md) for service documentation.

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
- **VPN Access**: Connect via the deployed Tailscale router for remote access to homelab services; WireGuard remains retained/planned for service-specific use.

---

## Proxmox Nodes

| Node | Hardware | CPU | RAM | Storage | IP Address | Web UI | SSH Access | Status | Notes |
|------|----------|-----|-----|---------|------------|--------|------------|--------|-------|
| **Dell Laptop** | Dell Latitude | i7-3520M (2C/4T) | 15GB | 500GB HDD | `10.0.0.4` | `https://10.0.0.4:8006` | `ssh root@10.0.0.4` | `deployed` | Intel I217 NIC (`e1000e`) — hangs under sustained load. Max 8GB RAM across all VMs |
| **Gaming PC** | Custom | i7-10700K (8C/16T) | 32GB | 1TB + 500GB SSD | `TBD` | `TBD` | `TBD` | `not yet repurposed` | — |

---

## Infrastructure Services

### Templates & Base Images

| Name | Flake Config | Type | Purpose | Build Command | Status |
|------|--------------|------|---------|---------------|--------|
| **Base VMA** | `initialProxmoxVMA` | VMA Template | Base image for new VMs | `nixos-rebuild build-image --image-variant proxmox --flake .#initialProxmoxVMA` | `ready` |
| **Generic VM** | `proxmoxVM` | VM Template | Standard Proxmox VM config | `nixos-rebuild dry-build --flake .#proxmoxVM` | `ready` |
| **LXC Base** | `initialLXC` | LXC Template | Container base tarball | `nix build .#nixosConfigurations.initialLXC.config.system.build.tarball` | `ready` |

### Foundation Services (Dell Node)

| Service | Hostname | VM/CT ID | IP Address | Cores | RAM | Disk | Ports | Status | Access |
|---------|----------|----------|------------|-------|-----|------|-------|---------|--------|
| **Desktop** | gaia | — | `[Laptop IP]` | 8 | 16GB | 500GB | — | `deployed` | Direct access |
| **Agent Sandbox** | agent-sandbox | 105 | `10.0.0.5` | 4 | 8GB | 24GB | 22 | `deployed` | `ssh agent@10.0.0.5` |
| **NixOS Builder** | nixos-builder | 200 | `10.0.0.7` | 6 | 12GB | 100GB | 22, 9100 | `deployed` | `ssh sandmhan@10.0.0.7` |
| **Matrix Server** | matrix | 102 | `10.0.0.6` | 2 | 4GB | 40GB | 80,443,8448,9800 | `deployed` | `https://matrix.sandmhan.dev` |
| **Matrix Agent Bridge** | matrix (co-located) | 102 | `10.0.0.6` | — | — | — | 9800 | `configured` | Webhook: `http://10.0.0.6:9800/health` |
| **Fitness (wger)** | fitness | 106 | `10.0.0.167` | 2 | 2GB | 15GB | 80,8000,9100,9101 | `deployed` | `http://10.0.0.167/` — Login: `admin` / `adminadmin` |
| **Tailscale Router** | vpn | 110 | `10.0.0.168` | 1 | 1GB | 20GB | 41641 | `deployed` | `ssh sandmhan@100.120.234.19` (Tailscale only — LAN unreachable, see known issues) |

**Deployment Commands**:
```bash
# Agent Sandbox (deployed)
nixos-rebuild switch --target-host agent@10.0.0.5 --flake .#agent-sandbox --sudo

# NixOS Builder (deployed) 
nixos-rebuild switch --target-host sandmhan@10.0.0.7 --flake .#nixos-builder --sudo

# Matrix Server (deployed)
nixos-rebuild switch --target-host sandmhan@10.0.0.6 --flake .#matrix --sudo

# Fitness / wger (deployed — no DHCP reservation, DHCP-assigned IP)
nixos-rebuild switch --target-host sandmhan@10.0.0.167 --flake .#fitness --sudo
```

---

## Planned VM Services (Gaming PC Node)

> **NETWORK NOTE**: All services below will be deployed on the current flat `10.0.0.0/24` network. IPs will be assigned via DHCP reservation once each VM is created. VLAN segmentation (`10.0.20.0/24` services VLAN, etc.) is planned for a future phase once the managed switch is integrated with pfSense — see [Future: VLAN Segmentation](#future-vlan-segmentation) below.

| Service | Hostname | VM ID | IP (Planned) | Cores | RAM | Disk | GPU | Ports | Deployment |
|---------|----------|-------|--------------|-------|-----|------|-----|-------|------------|
| **Monitoring** | monitor | 107 | `10.0.0.TBD` | 2 | 4GB | 50GB | — | 3000,9090,9100 | `qmrestore [VMA] 107; qm set 107 --cores 2 --memory 4096; nixos-rebuild switch --target-host sandmhan@[IP] --flake .#monitor` |
| **Git Server** | git | 109 | `10.0.0.TBD` | 2 | 2GB | 30GB | — | 80,443,3022,9187 | `qmrestore [VMA] 109; qm set 109 --cores 2 --memory 2048; nixos-rebuild switch --target-host sandmhan@[IP] --flake .#git` |
| **AI Server** | llama | 108 | `10.0.0.TBD` | 6 | 14GB | 100GB | RTX 3060 | 8080 | `qmrestore [VMA] 108; qm set 108 --cores 6 --memory 14336 --hostpci0 [GPU_ID]; nixos-rebuild switch --target-host sandmhan@[IP] --flake .#llama` |
| **NVR** | nvr | TBD — avoid 105 | `10.0.0.TBD` | 4 | 8GB | 200GB | — | 5000 | `qmrestore [VMA] [ID]; qm set [ID] --cores 4 --memory 8192; nixos-rebuild switch --target-host sandmhan@[IP] --flake .#nvr` |
| **Home Assistant** | homeassistant | 103 | `10.0.0.TBD` | 2 | 4GB | 50GB | — | 80,8123,1883,1884,9100 | `qmrestore [VMA] 103; qm set 103 --cores 2 --memory 4096; nixos-rebuild switch --target-host sandmhan@[IP] --flake .#homeassistant` |
| **Fitness (wger)** | fitness | 106 | `10.0.0.167` | 2 | 2GB | 15GB | — | 80,8000,9100,9101 | `deployed` — see Foundation Services |
| **Media (*arr)** | media | TBD | `10.0.0.TBD` | 4 | 8GB | 80GB | 1080 Ti | 8096,8989,7878,9696,8080 | `qmrestore [VMA] [ID]; nixos-rebuild switch --target-host sandmhan@[IP] --flake .#media` |
| **Gaming (Sunshine)** | gaming | TBD | `10.0.0.TBD` | 6 | 12GB | 200GB | RTX 3060 / 1080 Ti | 47984-47990,47998-48010 | `qmrestore [VMA] [ID]; nixos-rebuild switch --target-host sandmhan@[IP] --flake .#gaming` |
| **Manga (Komga + Suwayomi)** | module-only/planned | TBD | `10.0.0.TBD` | 2 | 4GB | 40GB | — | 80,25600,4567,9100 | `systemModules/manga/default.nix` exists; no host or flake output yet |

> **NOTE**: Rows marked `deployed` are already live. Planned VM services with host/flake outputs are configuration-ready but still require SOPS secrets setup, DHCP reservations on the `10.0.0.0/24` network, and VM/LXC creation before deployment. Manga is module-only today (`systemModules/manga/default.nix`) and still needs a host and flake output before it can be deployed. See individual setup docs for prerequisites.

---

## LXC Container Services (Dell Node - Resource Efficient)

| Service | Hostname | CT ID | IP (Planned) | Cores | RAM | Disk | Ports | Status | Deployment |
|---------|----------|-------|--------------|-------|-----|------|-------|--------|------------|
| **Monitoring** | lxc-monitor | 207 | `10.0.0.10` | 1 | 1GB | 10GB | 3000,9090,9100 | `deployed` | `nixos-rebuild switch --target-host monitor@10.0.0.10 --flake .#lxc-monitor --sudo` |
| **Matrix Chat** | lxc-matrix | 204 | `10.0.0.TBD` | 1 | 2GB | 30GB | 80,443,8448 | `planned` | `[Create LXC]; nixos-rebuild switch --target-host matrix@[IP] --flake .#lxc-matrix` |
| **Git Server** | lxc-git | 206 | `10.0.0.TBD` | 1 | 1GB | 20GB | 80,443,3022 | `planned` | `[Create LXC]; nixos-rebuild switch --target-host git@[IP] --flake .#lxc-git` |
| **NAS** | lxc-nas | 201 | `10.0.0.TBD` | 1 | 2GB | 100GB | 2049,445 | `planned` | `[Create LXC]; nixos-rebuild switch --target-host nas@[IP] --flake .#lxc-nas` |
| **Home Assistant** | lxc-homeassistant | 203 | `10.0.0.TBD` | 1 | 2GB | 20GB | 80,8123,1883,1884,9100 | `planned` | `[Create LXC]; nixos-rebuild switch --target-host hass@[IP] --flake .#lxc-homeassistant` |

---

## Service Access & Web Interfaces

| Service | Internal URL | External URL (via VPN) | Default Credentials | Documentation |
|---------|-------------|-------------------------|-------------------|---------------|
| **Proxmox** | `https://10.0.0.4:8006` | `https://10.0.0.4:8006` | `root` / `[proxmox_password]` | Proxmox docs |
| **Matrix** | `http://10.0.0.6:80` | `https://matrix.sandmhan.dev` | Registration required | [Matrix Setup](../operations/secrets/sops-secrets-setup.md) |
| **Grafana** | `http://10.0.0.10:3000` | `http://grafana.homelab.local:3000` | `admin` / `[sops_encrypted]` | [Monitoring Setup](../operations/services/monitoring-setup.md) |
| **Prometheus** | `http://10.0.0.10:9090` | `http://prometheus.homelab.local:9090` | No auth | [Monitoring Setup](../operations/services/monitoring-setup.md) |
| **wger Exporter** | `http://10.0.0.167:9101/metrics` | N/A (internal only) | No auth | [Fitness Setup](../operations/services/fitness-setup.md) |
| **Frigate NVR** | `http://[NVR_IP]:5000` | `http://nvr.homelab.local:5000` | No auth (local only) | [Frigate Setup](../operations/services/frigate-nvr-setup.md) |
| **AI Server** | `http://[LLAMA_IP]:8080` | `http://ai.homelab.local:8080` | No auth (API only) | [AI Setup](../operations/services/llama-ai-server-setup.md) |
| **Forgejo Git (VM)** | `http://[GIT_IP]:3000` | `https://git.homelab.local` | `admin` / `[sops_encrypted]` | [Git Setup](../operations/services/forgejo-setup.md) |
| **Forgejo Git (LXC)** | `http://[LXC_GIT_IP]:3000` | `https://git.homelab.local` | `admin` / `[sops_encrypted]` | [Git Setup](../operations/services/forgejo-setup.md) |
| **Matrix Agent Bridge** | `http://10.0.0.6:9800/health` | N/A (internal only) | Bearer token (webhook) | [Agent Bridge Setup](../operations/services/matrix-agent-bridge-setup.md) |
| **Home Assistant** | `http://[HA_IP]:8123` | `http://homeassistant.homelab.local` | Onboarding required | [HA Setup](../operations/services/homeassistant-setup.md) |
| **wger Fitness** | `http://10.0.0.167/` | `http://fitness.homelab.local` | `admin` / `adminadmin` | [Fitness Setup](../operations/services/fitness-setup.md) |
| **wger Exporter** | `http://10.0.0.167:9101/metrics` | N/A | No auth | [Fitness Setup](../operations/services/fitness-setup.md) |
| **MQTT Broker** | `mqtt://[HA_IP]:1883` | N/A (internal only) | Anonymous (homelab) | [HA Setup](../operations/services/homeassistant-setup.md) |
| **Komga (Manga)** | `http://[MANGA_IP]:25600` | `http://komga.homelab.local` | First-run setup | [Manga Setup](../operations/services/manga-setup.md) |
| **Suwayomi (Manga)** | `http://[MANGA_IP]:4567` | `http://suwayomi.homelab.local` | No auth (local only) | [Manga Setup](../operations/services/manga-setup.md) |

---

## Network Configuration

### Current Network

All homelab infrastructure currently runs on a **flat `10.0.0.0/24` network**. VMs and containers receive IPs via DHCP from the pfSense router, with static reservations for deployed services.

| Subnet | Purpose | Status |
|--------|---------|--------|
| `10.0.0.0/24` | All homelab services, management, and VMs | **Active** |

### Future: VLAN Segmentation

VLAN segmentation is planned once the managed switch is properly integrated with pfSense and additional Proxmox nodes are online. **None of these VLANs exist yet.**

| VLAN ID | Subnet | Purpose | Firewall Rules | DNS |
|---------|--------|---------|----------------|-----|
| **1** | `10.0.0.0/24` | Management | Full access to all VLANs | `*.homelab.local` |
| **10** | `10.0.10.0/24` | IoT | Restricted: NVR access only, no internet except NTP | Camera hostnames |
| **20** | `10.0.20.0/24` | Services | Inter-service communication, internet access | Service hostnames |
| **30** | `10.0.30.0/24` | Guest | Internet only, no homelab access | No internal DNS |

**Prerequisites for VLAN deployment:**
- [ ] Managed switch configured with 802.1Q VLAN trunking
- [ ] pfSense VLAN interfaces and DHCP scopes created
- [ ] Inter-VLAN firewall rules configured
- [ ] All existing service IPs migrated from `10.0.0.x` to appropriate VLAN subnets
- [ ] NixOS host configs, systemModules, and monitoring targets updated with new IPs

### Port Mappings

| Service | Internal Port | External Port | Protocol | Purpose |
|---------|---------------|---------------|----------|---------|
| **SSH** | 22 | 22 | TCP | Remote management |
| **HTTP** | 80 | 80 | TCP | Web services |
| **HTTPS** | 443 | 443 | TCP | Secure web services |
| **Matrix Federation** | 8448 | 8448 | TCP | Matrix server federation |
| **WireGuard** | 51820 | 51820 | UDP | Planned/optional WireGuard access; current remote access uses Tailscale |
| **Grafana** | 3000 | — | TCP | Monitoring dashboard (VPN only) |
| **Prometheus** | 9090 | — | TCP | Metrics API (VPN only) |
| **Node Exporter** | 9100 | — | TCP | System metrics (internal only) |
| **wger Exporter** | 9101 | — | TCP | Fitness business metrics (internal only) |
| **Frigate** | 5000 | — | TCP | NVR interface (VPN only) |
| **AI Server** | 8080 | — | TCP | AI API (VPN only) |
| **Forgejo Web** | 3000 | — | TCP | Git web interface (VPN only) |
| **Forgejo SSH** | 3022 | — | TCP | Git SSH operations (VPN only) |
| **PG Exporter** | 9187 | — | TCP | PostgreSQL metrics (internal only) |
| **Matrix Bot Webhook** | 9800 | — | TCP | Agent bridge webhook receiver (internal only) |
| **Home Assistant** | 8123 | — | TCP | Smart home dashboard (VPN only) |
| **MQTT** | 1883 | — | TCP | IoT device message broker (internal only) |
| **MQTT WebSocket** | 1884 | — | TCP | MQTT browser clients (internal only) |
| **Komga** | 25600 | — | TCP | Manga library server + OPDS (VPN only) |
| **Suwayomi** | 4567 | — | TCP | Manga source aggregator (VPN only) |

---

## Secret Management

### SOPS Configuration

| Service | Secret File | Keys Required | Contains |
|---------|-------------|---------------|----------|
| **Matrix** | `secrets/matrix/secrets.yaml` | admin, matrix_key | Registration secret, postgres password, bot-access-token, webhook-secret |
| **Monitoring** | `secrets/monitoring/secrets.yaml` | admin, monitor_key | Grafana admin password, SMTP credentials |
| **Tailscale** | `secrets/tailscale/secrets.yaml` | admin, gaia_key, vpn_key | Auth keys for automatic node enrollment |
| **WireGuard** | `secrets/wireguard/secrets.yaml` | admin, vpn_key | Retained/planned WireGuard keys; not the deployed remote-access path |
| **Fitness (wger)** | `secrets/fitness/secrets.yaml` | admin, fitness_key | Django secret key, PostgreSQL password, wger API token (for exporter) |
| **Shared** | `secrets/shared/secrets.yaml` | admin, gaia/nvr/matrix keys | Cross-service credentials, certificates |
| **Personal** | `secrets/user/personal.yaml` | admin, gaia_key | Git config, API keys, personal tokens |
| **Forgejo** | `secrets/forgejo/secrets.yaml` | TBD git/lxc-git host keys | Routed by `systemModules/sops.nix`; add `.sops.yaml` creation rule before deployment |
| **Home Assistant** | `secrets/homeassistant/secrets.yaml` | TBD homeassistant/lxc-homeassistant host keys | Routed by `systemModules/sops.nix`; add `.sops.yaml` creation rule before deployment |
| **Media** | `secrets/media/secrets.yaml` | TBD media host key | Routed by `systemModules/sops.nix`; add `.sops.yaml` creation rule before deployment |
| **Gaming** | `secrets/gaming/secrets.yaml` | TBD gaming host key | Routed by `systemModules/sops.nix`; add `.sops.yaml` creation rule before deployment |
| **Manga** | `secrets/manga/secrets.yaml` (missing until service host is added) | TBD manga host key | Runtime mapping exists in `systemModules/sops.nix`; file and `.sops.yaml` rule still need to be created |

> `systemModules/sops.nix` already routes `git`, `lxc-git`, `homeassistant`, `lxc-homeassistant`, `media`, `gaming`, and `manga` to these service-specific files. Current `.sops.yaml` creation rules do **not** yet cover `forgejo`, `homeassistant`, `media`, `gaming`, or `manga`; add rules and run `sops updatekeys secrets/<service>/secrets.yaml` before relying on those files during deployment.

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
| **wger Fitness** | `http://10.0.0.167/api/v2/` | JSON API root with endpoint listing |
| **wger Exporter** | `http://10.0.0.167:9101/metrics` | Prometheus metrics format |
| **wger Django Metrics** | `http://10.0.0.167:8000/prometheus/metrics` | Django prometheus metrics |
| **Komga** | `http://[MANGA_IP]:25600/api/v1/libraries` | JSON library list |
| **Suwayomi** | `http://[MANGA_IP]:4567/api/v1/settings/about` | JSON server info |
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
check_service "Agent Sandbox SSH" "tcp://10.0.0.5:22"
check_service "Matrix Server" "http://10.0.0.6:8008/_matrix/client/versions"

check_service "Fitness (wger)" "http://10.0.0.167/api/v2/" 200
check_service "Fitness Node Exporter" "http://10.0.0.167:9100/metrics" 200
check_service "Fitness wger Exporter" "http://10.0.0.167:9101/metrics" 200
check_service "Fitness Django Metrics" "http://10.0.0.167:8000/prometheus/metrics" 200

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
| 2026-05-03 | Add manga stack (Komga + Suwayomi) systemModules with monitoring integration | — | Configuration only — NOT deployed. Requires SOPS setup, DHCP reservation, VM creation, and SSH user verification. Modules: `systemModules/manga/{default,komga,suwayomi,monitoring}.nix`. Placeholder scrape targets added to `monitoring.nix`. See [Manga Setup](../operations/services/manga-setup.md) for deployment checklist. |
| 2026-05-03 | Enable Matrix Synapse metrics (`enable_metrics = true`) | — | Configuration only — NOT deployed. Requires SSH user verification on matrix VM (may be `sandmhan` or `matrix` depending on pre-refactor state). See `docs/tickets/todo-matrix-metrics.md`. |
| 2026-05-02 | Add wger Prometheus exporter sidecar and Grafana fitness dashboard | — | Custom Python exporter (`wger-exporter`) at `:9101` polls wger REST API for body weight, workouts, nutrition macros, and measurements. Fixed `EXPOSE_PROMETHEUS_METRICS` env var bug for django-prometheus. Added `wger-app` and `wger-fitness` scrape jobs. Provisioned Fitness Overview Grafana dashboard with 11 panels including macro breakdown stacked bars and dual-axis calorie/weight chart. Backfilled 6 historical weight entries into Prometheus TSDB via `promtool tsdb create-blocks-from openmetrics`. |
| 2026-04-25 | Deploy fitness/wger service to VM 106 (10.0.0.167) on Dell node | — | First service deployment with SOPS secrets. Test instance on management VLAN (no DHCP reservation). Containers: wger, PostgreSQL, Redis, Celery. Nginx reverse proxy on port 80. |
| 2026-04-25 | Add media (nixflix), fitness (wger), gaming (Sunshine) systemModules and host configs | — | Configuration only — NOT deployed (except fitness). Requires SOPS setup, DHCP reservations, VM creation |
| 2026-04-25 | Refactor Frigate NVR into option-based systemModule with dynamic camera config | — | Configuration only — NOT deployed. Replaces hardcoded cameras with NixOS options |
| 2026-04-25 | Fix Forgejo, Home Assistant, Matrix Agent Bridge modules (broken package refs, sops interface) | — | Configuration only — NOT deployed. All evaluate cleanly via dry-run |
| 2026-04-24 | **INCIDENT**: Agent VM 105 spammed qm commands against VM 200, triggered e1000e NIC hang on Dell node, required power cycle | — | Added Proxmox safety rules to CLAUDE.md and AGENT.md |
| 2026-04-24 | Add Home Assistant systemModule with MQTT, PostgreSQL, nginx, USB passthrough | — | VM and LXC host configs, secrets, documentation |
| 2026-04-24 | Add Matrix Agent Bridge for bot control and webhook notifications | — | New systemModule, bot script, co-located on matrix host (port 9800) |
| 2026-04-24 | Add Forgejo Git server (VM and LXC) to infrastructure registry | — | New systemModule, VM/LXC host configs, secrets, and documentation |
| 2026-04-24 | Complete infrastructure registry overhaul with deployment commands, access methods, and troubleshooting | — | Added comprehensive host information, build commands, and operational procedures |
| 2026-04-24 | Added Dell node IP (10.0.0.4) and NIC hardware limitations to registry | — | — |
| 2026-04-23 | Initial registry created from flake.nix inventory | — | Basic structure |
| 2026-04-23 | Updated agent-sandbox IP to 10.0.0.5, deployed latest config | — | IP assignment |
| 2026-04-23 | Marked nixos-builder as deployed, updated roadmap for incremental config development approach | — | Status update |

---

**Note**: Replace placeholder values (TBD, [BRACKETS]) with actual values as infrastructure is deployed. Keep this registry updated with every infrastructure change.
