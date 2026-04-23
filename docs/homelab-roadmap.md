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
| Agent sandbox VM | Done | `hosts/agent/` | VMA image building |
| llama.cpp module | Complete | `systemModules/llama.nix` | Needs real GPU PCI IDs |
| Matrix Synapse | Complete | `systemModules/matrix.nix` | Needs DNS + ACME |
| Frigate | Partial | `systemModules/frigate.nix` | Hardcoded cameras, no AI detector |
| Jellyfin | Stub | `systemModules/jellyfin.nix` | Just `enable = true` |
| sops-nix | Partial | `feat/sops` branch | Initial integration, needs secrets populated |
| Monitoring | Not started | — | — |
| NAS/backup | Not started | — | — |
| Media stack (*arr) | Not started | — | nixflix integration planned |
| Fitness tracking | Not started | — | wger (OCI container) |
| Git server | Not started | — | Forgejo |
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
| **agent-sandbox** | 900 | 4 | 8GB | — | 40GB | Done |

> Note: VMs that need GPU passthrough can only run on the Gaming PC node. Lightweight services run on the Dell now and can be migrated later.

---

## Network Architecture

### VLANs (Cisco 3750G)

| VLAN | Subnet | Purpose |
|------|--------|---------|
| 1 (default) | 10.0.0.0/24 | Management / trusted devices |
| 10 | 10.0.10.0/24 | IoT devices (cameras, smart home, sensors) |
| 20 | 10.0.20.0/24 | Homelab services (VMs) |
| 30 | 10.0.30.0/24 | Guest network |

### Firewall Rules (Protectli / Proxmox firewall)
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
- **Matrix**: registration shared secret, Coturn static auth secret, PostgreSQL password
- **Nixflix/media**: Sonarr/Radarr/Prowlarr API keys, SABnzbd API key, qBittorrent password, Jellyfin admin password
- **Forgejo**: admin password, PostgreSQL password, secret key
- **wger**: Django secret key, API keys, PostgreSQL password
- **Grafana**: admin password, SMTP credentials (optional)
- **WireGuard**: private keys (if VPN for download clients)

---

## Implementation Phases

> **Note**: Each phase can be implemented with **VMs** (current approach) or **LXC containers** (resource-efficient alternative). LXC requires developing parallel scaffolding (`hosts/lxc-base/`, `lxcConfigurations` in flake.nix) but offers 50% better resource utilization.

### Phase 1 — Observability & Storage (Dell node, deploy now)

These have no GPU dependency and are lightweight enough for the Dell.

#### 1a. Monitoring Stack (`hosts/monitor/`, `systemModules/monitoring.nix`)

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

#### 1b. NAS VM (`hosts/nas/`, `systemModules/nas.nix`)

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

### Phase 2 — Communication & Dev Tools (Dell node)

#### 2a. Matrix Homeserver (`hosts/matrix/`)

- `systemModules/matrix.nix` is already complete
- Wrap in a host config extending `hosts/server/`
- DNS records needed: `matrix.sandmhan.dev`, `sandmhan.dev`, `turn.sandmhan.dev`
- ACME/Let's Encrypt (port 80/443 must be reachable — port forward from Protectli)
- Secrets via sops-nix: Synapse registration secret, Coturn auth, PostgreSQL password
- Optional: Element Web as a static nginx site

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
- Camera streams on IoT VLAN (VLAN 10), Frigate VM on services VLAN (VLAN 20) with cross-VLAN access to IoT

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
├── ai-tools.nix               # whisper, piper, comfyui orchestration
├── wger.nix                   # Fitness tracking (OCI container)
├── sunshine-server.nix        # Headless GPU gaming server

secrets/
├── matrix.yaml                # Matrix secrets (sops-encrypted)
├── media.yaml                 # nixflix API keys
├── forgejo.yaml               # Git server secrets
├── wger.yaml                  # Fitness app secrets
├── grafana.yaml               # Monitoring secrets
└── .sops.yaml                 # Key mappings
```

---

## Deployment Order

```
Phase 1 (Dell, now)          Phase 2 (Dell, now)
┌──────────────┐             ┌──────────────┐
│  monitoring  │◄────────────│   matrix     │
│  (grafana +  │  metrics    │  (synapse +  │
│  prometheus) │◄──┐         │   coturn)    │
└──────┬───────┘   │         └──────────────┘
       │           │         ┌──────────────┐
┌──────▼───────┐   │         │    git       │
│     nas      │   │         │  (forgejo)   │
│  (nfs/smb)   │   │         └──────────────┘
└──────────────┘   │
                   │         Phase 3 (Gaming PC)
                   │         ┌──────────────┐
                   ├─────────│     ai       │
                   │         │ (llama +     │◄──── Frigate detector
                   │         │  whisper +   │
                   │         │  comfyui)    │
                   │         └──────────────┘
                   │         ┌──────────────┐
                   ├─────────│   media      │
                   │         │ (nixflix +   │
                   │         │  jellyfin)   │
                   │         └──────┬───────┘
                   │                │ NFS mount
                   │         ┌──────▼───────┐
                   ├─────────│    nvr       │
                   │         │  (frigate)   │
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
