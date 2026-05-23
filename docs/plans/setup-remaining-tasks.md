# Remaining Setup Tasks for Homelab Infrastructure

## Overview

This document tracks remaining homelab setup work. Remote access is no longer blocked on a WireGuard deployment: the `vpn` host is deployed as a Tailscale subnet router. WireGuard is retained/planned for optional service-specific use only.

Canonical deployment status, VM IDs, and IPs live in `docs/architecture/infrastructure-registry.md`.

## Priority Tasks

### 1. Complete sops-nix Secrets Integration

#### 1.1 Verify Host Age Keys

For each host that needs secrets access:

```bash
# Derive an age recipient from the host SSH key
ssh user@host 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age

# Or inspect a generated sops-nix age key on the host
ssh user@host 'sudo age-keygen -y /var/lib/sops-nix/key.txt'
```

Update `.sops.yaml` with real recipients for hosts that still have placeholders.

#### 1.2 Add Creation Rules for Service Secret Files

`systemModules/sops.nix` already routes these hostnames to service-specific files:

- `git` and `lxc-git` → `secrets/forgejo/secrets.yaml`
- `homeassistant` and `lxc-homeassistant` → `secrets/homeassistant/secrets.yaml`
- `media` → `secrets/media/secrets.yaml`
- `gaming` → `secrets/gaming/secrets.yaml`
- `manga` → `secrets/manga/secrets.yaml`

Before deploying those services, add corresponding `.sops.yaml` creation rules and re-encrypt/update keys:

```bash
sops updatekeys secrets/<service>/secrets.yaml
```

Do not commit decrypted secret contents.

#### 1.3 Populate Secret Files

Known service secret files include:

- `secrets/matrix/secrets.yaml`
- `secrets/monitoring/secrets.yaml`
- `secrets/tailscale/secrets.yaml`
- `secrets/wireguard/secrets.yaml` (optional/planned WireGuard)
- `secrets/fitness/secrets.yaml`
- `secrets/forgejo/secrets.yaml`
- `secrets/homeassistant/secrets.yaml`
- `secrets/media/secrets.yaml`
- `secrets/gaming/secrets.yaml`

`secrets/manga/secrets.yaml` is referenced by the runtime mapping but is not currently present; create it only when the manga host/output is added.

### 2. Remote Access Status

Tailscale is the current remote-access path.

```bash
# Deployed router status
ssh sandmhan@100.120.234.19 'tailscale status'

# Deploy/update the router configuration if needed
nixos-rebuild switch --target-host sandmhan@100.120.234.19 --flake .#vpn --sudo
```

Remaining remote-access work:

- [ ] Keep `secrets/tailscale/secrets.yaml` recipients current.
- [ ] Confirm advertised routes in the Tailscale admin console after router changes.
- [ ] Optionally implement WireGuard for service-specific or fallback access.

WireGuard setup is not a blocker for remote management.

### 3. Build Additional Service Configurations

#### Monitoring Stack

`lxc-monitor` is deployed. The `monitor` VM output exists but should be treated as planned unless Proxmox confirms it is live.

```bash
nix build --dry-run .#nixosConfigurations.lxc-monitor.config.system.build.toplevel
```

#### NAS Configuration

```bash
nix build --dry-run .#nixosConfigurations.lxc-nas.config.system.build.toplevel
```

#### Git Server

Forgejo host and LXC outputs exist. Ensure `secrets/forgejo/secrets.yaml` is covered by `.sops.yaml` creation rules before deployment.

```bash
nix build --dry-run .#nixosConfigurations.git.config.system.build.toplevel
nix build --dry-run .#nixosConfigurations.lxc-git.config.system.build.toplevel
```

#### Matrix Agent Control Plane

Matrix is deployed and includes the agent bridge module. Keep bridge tokens in `secrets/matrix/secrets.yaml`.

### 4. Network Infrastructure Setup

All services currently run on the flat `10.0.0.0/24` network. VLAN segmentation remains future work after core services are stable.

DNS/internal naming remains a follow-up item; use current IPs from `docs/architecture/infrastructure-registry.md` until DNS is deployed.

### 5. Service Deployment Strategy

#### Deployed / active

- `matrix`
- `fitness`
- `vpn` (Tailscale router)
- `lxc-monitor`
- `nixos-builder`
- `agent-sandbox`

#### Ready/planned outputs

- `git`, `lxc-git`
- `homeassistant`, `lxc-homeassistant`
- `media`
- `nas`, `lxc-nas`
- `nvr`
- `llama`
- `gaming`
- `monitor` VM

### 6. Documentation and Maintenance

- Update `docs/architecture/infrastructure-registry.md` with any actual deployment, IP, or VM ID change.
- Validate affected flake outputs with `nix build --dry-run` before deploying.
- Keep SOPS creation rules and `systemModules/sops.nix` runtime mappings in sync.
- Document operational procedures for Tailscale, service secrets, monitoring, backups, and recovery.

## Success Metrics

- [x] **Remote access**: Tailscale subnet router deployed for homelab access.
- [ ] **Secrets Management**: All service files have matching `.sops.yaml` creation rules and valid recipients.
- [x] **Monitoring base**: `lxc-monitor` deployed.
- [ ] **Autonomous Operations**: NixOS Builder + Matrix bot workflows validated end-to-end.
- [ ] **Documentation**: Registry and runbooks kept current with deployments.
- [ ] **Backup/Recovery**: Disaster recovery procedures validated.

## Next Immediate Actions

1. Add missing `.sops.yaml` creation rules for Forgejo, Home Assistant, media, gaming, and manga when ready to manage those service files.
2. Run `sops updatekeys secrets/<service>/secrets.yaml` after adding each rule.
3. Validate planned service outputs with `nix build --dry-run` before Proxmox deployment.
4. Keep Tailscale router routes and secrets current.
