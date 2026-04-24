# Infrastructure Registry

Single source of truth for all deployed and planned infrastructure. **Update this file in the same commit as any host change.**

## Proxmox Nodes

| Node | Hardware | CPU | RAM | Storage | Status |
|------|----------|-----|-----|---------|--------|
| Dell Laptop | Dell Latitude | i7-3520M (2C/4T) | 15GB | 500GB HDD | `deployed` |
| Gaming PC | Custom | i7-10700K (8C/16T) | 32GB | 1TB + 500GB SSD | `not yet repurposed` |

## NixOS Hosts

| Hostname | Flake Output | VM/CT ID | Type | Node | IP Address | Cores | RAM | Disk | GPU | Services | SSH User | Status | Notes |
|----------|-------------|----------|------|------|-----------|-------|-----|------|-----|----------|----------|--------|-------|
| gaia | `nixosConfigurations.gaia` | — | Bare metal | Framework laptop | — | 8 | 16GB | 500GB | — | Desktop environment | sandmhan | `deployed` | Primary workstation, Framework 13 AMD |
| agent-sandbox | `nixosConfigurations.agent-sandbox` | 105 | VM | Dell | 10.0.0.163 | 4 | 8GB | 24GB | — | Claude Code autonomous agent | agent | `deployed` | `--dangerously-accept-permissions` sandbox |
| — | `nixosConfigurations.initialProxmoxVMA` | — | VMA template | — | — | — | — | — | — | Base image for new VMs | sandmhan | `template` | Build with `nixos-rebuild build-image` |
| — | `nixosConfigurations.proxmoxVM` | — | VM template | — | — | — | — | — | — | Generic Proxmox VM | sandmhan | `template` | Uses `hosts/server` |
| nvr | `nixosConfigurations.nvr` | — | VM | — | — | — | — | — | — | Frigate NVR | sandmhan | `planned` | Phase 3, needs camera config |
| llama | `nixosConfigurations.llama` | — | VM | — | — | — | — | — | RTX 3060 | llama.cpp inference | sandmhan | `planned` | Phase 3, needs GPU passthrough |
| matrix | `nixosConfigurations.matrix` | — | VM | — | — | — | — | — | — | Synapse + Coturn | sandmhan | `planned` | Phase 2, needs DNS + ACME |
| nixos-builder | `nixosConfigurations.nixos-builder` | 200 | VM | Dell | — | 6 | 12GB | 100GB | — | Nix build orchestration | sandmhan | `deployed` | Autonomous build server |
| lxc-matrix | `nixosConfigurations.lxc-matrix` | — | LXC | Dell | — | 0.5 | 1GB | 20GB | — | Synapse + PostgreSQL | matrix | `planned` | LXC alternative to VM |
| lxc-monitor | `nixosConfigurations.lxc-monitor` | — | LXC | Dell | — | 0.5 | 1GB | 10GB | — | Prometheus + Grafana | monitor | `planned` | Phase 1b |
| lxc-git | `nixosConfigurations.lxc-git` | — | LXC | Dell | — | 0.3 | 512MB | 15GB | — | Forgejo | git | `planned` | Phase 2b |
| lxc-nas | `nixosConfigurations.lxc-nas` | — | LXC | Dell | — | 0.5 | 1GB | 20GB | — | NFS/Samba | nas | `planned` | Phase 1c |

## Network

| VLAN | Subnet | Purpose |
|------|--------|---------|
| 1 | 10.0.0.0/24 | Management / trusted devices |
| 10 | 10.0.10.0/24 | IoT devices (cameras, smart home) |
| 20 | 10.0.20.0/24 | Homelab services (VMs/containers) |
| 30 | 10.0.30.0/24 | Guest network |

## Update Log

| Date | Change | Commit |
|------|--------|--------|
| 2026-04-23 | Initial registry created from flake.nix inventory | — |
| 2026-04-23 | Updated agent-sandbox IP to 10.0.0.163, deployed latest config | — |
| 2026-04-23 | Marked nixos-builder as deployed, updated roadmap for incremental config development approach | — |
