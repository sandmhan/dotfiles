# Gaming VM (Sunshine Remote Streaming) Setup Guide

## Overview

The Gaming VM provides headless game streaming via Sunshine server with GPU passthrough, allowing Moonlight clients on any device to play PC games remotely. This is a Phase 4 deployment (lowest priority) designed for a dedicated gaming GPU (RTX 3060 or GTX 1080 Ti) passed through to a Proxmox VM.

## Features

- **Sunshine Server**: Headless game streaming server (Moonlight-compatible)
- **GPU Passthrough**: Dedicated NVIDIA GPU via VFIO/PCI passthrough
- **Virtual Display**: Xorg with virtual framebuffer for headless operation
- **PipeWire Audio**: Low-latency audio capture for streaming
- **NVIDIA Hardware Encoding**: NVENC for efficient video encoding
- **Looking Glass**: Optional local + remote simultaneous display (future)
- **Monitoring Integration**: Node exporter for Prometheus metrics

## Architecture

```
                              Proxmox Host (Dell PowerEdge / Gaming PC)
                              +-------------------------------------------+
                              |                                           |
                              |  +---------+  PCI Passthrough  +--------+ |
 Moonlight Clients            |  |  GPU    |=================>| Gaming | |
 +------------------+         |  | RTX 3060|                  |  VM    | |
 | Phone / Tablet   |<------->|  +---------+                  | (108)  | |
 | PC / TV          | Stream  |                               |        | |
 | Steam Deck       | (UDP)   |  Sunshine Server (:47984-90)  | 6 core | |
 +------------------+         |  PipeWire Audio                | 12GB   | |
                              |  Virtual Display (Xorg)        | 200GB  | |
                              +-------------------------------------------+
```

## Prerequisites

### 1. Hardware Requirements

- Dedicated GPU (not shared with AI/compute workloads)
  - Recommended: NVIDIA RTX 3060 or GTX 1080 Ti
  - Must support NVENC hardware encoding
- Proxmox host with IOMMU support enabled in BIOS
- VM: 6 cores, 12GB RAM, 200GB disk (VM ID 108)

### 2. Proxmox Host Configuration

Enable IOMMU on the Proxmox host:

```bash
# Edit GRUB config on Proxmox host
# For Intel CPU:
#   GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"
# For AMD CPU:
#   GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt"

# Verify IOMMU groups
find /sys/kernel/iommu_groups/ -type l | sort -V

# Find GPU PCI IDs
lspci -nn | grep -i nvidia
# Example: 01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA106 [10de:2504]
# Example: 01:00.1 Audio device [0403]: NVIDIA Corporation GA106 [10de:228e]
```

### 3. GPU Passthrough Setup

```bash
# On Proxmox host, blacklist GPU from host
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
echo "options vfio-pci ids=10de:2504,10de:228e" >> /etc/modprobe.d/vfio.conf

# Load VFIO modules
echo "vfio" >> /etc/modules
echo "vfio_iommu_type1" >> /etc/modules
echo "vfio_pci" >> /etc/modules

# Update initramfs
update-initramfs -u

# Reboot Proxmox host

# Assign GPU to VM
qm set 108 --hostpci0 01:00.0,pcie=1,x-vga=1
```

### 4. Secrets Configuration

```bash
# Create secrets file with sops
sops secrets/gaming/secrets.yaml

# Required secrets:
# sunshine-username: admin
# sunshine-password: <secure-password>
```

### 5. VM Creation

```bash
# Create VM on Proxmox (or restore from VMA image)
qm create 108 --name gaming --cores 6 --memory 12288 --balloon 0
qm set 108 --cpu host  # CPU passthrough for performance
qm set 108 --hostpci0 01:00.0,pcie=1,x-vga=1  # GPU passthrough

# Deploy NixOS configuration
nixos-rebuild switch --target-host sandmhan@10.0.0.TBD --flake .#gaming --sudo
```

## Configuration

### Module Options

| Option | Default | Description |
|--------|---------|-------------|
| `homelab.sunshine.enable` | false | Enable Sunshine server |
| `homelab.sunshine.deploymentType` | "vm" | Deployment type |
| `homelab.sunshine.resourceProfile` | "high" | Resource profile |
| `homelab.sunshine.gpu.pciId` | "0000:01:00.0" | GPU PCI bus ID |
| `homelab.sunshine.gpu.driver` | "nvidia" | GPU driver type |
| `homelab.sunshine.gpu.model` | "RTX 3060" | GPU model description |
| `homelab.sunshine.display.resolution` | "1920x1080" | Virtual display resolution |
| `homelab.sunshine.display.refreshRate` | 60 | Refresh rate (Hz) |
| `homelab.sunshine.audio.backend` | "pipewire" | Audio backend |
| `homelab.sunshine.network.controlPort` | 47989 | Sunshine control port |
| `homelab.sunshine.network.videoPort` | 47984 | Video streaming port |
| `homelab.sunshine.network.upnp` | false | UPnP port forwarding |

### Network Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 47984 | TCP/UDP | Video streaming |
| 47989 | TCP | Control / API |
| 47990 | TCP | Web UI (HTTPS) |
| 47998-48010 | UDP | Audio, control, and data channels |
| 9100 | TCP | Prometheus node exporter |

## Deployment

### Build (dry-run validation)

```bash
nix build --dry-run .#nixosConfigurations.gaming.config.system.build.toplevel
```

### Deploy

```bash
nixos-rebuild switch --target-host sandmhan@10.0.0.TBD --flake .#gaming --sudo
```

## Client Setup (Moonlight)

1. Install Moonlight on client device (phone, tablet, PC, Steam Deck)
2. Open Moonlight and add host: `10.0.0.TBD` (or gaming VM IP)
3. First connection requires pairing via Sunshine web UI:
   - Open `https://10.0.0.TBD:47990` in a browser
   - Log in with configured credentials
   - Accept the pairing request from Moonlight
4. Select applications to stream

## Troubleshooting

### GPU Not Detected

```bash
# Check if GPU is passed through
lspci | grep -i nvidia

# Verify NVIDIA driver loaded
nvidia-smi

# Check IOMMU groups (on Proxmox host)
dmesg | grep -i iommu
```

### Sunshine Not Starting

```bash
# Check service status
systemctl status sunshine

# View logs
journalctl -u sunshine -f

# Verify display
echo $DISPLAY
xdpyinfo | head -20
```

### No Audio in Stream

```bash
# Check PipeWire status
systemctl --user status pipewire
pw-cli list-objects | grep -i sink

# Check system-level PipeWire
systemctl status pipewire
```

### High Latency

- Ensure client and server are on the same VLAN/subnet
- Check that NVENC hardware encoding is being used (not software encoding)
- Reduce resolution or refresh rate in Sunshine settings
- Verify network bandwidth (minimum 50 Mbps recommended for 1080p60)

### Looking Glass Setup (Future)

For simultaneous local and remote display:
```bash
# On Proxmox host, add shared memory device
qm set 108 --args '-device ivshmem-plain,memdev=ivshmem,bus=pci.0 -object memory-backend-file,id=ivshmem,share=on,mem-path=/dev/shm/looking-glass,size=128M'
```

## Integration

### Monitoring

The gaming VM exports metrics on port 9100 (node exporter). The monitoring stack at `10.0.0.10` scrapes this target automatically via the `gaming` entry in `systemModules/monitoring.nix`.

### Secrets

Sunshine credentials are managed via SOPS in `secrets/gaming/secrets.yaml`.

## Files

| File | Purpose |
|------|---------|
| `systemModules/sunshine-server.nix` | System module with all Sunshine configuration |
| `hosts/gaming/default.nix` | VM host configuration |
| `secrets/gaming/secrets.yaml` | SOPS-encrypted credentials |
| `home/modules/sunshine.nix` | Home Manager module (desktop use, separate) |
