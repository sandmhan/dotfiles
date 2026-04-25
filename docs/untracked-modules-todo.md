# Module Implementation Status

All systemModules now evaluate cleanly via `nix build --dry-run`. **None have been deployed yet.** Deployment requires completing SOPS secrets setup, creating DHCP reservations, and provisioning VMs/LXCs on Proxmox.

## Completed — Configuration Only (NOT Deployed)

### Forgejo (`systemModules/forgejo.nix`)
- [x] Fixed removed `servicePackages.forgejoUtils` reference — inlined `[ pkgs.postgresql ]`
- [x] Removed dead `homelab.sops` block from `hosts/git/default.nix`
- [x] Added sops hostname mappings for `git` and `lxc-git`
- [x] Added node exporter for Prometheus monitoring
- [x] Dry-run build passes for `.#git`

### Home Assistant (`systemModules/homeassistant.nix`)
- [x] Fixed removed `servicePackages.homeassistant` / `homeassistantUtils` — inlined packages
- [x] Fixed `unit_system` from "imperial" to "us_customary"
- [x] Fixed `hass` user assertion (isSystemUser)
- [x] Removed dead `homelab.sops` blocks from VM and LXC host configs
- [x] Added sops hostname mappings for `homeassistant` and `lxc-homeassistant`
- [x] Dry-run build passes for `.#homeassistant` and `.#lxc-homeassistant`

### Matrix Agent Bridge (`systemModules/matrix-agent-bridge.nix`)
- [x] Fixed removed `servicePackages.matrixBot` — uses existing `pythonEnv`
- [x] Module integrated into matrix flake config
- [x] Dry-run build passes for `.#matrix`

### Frigate NVR (`systemModules/frigate.nix`)
- [x] Refactored from hardcoded cameras to option-based `homelab.frigate.cameras` attrset
- [x] Added MQTT, AI detector, NFS storage, recording options
- [x] Rewrote `hosts/nvr/default.nix`, deleted `hosts/nvr/frigate.nix`
- [x] Fixed flake entry to use `hosts/server` base instead of `hosts/proxmox-base`
- [x] Dry-run build passes for `.#nvr`

### Media / *arr Stack (`systemModules/media.nix`)
- [x] New module: Jellyfin, Sonarr, Radarr, Prowlarr, SABnzbd (native NixOS services)
- [x] qBittorrent and Recyclarr via OCI containers (podman)
- [x] Nginx reverse proxy, NFS mount units, GPU passthrough placeholders
- [x] Host config at `hosts/media/default.nix`
- [x] Dry-run build passes for `.#media`

### Fitness / wger (`systemModules/wger.nix`)
- [x] New module: OCI containers for wger Django, PostgreSQL, Redis, Celery worker
- [x] Nginx reverse proxy, Prometheus metrics endpoint
- [x] Host config at `hosts/fitness/default.nix`
- [x] Dry-run build passes for `.#fitness`

### Gaming / Sunshine (`systemModules/sunshine-server.nix`)
- [x] New module: Headless Sunshine streaming server with NVIDIA GPU passthrough
- [x] Virtual display (Xorg dummy), PipeWire audio, systemd service
- [x] Host config at `hosts/gaming/default.nix`
- [x] Dry-run build passes for `.#gaming`

---

## Pre-Deployment Blockers (applies to all services above)

These must be completed before any service can be deployed:

- [ ] **SOPS secrets setup**: Encrypt all `secrets/*/secrets.yaml` files with age keys. Currently plaintext placeholders.
- [ ] **DHCP reservations**: All `10.0.20.*` IPs are provisional — create reservations on Protectli router
- [ ] **VM/LXC provisioning**: Create VMs from VMA images or LXC containers on Proxmox
- [ ] **VLAN 20 setup**: Services VLAN not yet configured on Cisco 3750G switch
- [ ] **DNS**: No internal DNS for `*.homelab.local` domains yet

### Per-Service Pre-Deployment Notes

| Service | Additional Prerequisites |
|---------|------------------------|
| **Forgejo** | None beyond common blockers |
| **Home Assistant** | USB dongles need physical connection + Proxmox passthrough (`qm set --usb`) |
| **Matrix Agent Bridge** | Bot user must be registered on Synapse, access token generated |
| **Frigate NVR** | Camera RTSP URLs must be updated with real credentials |
| **Media** | NAS must be deployed first (NFS mounts); GPU PCI IDs need discovery on Gaming PC |
| **Fitness** | None beyond common blockers |
| **Gaming** | Gaming PC must be repurposed as Proxmox node; GPU PCI IDs need discovery |
