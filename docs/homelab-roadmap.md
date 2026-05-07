# Homelab Service Roadmap

## Hardware

### Current Proxmox Node — Dell Laptop
- CPU: i7-3520M (2C/4T @ 2.90GHz)
- RAM: 15GB
- Storage: 500GB HDD
- **Role**: Run lightweight VMs now (matrix, git, NAS, monitoring). Becomes secondary node later.

### Future Proxmox Node — Gaming PC
- CPU: i7-10700K (8C/16T @ 3.80GHz)
- GPU (onboard): RTX 3060 (12GB VRAM)
- RAM: 32GB
- Storage: 1TB + 500GB SSD
- **Role**: Primary node for GPU-heavy and resource-intensive VMs.
- **Not yet repurposed** — modules should be ready to deploy when it is.

### Spare GPUs (for passthrough when Gaming PC becomes a node)
- **RTX 3060** (12GB) → AI inference (llama.cpp, whisper, SD). Best choice: Ampere fp16/int8 + most VRAM.
- **GTX 1080 Ti** (11GB) → Jellyfin transcoding + Frigate detection (NVDEC/NVENC).
- **Quadro P2000** (5GB) → Backup/secondary transcoding or Frigate-dedicated.
- **VT 5450** (2GB) → Too old to be useful. Skip.

### Networking
- **Switch**: Cisco Catalyst 3750G 48-port PoE managed
- **Router**: Protectli Vault 4-port
- **VLAN plan**: See [Network Architecture](#network-architecture) below.

---

## Current State

| Service | Status | Location | Notes |
|---------|--------|----------|-------|
| Server base template | Done | `hosts/server/` | Reusable for all VMs |
| Agent sandbox VM | **Deployed** | `hosts/agent/` | VM ID 105, 10.0.0.5 |
| NixOS Builder VM | **Deployed** | `hosts/nixos-builder/` | VM ID 200, autonomous builds |
| llama.cpp module | Complete | `systemModules/llama.nix` | Needs real GPU PCI IDs |
| Matrix Synapse | Complete | `systemModules/matrix.nix` | Needs DNS + ACME |
| Frigate | Partial | `systemModules/frigate.nix` | Hardcoded cameras, no AI detector |
| Jellyfin | Stub | `systemModules/jellyfin.nix` | Just `enable = true` |
| sops-nix | Partial | `feat/sops` branch | Initial integration, needs secrets populated |
| Remote access | In development | `systemModules/tailscale.nix` | Pivoted to Tailscale (WireGuard module retained, not deployed) |
| Monitoring | In development | — | systemModules/monitoring.nix (Prometheus + Grafana) |
| NAS/backup | In development | — | systemModules/nas.nix (NFS/Samba) |
| Media stack (*arr) | Not started | — | nixflix integration planned |
| Fitness tracking | Not started | — | wger (OCI container) |
| Git server | In development | — | systemModules/forgejo.nix |
| Remote gaming | HM modules exist | `homeModules/sunshine.nix` | Not a server VM yet |

---

## Container vs VM Deployment Strategy

Given limited hardware resources (especially on the Dell node), we should consider **LXC containers** for lightweight services alongside VMs for isolation-critical workloads.

### LXC vs VM Analysis

**NixOS LXC Support:**
- ✅ **Full NixOS support** in privileged LXC containers
- ✅ **Flake-based deployment** works (same `nixos-rebuild --target-host` workflow)
- ✅ **systemd services** function normally in privileged containers
- ⚠️ **Unprivileged containers** have kernel module/systemd restrictions

**Resource Efficiency Comparison:**

| Aspect | VMs | LXC Containers |
|--------|-----|----------------|
| **CPU Overhead** | ~10-15% hypervisor tax | ~2-5% container overhead |
| **RAM Overhead** | ~512MB per VM minimum | ~50-100MB per container |
| **Storage** | Full filesystem per VM | Shared kernel, smaller footprint |
| **Startup Time** | 30-60 seconds | 2-10 seconds |
| **GPU Sharing** | Complex passthrough setup | Easy shared GPU access |
| **Security Isolation** | Strong (separate kernel) | Weaker (shared kernel) |

### Deployment Recommendations

**Use VMs for:**
- **Autonomous Agent Sandbox** (security isolation critical)
- **Gaming/Remote Desktop** (needs full kernel control)
- **AI Services** (GPU passthrough, potential kernel conflicts)
- **Anything untrusted or experimental**

**Use LXC for:**
- **Matrix Synapse** (lightweight, well-contained service)
- **Monitoring Stack** (Prometheus/Grafana - resource efficient)
- **Git Server** (Forgejo - simple service)
- **Jellyfin** (when not using GPU transcoding)
- **NAS Services** (NFS/Samba - kernel filesystem access)
- **Fitness Tracking** (wger - simple web app)

**Hybrid Approach Benefits:**
- **Dell Node**: Run 4-5 LXC containers vs 2-3 VMs with same resources
- **Gaming PC**: Use VMs for GPU workloads, LXCs for support services
- **GPU Efficiency**: Multiple LXCs can share GPU for light inference tasks

### LXC Scaffolding Requirements

To implement this strategy, we need parallel infrastructure:

```
hosts/
├── lxc-base/              # Base LXC configuration (equivalent to server/)
│   ├── default.nix        # Common LXC settings, networking, SSH
│   ├── networking.nix     # DHCP, systemd-networkd for containers
│   └── monitoring.nix     # Prometheus node exporter
├── lxc-matrix/            # Matrix in LXC
├── lxc-git/               # Forgejo in LXC
├── lxc-monitor/           # Monitoring stack in LXC
└── lxc-nas/               # NAS services in LXC

flake.nix additions:
- lxcConfigurations = { ... }  # Parallel to nixosConfigurations
- LXC build targets for proxmox-lxc module
```

**Implementation Notes:**
- **Privileged containers** required for full NixOS (security tradeoff acceptable for homelab)
- **Shared storage** via bind mounts more efficient than NFS between containers
- **Network isolation** still possible with VLAN tagging in containers
- **Backup/migration** simpler - container templates vs full VM images

### Resource Allocation (Revised)

**Dell Node (with LXC optimization):**

| Service | Type | Cores | RAM | Storage | Notes |
|---------|------|-------|-----|---------|-------|
| monitor | LXC | 0.5 | 1GB | 10GB | Prometheus + Grafana |
| matrix | LXC | 0.5 | 1GB | 20GB | Synapse + PostgreSQL |
| git | LXC | 0.3 | 512MB | 15GB | Forgejo |
| nas | LXC | 0.5 | 1GB | 20GB + mounts | NFS/Samba |
| backup | VM | 1 | 2GB | 30GB | Isolation for backup tasks |

**Total: 2.8 cores, 5.5GB RAM** (vs previous 5 cores, 11GB with VMs)

This frees up **50% more resources** for additional services or the Gaming PC transition.

---

## VM Layout

### Dell Node (current — resource-constrained)

| VM | ID | Cores | RAM | GPU | Disk | Phase |
|----|----|-------|-----|-----|------|-------|
| **monitor** | 100 | 1 | 2GB | — | 20GB | 1 |
| **nas** | 101 | 1 | 2GB | — | 20GB + passthrough disks | 1 |
| **homeassistant** | 103 | 2 | 4GB | — | 40GB + USB dongles | 1 |
| **matrix** | 104 | 1 | 2GB | — | 30GB | 2 |
| **git** | 106 | 1 | 1GB | — | 20GB | 2 |

### Gaming PC Node (future — when repurposed)

| VM | ID | Cores | RAM | GPU | Disk | Phase |
|----|----|-------|-----|-----|------|-------|
| **ai** | 102 | 6 | 14GB | RTX 3060 (passthrough) | 60GB | 3 |
| **media** | 103 | 4 | 8GB | 1080 Ti (transcode) | 80GB + NAS mount | 3 |
| **nvr** | 105 | 2 | 4GB | — (uses ai API for detection) | 30GB + NAS mount | 3 |
| **fitness** | 107 | 1 | 1GB | — | 20GB | 3 |
| **gaming** | 108 | 6 | 12GB | 1080 Ti or 3060 | 200GB | 4 |
| **agent-sandbox** | 105 | 4 | 8GB | — | 24GB | Done |
| **nixos-builder** | 200 | 6 | 12GB | — | 100GB | 1 |

> Note: VMs that need GPU passthrough can only run on the Gaming PC node. Lightweight services run on the Dell now and can be migrated later.

---

## NixOS Builder Infrastructure

### Dedicated Build Server Concept

**Problem**: Current deployment workflow requires laptop to remain powered and connected during long builds. The `nixos-rebuild --target-host` pattern builds configurations locally then transfers artifacts, but this is interrupted if the laptop sleeps or disconnects.

**Solution**: Deploy a dedicated **NixOS Builder VM** that handles configuration building and deployment autonomously.

### Builder VM Specifications

| Component | Specification | Rationale |
|-----------|---------------|-----------|
| **VM ID** | 200 | Dedicated infrastructure ID range |
| **Resources** | 6 cores, 12GB RAM | Optimized for parallel Nix builds |
| **Storage** | 100GB | Large Nix store for caching built derivations |
| **Location** | Gaming PC node (when available) | More powerful hardware for faster builds |
| **Fallback** | Dell node (current) | Can run with reduced performance |

### Builder Capabilities

**Core Functions:**
- **Configuration Building**: Evaluate and build flake configurations for all homelab hosts
- **Artifact Transfer**: Deploy built systems via `nixos-rebuild --target-host`
- **Build Caching**: Maintain shared Nix store cache for faster subsequent builds
- **Scheduled Deployments**: Automated updates and maintenance deployments
- **Remote Triggering**: Accept build requests via API or Git webhooks

**Autonomous Operations:**
- **Uninterrupted Builds**: Continue building even if control laptop powers down
- **Background Processing**: Handle long-running builds (agent configs, full system updates)
- **Retry Logic**: Automatically retry failed deployments with exponential backoff
- **Status Reporting**: Notify completion status via Matrix/email/webhooks

### Builder Configuration

```nix
# hosts/nixos-builder/default.nix
{
  imports = [ ../server/default.nix ];

  # Optimize for building
  nix.settings = {
    max-jobs = "auto";          # Use all available cores
    cores = 6;                  # All VM cores for single builds  
    builders-use-substitutes = true;
    
    # Large build sandbox
    sandbox-paths = [
      "/tmp"
      "/var/tmp" 
    ];
  };

  # Large temporary storage for builds
  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "size=8G" ];     # Large tmpfs for build artifacts
  };

  # Builder services
  services = {
    # Git daemon for receiving configuration updates
    gitDaemon.enable = true;
    
    # SSH server for remote deployment
    openssh.enable = true;
    
    # Optional: Hydra for advanced build orchestration
    # hydra.enable = true;
  };

  # Deployment tools
  environment.systemPackages = with pkgs; [
    nixos-rebuild
    git
    nix
    # Custom deployment scripts
  ];
}
```

### Integration with Current Workflow

**Phase 1 Implementation:**
1. **Deploy Builder VM**: Use proven VMA + target-host pattern  
2. **Configure Nix Store**: Set up binary cache and substituters
3. **Test Deployments**: Validate builder can deploy to existing VMs
4. **Migration**: Transition from laptop-based builds to builder-based

**Enhanced Deployment Pattern:**
```bash
# Instead of local builds:
nixos-rebuild switch --target-host agent@10.0.0.160 --flake .#agent-sandbox

# Builder-orchestrated deployments:
ssh builder@10.0.0.7 "deploy-config agent-sandbox 10.0.0.160"

# Or automated via Git push:
git push builder main  # Triggers automatic deployment pipeline
```

**Benefits Over Current Approach:**
- ✅ **Always Available**: Builder VM never sleeps or disconnects
- ✅ **Dedicated Resources**: Optimized hardware for building (6 cores, 12GB RAM)
- ✅ **Persistent Cache**: Shared Nix store reduces rebuild times
- ✅ **Autonomous Operation**: No dependency on laptop availability
- ✅ **Scalable**: Can build for multiple targets simultaneously
- ✅ **Reliable**: Retry logic and error handling for robust deployments

### Known Issues

**VMA restore creates duplicate MAC addresses.** Every VM restored from `initialProxmoxVMA` gets the same MAC (`52:54:00:12:34:56`), causing DHCP collisions. The current workaround is manually assigning a unique MAC after restore (`qm set <vmid> --net0 virtio=<mac>,bridge=vmbr0`), but this is error-prone and has already caused a collision (VM 110 vs VM 102). Investigate alternatives:
- Set MAC via cloud-init or Proxmox API at restore time
- Use `nixos-anywhere` to push configs directly to fresh VMs without VMA images
- Generate unique MACs in the `qmrestore` + `qm set` workflow automatically
- Build per-host VMA images with unique network config baked in

### Future Enhancements

**Advanced Capabilities:**
- **CI/CD Integration**: GitHub Actions trigger deployments via builder
- **Configuration Validation**: Test builds in isolated environments
- **Rollback Automation**: Automatic rollback on failed health checks
- **Multi-Architecture**: Cross-compilation for different target architectures
- **Build Scheduling**: Off-peak builds to minimize resource contention

This builder infrastructure enables true **autonomous homelab management** where configuration changes can be deployed reliably without manual intervention or laptop dependency.

---

## Network Architecture

### Current: Flat Network

All services currently run on a single flat `10.0.0.0/24` network. VLANs are planned for the future but not yet implemented.

### Future VLANs (Cisco 3750G) — NOT YET IMPLEMENTED

| VLAN | Subnet | Purpose |
|------|--------|---------|
| 1 (default) | 10.0.0.0/24 | Management / trusted devices |
| 10 | 10.0.10.0/24 | IoT devices (cameras, smart home, sensors) |
| 20 | 10.0.20.0/24 | Homelab services (VMs) |
| 30 | 10.0.30.0/24 | Guest network |

### Future Firewall Rules (Protectli / Proxmox firewall)
- **IoT (VLAN 10)**: Can reach NVR (Frigate) and Home Assistant only. No internet except NTP. No access to other VLANs.
- **Services (VLAN 20)**: Inter-VM communication allowed. Internet for updates/APIs. Accessible from management VLAN.
- **Guest (VLAN 30)**: Internet only. No access to any other VLAN.
- **Management (VLAN 1)**: Full access to all VLANs. SSH to Proxmox and VMs.

---

## Secrets Management

### Approach: sops-nix + Bitwarden CLI

The `feat/sops` branch has initial sops-nix integration. Plan:

1. **age key** on each host (generated at deploy time, stored in `/var/lib/sops-nix/key.txt`)
2. **`.sops.yaml`** in repo root maps secrets files to authorized keys
3. **Secrets files** in `secrets/` directory (encrypted in git)
4. **Bitwarden CLI** (`bw`) used to populate initial secret values:
   - `bw get password "matrix-synapse-registration-key"` → piped into sops
   - Script to bootstrap all secrets from Bitwarden vault into sops-encrypted files
5. Secrets referenced in NixOS configs via `sops.secrets.<name>.path`

### Secrets Inventory (per service)
- **Matrix**: registration shared secret, Coturn static auth secret, PostgreSQL password, agent bot access token
- **Nixflix/media**: Sonarr/Radarr/Prowlarr API keys, SABnzbd API key, qBittorrent password, Jellyfin admin password
- **Forgejo**: admin password, PostgreSQL password, secret key
- **wger**: Django secret key, API keys, PostgreSQL password
- **Grafana**: admin password, SMTP credentials (optional)
- **Tailscale**: reusable auth key for automatic node enrollment
- **WireGuard** *(retained, not deployed)*: private keys (if VPN for download clients)

---

## Implementation Phases

> **Note**: Each phase can be implemented with **VMs** (current approach) or **LXC containers** (resource-efficient alternative). LXC requires developing parallel scaffolding (`hosts/lxc-base/`, `lxcConfigurations` in flake.nix) but offers 50% better resource utilization.

### Phase 1 — Foundation & Observability (Dell node, build configs now, selective deployment)

These services have no GPU dependency and establish the foundation for autonomous homelab operations.

**Current Approach**: Due to resource constraints on Dell node, building service configurations incrementally for future deployment rather than deploying all services immediately. NixOS Builder enables autonomous builds without laptop dependency.

#### 1a. NixOS Builder (`hosts/nixos-builder/`, VM ID 200) ✅ **DEPLOYED**

**Priority**: ~~Deploy first to enable autonomous configuration management.~~ **COMPLETED**

**Services:**
- **Configuration Building**: Dedicated VM for building NixOS configurations
- **Deployment Orchestration**: Remote deployment via `nixos-rebuild --target-host`
- **Build Caching**: Persistent Nix store for faster subsequent builds
- **Autonomous Operation**: Uninterrupted builds independent of laptop availability

**Config Requirements:**
```
Resources: 6 cores, 12GB RAM, 100GB storage
Network: SSH access to all homelab targets
Storage: Large tmpfs for build artifacts (/tmp = 8GB)
```

**Implementation:**
1. Deploy using proven VMA + target-host pattern
2. Configure Nix settings for optimal building (max-jobs = auto, cores = 6)
3. Set up Git daemon for configuration repository access
4. Test deployment pipeline with existing agent-sandbox VM
5. Migrate from laptop-based builds to builder-orchestrated deployments

**Benefits:**
- Enables builds to continue during laptop sleep/shutdown
- Dedicated resources for faster compilation
- Foundation for future CI/CD and autonomous updates
- Scales to support multiple target deployments

#### 1b. Monitoring Stack (`hosts/monitor/`, `systemModules/monitoring.nix`)

**Services:**
- **Prometheus** — metric collection, scraping all VM node exporters
- **Grafana** — dashboards and visualization
- **Node exporter** — already on agent VM (port 9100), add to all VMs via server base template
- **Loki** (optional) — log aggregation from all VMs

**Config:**
```
systemModules/monitoring.nix
├── services.prometheus (scrape configs for all VMs)
├── services.grafana (dashboards, datasources)
└── services.loki (optional log aggregation)
```

**Why first**: Every subsequent service benefits from monitoring. Prometheus scrape targets get added as VMs come online.

#### 1c. NAS VM (`hosts/nas/`, `systemModules/nas.nix`)

**Services:**
- **NFS server** — exports for media, recordings, backups (mounted by media/nvr VMs)
- **Samba** — Windows/Mac file access
- **borgbackup** or **restic** — scheduled backups to external drive or cloud
- **smartd** — disk health monitoring (exported to Prometheus)

**Storage layout:**
```
/srv/
├── media/        # Jellyfin library (movies, tv, music)
├── recordings/   # Frigate NVR clips
├── backups/      # VM backup snapshots
└── downloads/    # *arr download staging
```

**Hardware note:** On the Dell, this uses the internal 500GB HDD. When the Gaming PC comes online, attach dedicated disks and migrate.

#### 1d. Home Assistant (`hosts/homeassistant/`, `systemModules/homeassistant.nix`)

**Priority**: Deploy in Phase 1 to establish IoT/automation foundation that integrates with all subsequent services.

**Services:**
- **Home Assistant Core** — central automation and device management hub
- **PostgreSQL** — database backend for historical data
- **Nginx** — reverse proxy with ACME for external access
- **MQTT Broker** (Mosquitto) — IoT device communication
- **Z-Wave/Zigbee support** — local device control (USB dongles)

**Integration Points:**
- **Grafana metrics**: Custom sensors and dashboards via Home Assistant Prometheus integration
- **Frigate cameras**: Live feeds, motion detection alerts, and automation triggers
- **Monitoring stack**: System health sensors exported to Prometheus
- **Matrix notifications**: Alerts and status updates via Matrix bot integration

**IoT Device Support:**
- **PetLibro devices**: Pet feeders, waterers, and automatic litterbox via cloud integration or MQTT
- **Robot vacuum**: Cleaning schedules, room-specific cleaning, maintenance alerts
- **Smart lights**: Scene automation, circadian lighting, presence detection
- **Network devices**: Router/switch monitoring, bandwidth usage, device tracking

**Config Structure:**
```nix
systemModules/homeassistant.nix
├── services.home-assistant (core automation engine)
├── services.postgresql (historical data storage)  
├── services.mosquitto (MQTT broker for IoT devices)
├── services.nginx (reverse proxy + SSL termination)
└── networking.firewall (ports 8123, 1883, 1884)
```

**Network Integration (currently flat 10.0.0.0/24; VLANs planned):**
- **Management VLAN (1)**: Home Assistant server access
- **IoT VLAN (10)**: Isolated device communication via MQTT bridge (future)
- **Services VLAN (20)**: Integration with Frigate, Grafana, Matrix (future)
- **Cross-VLAN rules**: Controlled access between IoT devices and services (future)

**Automation Examples:**
- **Pet care**: Feeding schedules, water level monitoring, litterbox cleaning alerts
- **Security integration**: Motion detection → light automation → Matrix notifications  
- **Energy monitoring**: Device power usage → Grafana dashboards → efficiency automations
- **Presence detection**: Phone/device tracking → scene activation → security arming

**Migration Notes:**
- **Existing instance**: Migrate configuration from current Proxmox VM
- **Network setup**: Reconfigure for new VLAN structure and Protectli router
- **Device re-pairing**: Update device configurations for new network topology
- **Backup strategy**: Regular config backups to NAS VM, database snapshots

**Resources:**
```
VM ID: 103 (Dell node)
Cores: 2, RAM: 4GB, Disk: 40GB
USB passthrough: Z-Wave/Zigbee dongles
Network: Bridge to all VLANs with firewall rules
```

**Implementation Priority:**
1. Deploy basic Home Assistant + PostgreSQL + MQTT
2. Migrate existing configuration and update network settings
3. Re-establish IoT device connections on new VLANs
4. Configure Grafana integration for monitoring dashboards
5. Set up Frigate camera feeds and automation triggers
6. Implement Matrix notification system
7. Create comprehensive device automations and scenes

**Benefits:**
- **Central IoT hub**: Single interface for all smart home devices
- **Service integration**: Unified automation across homelab services  
- **Enhanced monitoring**: IoT device metrics in Grafana dashboards
- **Automation platform**: Complex scenarios across security, comfort, and efficiency
- **Mobile access**: Secure remote control via Home Assistant mobile app

### Phase 2 — Communication & Dev Tools (Dell node)

#### 2a. Matrix Homeserver & Agent Control Plane (`hosts/matrix/`)

- `systemModules/matrix.nix` is already complete
- Wrap in a host config extending `hosts/server/`
- DNS records needed: `matrix.sandmhan.dev`, `sandmhan.dev`, `turn.sandmhan.dev`
- ACME/Let's Encrypt (port 80/443 must be reachable — port forward from Protectli)
- Secrets via sops-nix: Synapse registration secret, Coturn auth, PostgreSQL password
- Optional: Element Web as a static nginx site

**Agent Control via Matrix:**

Matrix serves as the primary remote interface for interacting with autonomous AI agents and receiving homelab status updates. All messaging logs stay self-hosted.

**Architecture:**
- **Matrix bot service** (`systemModules/matrix-agent-bridge.nix`) — a bot user on the Synapse homeserver that bridges commands to agents
- **Dedicated rooms** for agent interaction:
  - `#agent-status:sandmhan.dev` — broadcast channel for agent progress updates, build results, deployment notifications
  - `#agent-control:sandmhan.dev` — interactive room for issuing commands to running agents (start, stop, check status, adjust parameters)
  - `#homelab-alerts:sandmhan.dev` — system-level alerts from monitoring (Prometheus alertmanager → Matrix webhook)
- **End-to-end encryption** optional per room — status broadcasts can be unencrypted for webhook simplicity, control rooms encrypted

**Bot Capabilities:**
- **Agent lifecycle management**: Start/stop/restart autonomous agents via chat commands
- **Status polling**: Request current status of running tasks (`!status agent-sandbox`, `!status deploy gaia`)
- **Build orchestration**: Trigger NixOS builds on the builder VM (`!deploy nvr`, `!build .#agent-sandbox`)
- **Log streaming**: Tail recent logs from any agent or service (`!logs frigate --lines 50`)
- **Approval gates**: Agents pause and request human approval before destructive actions — user responds in Matrix

**Integration Points:**
- **NixOS Builder (Phase 1a)**: Builder reports build success/failure to `#agent-status`, accepts build commands from `#agent-control`
- **Monitoring (Phase 1b)**: Prometheus alertmanager sends alerts to `#homelab-alerts` via Matrix webhook receiver
- **Home Assistant (Phase 1d)**: HA notifications route through Matrix bot (security alerts, IoT events)
- **AI Server (Phase 3a)**: Remote inference requests and agent orchestration via Matrix commands
- **Tailscale/WireGuard**: VPN provides secure remote access to Matrix homeserver from mobile/laptop

**Implementation approach:**
- Use [mautrix](https://github.com/mautrix) or [matrix-nio](https://github.com/poljar/matrix-nio) Python SDK for bot implementation
- Bot runs as a systemd service alongside Synapse on the matrix host
- Command parsing with prefix (`!deploy`, `!status`, `!logs`) or natural language via local LLM (Phase 3)
- Webhook receiver endpoint for Prometheus alertmanager, Forgejo CI, and other services

**Remote Access Strategy:**
- **Primary**: Matrix client apps (Element on phone/laptop) for day-to-day agent interaction — works from anywhere with internet
- **Secondary**: Tailscale mesh VPN for direct SSH/web UI access when deeper control is needed
- **Tailscale setup**: Each homelab VM imports `systemModules/tailscale.nix` and auto-enrolls via sops-encrypted auth key. One subnet router node advertises homelab subnets to the tailnet. No port forwarding, NAT traversal, or key distribution needed.
- **Benefit**: Matrix federation means you can interact from any Matrix client without VPN, while Tailscale remains available for admin tasks
- **Note**: WireGuard module (`systemModules/wireguard.nix`) and host (`hosts/vpn/`) are retained in the repo but not deployed

#### 2b. Self-hosted Git — Forgejo (`hosts/git/`, `systemModules/forgejo.nix`)

**Services:**
- **Forgejo** (actively maintained Gitea fork, in nixpkgs as `services.forgejo`)
- PostgreSQL backend
- Nginx reverse proxy with ACME
- SSH on port 3022 (avoid conflict with host SSH)

**Config:**
```nix
services.forgejo = {
  enable = true;
  database.type = "postgres";
  settings.server = {
    DOMAIN = "git.sandmhan.dev";
    ROOT_URL = "https://git.sandmhan.dev/";
    SSH_PORT = 3022;
  };
};
```

- Mirror GitHub repos via Forgejo's built-in migration
- CI/CD: Forgejo Actions (Gitea Actions compatible) or Woodpecker CI

### Phase 3 — GPU Services (Gaming PC node required)

These all need significant CPU/RAM/GPU and wait for the Gaming PC to become a Proxmox node.

#### 3a. Local AI Server (`hosts/ai/`, extend `systemModules/llama.nix`)

**GPU**: RTX 3060 (12GB VRAM) via PCI passthrough

**Services (all sharing the GPU via time-slicing):**

| Service | Purpose | Port | Notes |
|---------|---------|------|-------|
| **llama.cpp** | LLM inference (OpenAI-compatible API) | 8080 | Existing module, `--n-gpu-layers 999` |
| **whisper.cpp** | Speech-to-text | 8081 | Server mode, shares GPU |
| **Piper** | Text-to-speech | 8082 | CPU-only, lightweight |
| **ComfyUI** | Image generation (Stable Diffusion) | 8188 | Web UI + API, GPU |
| **Open WebUI** | Chat frontend for llama.cpp | 3000 | Web UI, connects to llama.cpp API |

**New module**: `systemModules/ai-tools.nix` — orchestrates whisper, piper, comfyui as systemd services or OCI containers alongside the existing llama.nix.

**Agent orchestration**: The llama.cpp OpenAI-compatible API enables tool-use agents. Open WebUI provides a ChatGPT-like interface. For programmatic orchestration, any framework (LangChain, CrewAI, etc.) can hit the local API.

**Multi-modal**: whisper (audio→text) + llama.cpp (text→text) + piper (text→audio) + comfyui (text→image) gives you a full local multi-modal pipeline.

#### 3b. Media Server — nixflix (`hosts/media/`)

**Flake input:**
```nix
nixflix = {
  url = "github:kiriwalawren/nixflix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

**GPU**: 1080 Ti (passthrough) for Jellyfin hardware transcoding via NVENC/NVDEC

**Services (all managed by nixflix module):**
- **Jellyfin** — media server with automatic library config
- **Sonarr** — TV show management
- **Radarr** — movie management
- **Lidarr** — music management (optional)
- **Prowlarr** — indexer management
- **qBittorrent** — download client (behind WireGuard kill switch)
- **SABnzbd** — Usenet download client
- **Recyclarr** — TRaSH Guides quality profiles
- **Nginx** — reverse proxy (managed by nixflix)
- **PostgreSQL** — backend for *arr services

**Storage**: NFS mounts from NAS VM (`/data/media`, `/data/downloads`)

**Secrets**: All API keys and passwords via sops-nix using nixflix's `{_secret = path}` pattern.

#### 3c. Frigate NVR (`hosts/nvr/`, refactor `systemModules/frigate.nix`)

**Improvements over current config:**
- Dynamic camera config via NixOS options (not hardcoded IPs)
- AI detector pointing to local AI server's API (HTTP detector → `http://ai-vm:8080/detect`)
- Motion zones and detection masks per camera
- Recording storage on NAS mount via NFS
- MQTT integration for Home Assistant
- Camera streams on IoT VLAN (future), Frigate VM on homelab network with cross-VLAN access to IoT (when VLANs are implemented)

#### 3d. Fitness Tracking — wger (`hosts/fitness/`, `systemModules/wger.nix`)

**Why wger**: Only self-hosted app covering all three pillars — exercise tracking, nutrition logging (with Open Food Facts integration), and biometric measurements (weight, body fat, custom measurements). Has native Prometheus `/metrics` endpoint for Grafana dashboards.

**Deployment**: OCI container (not in nixpkgs as a service module)

**Stack:**
- **wger** — Django app (OCI container)
- **PostgreSQL** — database backend
- **Redis** — cache/celery broker
- **Nginx** — reverse proxy
- **Celery** — async task worker (exercise thumbnail generation, etc.)

**Grafana integration**: Prometheus scrapes wger's `/metrics` endpoint directly. Custom Grafana dashboards for:
- Weight/body composition trends
- Caloric intake vs expenditure
- Macro breakdown over time
- Workout volume and progression

**Mobile**: Native Flutter apps (Android/iOS) with barcode scanning for food logging and offline workout tracking.

**Complement (optional)**: Tandoor Recipes (`services.tandoor-recipes` — native NixOS module) for meal planning and recipe management with USDA nutritional data. Separate concern from wger's tracking.

### Phase 4 — Nice-to-Have

#### 4a. Remote Gaming — Sunshine (`hosts/gaming/`, `systemModules/sunshine-server.nix`)

- Most complex setup — needs full GPU passthrough, virtual display, PulseAudio/PipeWire
- GPU: 3060 or 1080 Ti (dedicated, not shared with AI)
- Sunshine server with Moonlight clients on Framework laptop, phones
- Existing `homeModules/sunshine.nix` is user-level — needs a system-level module for headless VM
- May require Looking Glass for local+remote simultaneous use
- **Recommendation**: Tackle last, after all other services are stable

---

## File Structure (new files to create)

```
hosts/
├── monitor/default.nix       # Prometheus + Grafana + Loki (VM)
├── nas/default.nix            # NFS + Samba + backups (VM)
├── matrix/default.nix         # Wrapper around systemModules/matrix.nix (VM)
├── git/default.nix            # Forgejo (VM)
├── ai/default.nix             # GPU passthrough + multi-service AI (VM)
├── media/default.nix          # nixflix media stack (VM)
├── fitness/default.nix        # wger + supporting services (VM)
├── gaming/default.nix         # Sunshine remote gaming (VM)
│
├── lxc-base/                  # LXC alternative scaffolding
│   ├── default.nix            # Base LXC config (like server/default.nix)
│   ├── networking.nix         # Container networking
│   └── monitoring.nix         # LXC-specific monitoring
├── lxc-monitor/default.nix    # Monitoring stack (LXC alternative)
├── lxc-nas/default.nix        # NAS services (LXC alternative)
├── lxc-matrix/default.nix     # Matrix homeserver (LXC alternative)
├── lxc-git/default.nix        # Forgejo (LXC alternative)

systemModules/
├── monitoring.nix             # Prometheus + Grafana + Loki
├── nas.nix                    # NFS/Samba exports, backup jobs
├── forgejo.nix                # Git server
├── matrix-agent-bridge.nix    # Matrix bot for AI agent control & notifications
├── ai-tools.nix               # whisper, piper, comfyui orchestration
├── wger.nix                   # Fitness tracking (OCI container)
├── tailscale.nix              # Tailscale mesh VPN (remote access)
├── wireguard.nix              # WireGuard VPN (retained, not deployed)
├── sunshine-server.nix        # Headless GPU gaming server

secrets/
├── matrix.yaml                # Matrix secrets (sops-encrypted)
├── media.yaml                 # nixflix API keys
├── forgejo.yaml               # Git server secrets
├── wger.yaml                  # Fitness app secrets
├── grafana.yaml               # Monitoring secrets
├── tailscale/secrets.yaml     # Tailscale auth key
└── .sops.yaml                 # Key mappings
```

---

## Deployment Order

```
Phase 1 (Dell, now)          Phase 2 (Dell, now)
┌──────────────┐             ┌──────────────┐
│  monitoring  │◄────────────│   matrix     │◄─── HA notifications
│  (grafana +  │  metrics    │  (synapse +  │
│  prometheus) │◄──┐         │  agent bot)  │◄─── remote agent control
└──────┬───────┘   │         └──────┬───────┘
       │           │                │ commands/status
┌──────▼───────┐   │         ┌──────▼───────┐
│     nas      │   │         │    git       │
│  (nfs/smb)   │   │         │  (forgejo)   │──── CI webhooks to Matrix
└──────┬───────┘   │         └──────────────┘
       │           │
┌──────▼───────┐   │         Phase 3 (Gaming PC)
│homeassistant │◄──┤         ┌──────────────┐
│ (iot hub +   │   ├─────────│     ai       │
│ automation)  │   │         │ (llama +     │◄──── Frigate detector
└───────┬──────┘   │         │  whisper +   │◄──── Matrix agent cmds
        │          │         │  comfyui)    │
        │          │         └──────────────┘
        │          │         ┌──────────────┐
        │          ├─────────│   media      │
        │          │         │ (nixflix +   │
        │          │         │  jellyfin)   │
        │          │         └──────┬───────┘
        │          │                │ NFS mount
        │          │         ┌──────▼───────┐
        │          ├─────────│    nvr       │◄─── HA camera integration
        └──────────┼─────────│  (frigate)   │
                   │         └──────────────┘
                   │         ┌──────────────┐
                   ├─────────│   fitness    │
                   │         │   (wger)     │
                   │         └──────────────┘
                   │
                   │         Phase 4
                   │         ┌──────────────┐
                   └─────────│   gaming     │
                             │ (sunshine)   │
                             └──────────────┘

Matrix Agent Control Flow:
┌──────────┐    Element     ┌──────────┐    bot API    ┌──────────────┐
│  Phone/  │◄──────────────►│  Matrix  │◄────────────►│  Agent Bot   │
│  Laptop  │   (anywhere)   │  Synapse │              │  Service     │
└──────────┘                └──────────┘              └──────┬───────┘
                                                             │
                            ┌────────────────────────────────┤
                            │              │                 │
                     ┌──────▼──┐    ┌──────▼──┐      ┌──────▼──────┐
                     │ Builder │    │  Agent  │      │ Alertmanager│
                     │  (build │    │ Sandbox │      │ (monitoring │
                     │  deploys)│    │ (tasks) │      │  webhooks)  │
                     └─────────┘    └─────────┘      └─────────────┘
```

---

## Shared Module Conventions

All VMs follow these patterns from `hosts/server/default.nix`:
- systemd-networkd + DHCP (static IP overrides per host)
- SSH public-key only (framework SSH key)
- qemuGuest.enable for Proxmox integration
- Prometheus node_exporter on port 9100 (scraped by monitoring VM)
- Nix flakes enabled, weekly garbage collection
- Passwordless sudo for wheel group
- Secrets via sops-nix

Each host config:
1. Imports `../server/default.nix` (base template)
2. Imports relevant `systemModules/*.nix`
3. Sets `networking.hostName`
4. Overrides resource-specific settings (firewall ports, storage mounts, GPU passthrough)
