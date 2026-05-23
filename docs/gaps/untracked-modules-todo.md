# Module Implementation Status

All systemModules evaluate cleanly via `nix build --dry-run`. **One service (Fitness/wger) has been deployed** as a test instance. All others remain configuration-only.

## Deployed

### Fitness / wger (`systemModules/wger.nix`)
- [x] OCI containers for wger Django, PostgreSQL, Redis, Celery worker
- [x] Nginx reverse proxy, Prometheus node exporter
- [x] SOPS secrets encrypted and decrypted on VM (`/run/secrets/wger/`)
- [x] **Deployed to VM 106** on Dell Proxmox node at `10.0.0.167`
- [x] Web UI accessible at `http://10.0.0.167/` (login: `admin` / `adminadmin`)
- [x] All 4 containers running, API responding, Celery connected to Redis
- **Deployment fixes applied during testing:**
  - Resized VM disk from 4.5G to 15G (VMA base image too small for container images)
  - Fixed SOPS secret YAML structure (flat keys to nested `wger:` object)
  - Added `DJANGO_CACHE_CLIENT_CLASS` env var to fix Redis cache error
  - Changed container port mapping from `8000:80` to `8000:8000`
  - Fixed celery command path (`/home/wger/.local/bin/celery -A wger worker`)
  - Opened firewall ports 8000/9100 for management VLAN access
- **Known limitations (test instance):**
  - Running on flat network (10.0.0.0/24), no DHCP reservation
  - Django running in dev mode (runserver, not gunicorn)
  - SOPS secrets decrypted to files but not yet injected as container env vars (containers use hardcoded test values)
  - No DNS (`.homelab.local`) setup yet

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

### Gaming / Sunshine (`systemModules/sunshine-server.nix`)
- [x] New module: Headless Sunshine streaming server with NVIDIA GPU passthrough
- [x] Virtual display (Xorg dummy), PipeWire audio, systemd service
- [x] Host config at `hosts/gaming/default.nix`
- [x] Dry-run build passes for `.#gaming`

---

## Pre-Deployment Blockers (applies to all services above)

These must be completed before any service can be deployed:

- [ ] **SOPS secrets setup**: Encrypt all `secrets/*/secrets.yaml` files with age keys. Currently plaintext placeholders.
- [ ] **DHCP reservations**: Undeployed services need static IPs on the `10.0.0.0/24` network — create reservations on Protectli router when deploying
- [ ] **VM/LXC provisioning**: Create VMs from VMA images or LXC containers on Proxmox
- [ ] **DNS**: No internal DNS for `*.homelab.local` domains yet
- [ ] **VLAN setup (future)**: Services VLAN not yet configured on Cisco 3750G switch — planned but deferred

### Per-Service Pre-Deployment Notes

| Service | Additional Prerequisites |
|---------|------------------------|
| **Forgejo** | None beyond common blockers |
| **Home Assistant** | USB dongles need physical connection + Proxmox passthrough (`qm set --usb`) |
| **Matrix Agent Bridge** | Bot user must be registered on Synapse, access token generated |
| **Frigate NVR** | Camera RTSP URLs must be updated with real credentials |
| **Media** | NAS must be deployed first (NFS mounts); GPU PCI IDs need discovery on Gaming PC |
| **Fitness** | **DEPLOYED** — test instance at 10.0.0.167. Production deployment needs DHCP reservation and real secrets injected into container env vars |
| **Gaming** | Gaming PC must be repurposed as Proxmox node; GPU PCI IDs need discovery |
