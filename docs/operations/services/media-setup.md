# Media Server (nixflix) Setup Guide

## Overview

The media server provides a comprehensive media management stack running on a dedicated Proxmox VM with GPU passthrough for hardware transcoding. Services include Jellyfin for media playback, the *arr stack for automated media management, and download clients for content acquisition.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Media Server VM                              │
│  ┌───────────┐  ┌────────┐  ┌────────┐  ┌──────────┐          │
│  │  Jellyfin  │  │ Sonarr │  │ Radarr │  │ Prowlarr │          │
│  │  (8096)    │  │ (8989) │  │ (7878) │  │  (9696)  │          │
│  └─────┬─────┘  └───┬────┘  └───┬────┘  └────┬─────┘          │
│        │             │           │             │                 │
│  ┌─────┴─────────────┴───────────┴─────────────┴─────┐         │
│  │              Nginx Reverse Proxy (:80)              │         │
│  └────────────────────────────────────────────────────┘         │
│                                                                  │
│  ┌──────────────┐  ┌──────────┐  ┌───────────┐                 │
│  │ qBittorrent  │  │ SABnzbd  │  │ Recyclarr │                 │
│  │   (OCI)      │  │  (8085)  │  │   (OCI)   │                 │
│  │   (8080)     │  │          │  │           │                  │
│  └──────┬───────┘  └────┬─────┘  └───────────┘                 │
│         │               │                                        │
│  ┌──────┴───────────────┴──────────────────────┐                │
│  │         NFS Mounts from NAS VM              │                │
│  │  /data/media     - Media library            │                │
│  │  /data/downloads - Download staging         │                │
│  └─────────────────────────────────────────────┘                │
│                                                                  │
│  ┌─────────────────┐                                            │
│  │ 1080 Ti GPU     │  NVENC/NVDEC hardware transcoding          │
│  │ (PCI passthru)  │                                            │
│  └─────────────────┘                                            │
└─────────────────────────────────────────────────────────────────┘
```

## Services

| Service | Type | Port | Purpose |
|---------|------|------|---------|
| Jellyfin | Native NixOS | 8096 | Media server with hardware transcoding |
| Sonarr | Native NixOS | 8989 | TV show management and automation |
| Radarr | Native NixOS | 7878 | Movie management and automation |
| Prowlarr | Native NixOS | 9696 | Indexer management for Sonarr/Radarr |
| qBittorrent | OCI Container | 8080 | Torrent client with optional VPN kill switch |
| SABnzbd | Native NixOS | 8085 | Usenet download client |
| Recyclarr | OCI Container | N/A | TRaSH Guides quality profile sync |
| Nginx | Native NixOS | 80 | Reverse proxy for all services |
| Node Exporter | Native NixOS | 9100 | Prometheus metrics |

## Configuration

### Module: `systemModules/media.nix`

The module is option-based with the following top-level settings:

```nix
homelab.media = {
  enable = true;
  deploymentType = "vm";       # vm | container | hybrid
  resourceProfile = "high";    # minimal | standard | high
  domain = "media.homelab.local";
};
```

### Sub-options

Each service can be individually enabled/disabled:

```nix
homelab.media = {
  jellyfin.enable = true;
  jellyfin.gpu.enable = true;
  sonarr.enable = true;
  radarr.enable = true;
  prowlarr.enable = true;
  downloadClients.qbittorrent.enable = true;
  downloadClients.sabnzbd.enable = true;
  recyclarr.enable = true;
  reverseProxy.enable = true;
  monitoring.enable = true;
};
```

### NAS Storage

Media and downloads are stored on the NAS VM via NFS:

```nix
homelab.media.storage = {
  nasAddress = "10.0.0.TBD";  # NAS VM IP
  mediaPath = "/data/media";
  downloadsPath = "/data/downloads";
};
```

## Deployment

### Prerequisites

1. NAS VM deployed with NFS exports for `/export/media` and `/export/downloads`
2. GPU passthrough configured on Proxmox host (see GPU section below)
3. SOPS secrets configured in `secrets/media/secrets.yaml`

### Build and Deploy

```bash
# Dry run to verify configuration
nix build --dry-run .#nixosConfigurations.media.config.system.build.toplevel

# Build VMA image for Proxmox
nixos-rebuild build-image --image-variant proxmox --flake .#media

# Transfer to Proxmox and restore
scp result/*.vma.zst root@proxmox:/var/lib/vz/dump/
qmrestore /var/lib/vz/dump/<file>.vma.zst <vmid> --storage local-zfs --force

# Configure VM resources
qm set <vmid> --cores 8 --memory 16384
qm set <vmid> --hostpci0 01:00,pcie=1  # GPU passthrough
qm set <vmid> --balloon 0              # Disable ballooning for GPU

# Deploy configuration updates
nixos-rebuild switch --target-host sandmhan@<media-ip> --flake .#media --sudo
```

### GPU Passthrough (1080 Ti)

#### Proxmox Host Setup

1. Enable IOMMU in BIOS
2. Update GRUB: `GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"`
3. Add kernel modules to `/etc/modules`:
   ```
   vfio
   vfio_iommu_type1
   vfio_pci
   vfio_virqfd
   ```
4. Blacklist nouveau: `echo "blacklist nouveau" > /etc/modprobe.d/blacklist-nouveau.conf`
5. Find GPU PCI IDs: `lspci -nn | grep -i nvidia`
6. Configure VFIO: `echo "options vfio-pci ids=XXXX:XXXX,XXXX:XXXX" > /etc/modprobe.d/vfio.conf`
7. Pass to VM: `qm set <vmid> --hostpci0 01:00,pcie=1`

#### NixOS VM Setup

After GPU passthrough is confirmed working, uncomment the NVIDIA driver configuration in `systemModules/media.nix`.

## Integration Patterns

### Sonarr/Radarr + Prowlarr

Prowlarr manages indexers centrally and syncs them to Sonarr and Radarr. After deployment:
1. Configure Prowlarr with indexer sources
2. Add Sonarr and Radarr as applications in Prowlarr settings
3. Prowlarr will automatically sync indexers to both services

### Sonarr/Radarr + Download Clients

1. In Sonarr/Radarr settings, add download clients:
   - qBittorrent: `http://localhost:8080` with credentials from sops
   - SABnzbd: `http://localhost:8085` with API key from sops
2. Configure media root folders pointing to NFS mounts

### Recyclarr + TRaSH Guides

After first deployment, edit `/var/lib/recyclarr/recyclarr.yml` to configure quality profiles for Sonarr and Radarr based on TRaSH Guides recommendations.

### Monitoring Integration

The node exporter on port 9100 is scraped by the monitoring stack. The media VM is registered in `systemModules/monitoring.nix` scrape targets.

## Secrets

Secrets are managed via sops-nix. Placeholder file: `secrets/media/secrets.yaml`

| Secret Key | Purpose |
|------------|---------|
| `media/jellyfin-api-key` | Jellyfin API key for external integrations |
| `media/sonarr-api-key` | Sonarr API key |
| `media/radarr-api-key` | Radarr API key |
| `media/prowlarr-api-key` | Prowlarr API key |
| `media/sabnzbd-api-key` | SABnzbd API key |
| `media/qbittorrent-password` | qBittorrent web UI password |

To encrypt with sops:
```bash
sops --encrypt --age $(cat /var/lib/sops-nix/key.txt | grep -oP 'public key: \K.*') secrets/media/secrets.yaml
```

## Network Configuration

| Resource | Address | Notes |
|----------|---------|-------|
| Media VM | 10.0.0.TBD | Not deployed — assign IP on 10.0.0.0/24 when deploying |
| NAS VM (NFS) | 10.0.0.TBD | Not deployed — assign IP on 10.0.0.0/24 when deploying |

## Troubleshooting

### NFS mounts not available

```bash
# Check mount status
mount | grep nfs
systemctl status data-media.mount
systemctl status data-downloads.mount

# Manually trigger automount
ls /data/media
ls /data/downloads

# Check NAS connectivity
ping 10.0.0.TBD
showmount -e 10.0.0.TBD
```

### Jellyfin not transcoding with GPU

```bash
# Verify GPU is visible
lspci | grep -i nvidia
nvidia-smi  # Should show 1080 Ti

# Check Jellyfin has GPU access
ls -la /dev/dri/
id jellyfin  # Should be in video and render groups

# Check Jellyfin logs
journalctl -u jellyfin -f
```

### *arr services not connecting to download clients

```bash
# Check service status
systemctl status sonarr radarr prowlarr sabnzbd
podman ps  # For qBittorrent container

# Check connectivity between services
curl http://localhost:8080  # qBittorrent
curl http://localhost:8085  # SABnzbd
curl http://localhost:8989  # Sonarr
curl http://localhost:7878  # Radarr
curl http://localhost:9696  # Prowlarr
```

### qBittorrent container issues

```bash
# Check container logs
podman logs qbittorrent

# Restart container
systemctl restart podman-qbittorrent

# Check container config
podman inspect qbittorrent
```

### Health check

The media-health-check systemd service runs hourly:

```bash
# Run manually
systemctl start media-health-check
journalctl -u media-health-check --no-pager
```
