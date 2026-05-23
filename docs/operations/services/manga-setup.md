# Manga Stack Setup Guide

Self-hosted manga reading with **Komga** (library server) and **Suwayomi** (source aggregator), integrated with Prometheus/Loki monitoring and the **Mihon** Android app.

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                   Manga VM (Proxmox)                 │
│                                                      │
│  ┌─────────────┐    ┌──────────────┐                 │
│  │    Komga     │    │  Suwayomi    │                 │
│  │   :25600     │◄───│   :4567      │                 │
│  │  (library)   │    │  (sources)   │                 │
│  └──────┬───────┘    └──────┬───────┘                 │
│         │   downloads CBZ   │                         │
│         │◄──────────────────┘                         │
│         │                                             │
│  ┌──────┴───────────────────────────┐                 │
│  │      /var/lib/komga/library      │                 │
│  │    (shared manga storage)        │                 │
│  └──────────────────────────────────┘                 │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌────────────────┐     │
│  │  Nginx   │  │  Node    │  │   Promtail     │     │
│  │  :80     │  │ Exporter │  │ (→ Loki)       │     │
│  │          │  │  :9100   │  │  :9080          │     │
│  └──────────┘  └──────────┘  └────────────────┘     │
└──────────────────────────────────────────────────────┘
         │                │               │
         ▼                ▼               ▼
    ┌──────���──┐    ┌────────────┐   ┌──────────┐
    │  Mihon   │    │ Prometheus │   │   Loki   │
    │ (Android)│    │   :9090    │   │  :3100   │
    └─────────┘    └────────────┘   └──────────┘
```

### How the Services Interact

- **Komga** serves your local manga library (CBZ/CBR/PDF/EPUB) via a web UI and OPDS feed
- **Suwayomi** runs Mihon extensions server-side to browse and download manga from online sources
- When `komgaIntegration.enable = true` (default), Suwayomi downloads directly into Komga's library directory as CBZ files, so all manga is accessible from one place
- **Mihon** on Android connects to both via their Keiyoushi extensions

## Services

### Komga (Library Server)

| Property | Value |
|----------|-------|
| Image | `gotson/komga:latest` |
| Port | 25600 (internal), 80 (nginx) |
| Data | `/var/lib/komga/config` (database, settings) |
| Library | `/var/lib/komga/library` (manga files) |
| Stack | Kotlin/JVM |
| RAM | ~1GB default (configurable via `javaMemory`) |
| OPDS | v1 + v2 at `/opds/v1.2/catalog` and `/opds/v2/catalog` |
| API | REST at `/api/v1/` |

**Supported formats:** CBZ, CBR, PDF, EPUB

### Suwayomi (Source Aggregator)

| Property | Value |
|----------|-------|
| Image | `ghcr.io/suwayomi/tachidesk:latest` |
| Port | 4567 (internal), 80 (nginx) |
| Data | `/var/lib/suwayomi` (extensions, thumbnails, database) |
| Downloads | Into Komga library by default, or `/var/lib/suwayomi/downloads` |
| Stack | Kotlin/JVM |
| RAM | ~1GB default (configurable via `javaMemory`) |
| API | REST at `/api/v1/` |

**Optional sidecar:** FlareSolverr (`flaresolverr.enable = true`) for sources behind Cloudflare protection.

## Configuration

### Module Options

```nix
# In your host config (e.g., hosts/manga/default.nix)
homelab.manga = {
  enable = true;
  deploymentType = "vm";        # "vm" or "container"
  resourceProfile = "standard"; # "minimal", "standard", or "high"
  monitoring.enable = true;     # node exporter + promtail

  komga = {
    enable = true;              # default: follows manga.enable
    port = 25600;
    image = "gotson/komga:latest";
    dataDir = "/var/lib/komga";
    libraryDir = "/var/lib/komga/library";
    javaMemory = "1g";          # auto-scaled by resourceProfile
    reverseProxy.enable = true;
    reverseProxy.domain = "komga.homelab.local";
  };

  suwayomi = {
    enable = true;              # default: follows manga.enable
    port = 4567;
    image = "ghcr.io/suwayomi/tachidesk:latest";
    dataDir = "/var/lib/suwayomi";
    downloadDir = "/var/lib/suwayomi/downloads";
    javaMemory = "1g";          # auto-scaled by resourceProfile
    komgaIntegration.enable = true;  # downloads go into Komga library
    reverseProxy.enable = true;
    reverseProxy.domain = "suwayomi.homelab.local";
    flaresolverr.enable = false;
  };
};
```

### Resource Profiles

| Profile | Komga JVM | Suwayomi JVM | Recommended VM |
|---------|-----------|--------------|----------------|
| minimal | 512m | 512m | 2 cores, 2GB RAM |
| standard | 1g | 1g | 2 cores, 4GB RAM |
| high | 2g | 2g | 4 cores, 8GB RAM |

## Pre-Deployment Checklist

All steps below must be completed before the manga stack is operational. Items are ordered by dependency.

- [ ] **Assign DHCP reservation** — Reserve a static IP for the manga VM on the homelab network (`10.0.0.0/24`) via pfSense or your router. Record the IP.
- [ ] **Add flake.nix entry** — Add the `manga` NixOS configuration to `flake.nix` (see step 4 below for the exact snippet).
- [ ] **Create Proxmox VM** — Build VMA image, transfer to Proxmox, restore as a new VM (steps 1-2 below).
- [ ] **Bootstrap SOPS secrets** — SSH into the new VM, extract its age public key, add to `.sops.yaml`, encrypt `secrets/manga/secrets.yaml` (step 3 below).
- [ ] **Update Promtail Loki URL** — In `systemModules/manga/monitoring.nix`, replace `10.0.0.TBD` in the Promtail client URL with the actual monitoring VM IP (currently `10.0.0.10` for lxc-monitor).
- [ ] **Uncomment monitoring scrape targets** — In `systemModules/monitoring.nix`:
  - Uncomment the manga node-exporter line in `staticTargets.node-exporters` and replace `10.0.0.TBD` with the manga VM IP
  - Uncomment the `komga` and `suwayomi` scrape jobs in `additionalScrapeConfigs` and replace `10.0.0.TBD`
  - Uncomment the manga entry in `targetLabels` and replace `10.0.0.TBD`
- [ ] **Deploy configuration** — `nixos-rebuild switch --target-host sandmhan@<manga-ip> --flake .#<manga-output> --sudo`
- [ ] **Redeploy monitoring** — Push updated scrape targets to the monitoring host so Prometheus starts scraping the manga VM.
- [ ] **Verify Komga first-run** — Open `http://<manga-ip>:25600`, create admin account, add a library pointing to `/data`.
- [ ] **Verify Suwayomi** — Open `http://<manga-ip>:4567`, install desired extensions (MangaDex, etc.).
- [ ] **Configure Mihon** — Install Keiyoushi extensions on Android, add Komga and Suwayomi sources (see Mihon setup section below).
- [ ] **Update infrastructure registry** — Replace all `TBD` placeholders for manga in `docs/architecture/infrastructure-registry.md` with the actual VM ID and IP.
- [ ] **Verify monitoring** — Confirm node exporter metrics appear in Prometheus at `http://<monitoring-ip>:9090/targets` and logs flow to Loki.

## Deployment

### 1. Build the Proxmox VMA Image

```bash
nixos-rebuild build-image --image-variant proxmox --flake .#initialProxmoxVMA
```

### 2. Transfer and Restore on Proxmox

```bash
# Transfer VMA to Proxmox host
scp result/*.vma.zst root@10.0.0.4:/var/lib/vz/dump/

# Restore as new VM (pick an unused VMID)
qmrestore /var/lib/vz/dump/<file>.vma.zst <VMID> --storage local-zfs --force

# Allocate resources (standard profile)
qm set <VMID> --cores 2 --memory 4096 --name manga
qm start <VMID>
```

### 3. Bootstrap SOPS Secrets

```bash
# SSH into the new VM
ssh sandmhan@<manga-ip>

# Get the host's age public key
sudo cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age

# On your local machine, add that key to .sops.yaml and create the encrypted secrets
cd secrets/manga
cp secrets.yaml.example secrets.yaml
sops -e -i secrets.yaml
```

### 4. Add Host to Flake

Add to `flake.nix`:

```nix
manga = mkNixosSystem {
  hostname = "manga";
  modules = [
    ./hosts/server
    ./hosts/server/hardware-configuration.nix
    ./systemModules/manga
    sops-nix.nixosModules.sops
  ];
};
```

### 5. Deploy Configuration

```bash
nixos-rebuild switch --target-host sandmhan@<manga-ip> --flake .#<manga-output> --sudo
```

### 6. Update Monitoring Targets

Once the manga VM has a static IP, update `systemModules/monitoring.nix`:
1. Uncomment the manga node-exporter entry in `staticTargets.node-exporters`
2. Uncomment the `komga` and `suwayomi` scrape jobs in `additionalScrapeConfigs`
3. Uncomment the manga entry in `targetLabels`
4. Replace all `10.0.0.TBD` with the actual IP

## Storage

### Persistent Data Locations

| Path | Contents | Backup Priority |
|------|----------|-----------------|
| `/var/lib/komga/config` | Komga database (SQLite), user accounts, reading progress | **High** |
| `/var/lib/komga/library` | Manga/comic files (CBZ, CBR, PDF, EPUB) | **High** |
| `/var/lib/suwayomi` | Suwayomi database, installed extensions, thumbnails | Medium |

### Podman Volumes

The stack uses host bind mounts (not named volumes) for easier backup and inspection:
- Komga config: `${dataDir}/config` → `/config` in container
- Komga library: `${libraryDir}` → `/data` in container
- Suwayomi data: `${dataDir}` → `/home/suwayomi/.local/share/Tachidesk` in container

### Backup Strategy

```bash
# Stop containers before backup for consistency
sudo systemctl stop podman-komga podman-suwayomi

# Backup critical data
sudo tar czf /tmp/manga-backup-$(date +%Y%m%d).tar.gz \
  /var/lib/komga/config \
  /var/lib/komga/library \
  /var/lib/suwayomi

# Restart
sudo systemctl start podman-komga podman-suwayomi
```

## Mihon (Android) Setup

### Komga Extension

1. Open Mihon → Settings → Browse → Extension repos
2. Add the Keiyoushi extensions repo: `https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json`
3. Browse extensions → search "Komga" → Install
4. Go to Sources → Komga → Settings (gear icon)
5. Set **Server URL**: `http://<manga-ip>:25600` (or `http://komga.homelab.local` if DNS is configured)
6. Set **Username** and **Password** (from Komga's first-run setup)
7. Reading progress syncs bidirectionally between Komga and Mihon

### Suwayomi Extension

1. Browse extensions → search "Suwayomi" → Install
2. Go to Sources → Suwayomi → Settings
3. Set **Server URL**: `http://<manga-ip>:4567` (or `http://suwayomi.homelab.local`)
4. Browse sources, add manga to library, and download chapters through the Suwayomi source in Mihon

### Recommended Workflow

1. **Discover** manga using Suwayomi sources (MangaDex, etc.) via Mihon or the Suwayomi web UI
2. **Download** chapters through Suwayomi — they land in Komga's library as CBZ files
3. **Read** from Komga in Mihon for a unified library with progress tracking
4. Use Suwayomi directly in Mihon for catching up on ongoing series from online sources

## Monitoring

### Prometheus Metrics

| Endpoint | Source | Description |
|----------|--------|-------------|
| `:9100/metrics` | Node Exporter | System CPU, memory, disk, network |
| `:25600/actuator/prometheus` | Komga (Spring Boot) | JVM metrics, library stats, API latency |
| `:4567` | Suwayomi | Basic JVM metrics (if enabled) |

### Loki Logs

Promtail ships journald logs from these systemd units:
- `podman-komga.service`
- `podman-suwayomi.service`
- `podman-flaresolverr.service` (if enabled)
- `manga-network.service`
- `manga-health-check.service`

### Grafana

Once scrape targets are live, create a Manga dashboard or add panels to the existing Infrastructure Health dashboard:
- Komga: library size, books scanned, active users, API response times
- System: container memory/CPU usage, disk usage on library mount
- Logs: error rate from Loki, container restart events

## Troubleshooting

### Containers not starting

```bash
# Check container status
sudo podman ps -a --filter name=komga --filter name=suwayomi

# View logs
sudo journalctl -u podman-komga -f
sudo journalctl -u podman-suwayomi -f

# Check network
sudo podman network inspect manga-net
```

### Komga not finding library files

```bash
# Verify library directory has content
ls -la /var/lib/komga/library/

# Check permissions (container runs as non-root UID 1000)
sudo chown -R 1000:1000 /var/lib/komga/library/
```

### Suwayomi downloads not appearing in Komga

```bash
# Verify integration mount is working
sudo podman inspect suwayomi | jq '.[0].Mounts'

# Trigger Komga library scan
curl -X POST http://localhost:25600/api/v1/libraries/<library-id>/scan \
  -u admin:password
```

### JVM out of memory

Increase `javaMemory` in the module config or set `resourceProfile = "high"`. Check current usage:

```bash
sudo podman stats komga suwayomi --no-stream
```

## Network Ports

| Port | Service | Protocol | Access |
|------|---------|----------|--------|
| 22 | SSH | TCP | Always open |
| 80 | Nginx | TCP | Open when reverseProxy enabled |
| 25600 | Komga | TCP | Open when reverseProxy disabled |
| 4567 | Suwayomi | TCP | Open when reverseProxy disabled |
| 9100 | Node Exporter | TCP | Prometheus scraping |
| 9080 | Promtail | TCP | Debug/status only |
