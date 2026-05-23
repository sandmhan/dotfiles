# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Nix flake-based configuration repository managing NixOS systems and Home Manager user environments. It supports a personal desktop (Framework laptop — Gaia), a Proxmox-based homelab with VMs for services like Frigate, Jellyfin, and Matrix, and an autonomous agent sandbox VM.

## Common Commands

```bash
# Home Manager configurations
make sandmhan      # Linux desktop (full GUI environment — daily driver)
make macman        # macOS (terminal-focused)
make wslman        # WSL (terminal-focused)
make terminalman   # Linux terminal-only (headless/server)

# NixOS system configurations
make gaia          # Rebuild NixOS system configuration
make full          # Full rebuild (NixOS + Home Manager)

# Maintenance
make update        # Update flake inputs
make clean         # Garbage collect old generations
nix fmt            # Format all Nix files

# Theme switching
theme-switch       # Rofi picker to hot-swap Stylix color scheme

# Proxmox homelab management
nixos-rebuild build-image --image-variant proxmox --flake .#initialProxmoxVMA
nixos-rebuild switch --target-host sandmhan@<host> --flake .#<config> --sudo
```

## Architecture

### Flake Structure (`flake.nix`)
- **Inputs**: nixpkgs (unstable), nixos-hardware, home-manager, stylix (theming), nvf (Neovim)
- **Helpers**: `mkNixosSystem` (VM configs), `mkHomeConfiguration` (HM configs)
- **Settings**: `baseUserSettings`, `linuxUserSettings`, `macUserSettings` define shared config; `systemSettings` for NixOS-specific options
- **Theme resolution**: Build-time default is statically set to `gruvbox-dark-hard`; `theme-switch` writes `~/.config/active-theme` and triggers Home Manager activation for runtime changes
- **specialArgs**: User and system settings are passed to modules via `specialArgs`/`extraSpecialArgs`

### NixOS Configurations
- `gaia` — Primary desktop (Framework 13 AMD) at `hosts/gaia/`
- `initialProxmoxVMA` — Base image for creating new Proxmox VMs
- `proxmoxVM` — Generic Proxmox VM configuration
- `nvr` — Network Video Recorder VM (Frigate)
- `llama` — LLM inference server VM
- `matrix` — Matrix homeserver VM
- `git` — Forgejo Git server
- `fitness` — wger fitness tracking
- `homeassistant` — Home Assistant smart-home automation
- `media` — Jellyfin + *arr media stack
- `vpn` — Tailscale subnet router
- `monitor` — Prometheus + Grafana monitoring stack
- `nas` — NFS/Samba storage services
- `nixos-builder` — Dedicated NixOS builder VM
- `agent-sandbox` — Autonomous agent development VM
- `agentVMA` — Agent VM Proxmox image (50GB disk)
- `gaming` — Sunshine remote gaming VM
- `initialLXC` — Proxmox LXC base tarball
- `lxc-matrix`, `lxc-monitor`, `lxc-git`, `lxc-homeassistant`, `lxc-nas` — LXC service containers

### Home Manager Configurations
- `sandmhan` — Linux desktop with full GUI environment (x86_64-linux) — **daily driver**
- `macman` — macOS terminal-focused configuration (aarch64-darwin)
- `wslman` — WSL terminal-focused configuration (x86_64-linux)
- `terminalman` — Linux terminal-only for headless systems (x86_64-linux)

### Directory Structure

```
home/
├── options.nix        # What CAN be configured (option declarations)
├── profiles/          # WHO configures what (machine-specific option values)
│   ├── desktop.nix    # Gaia/sandmhan — full desktop
│   ├── terminal.nix   # Headless/server base profile
│   ├── macos.nix      # macOS
│   └── wsl.nix        # WSL
└── modules/           # HOW options are realized (the actual configs)
    ├── core.nix       # git, home-manager, nixpkgs config
    ├── terminal.nix   # tmux, bash, alacritty, shell tools
    ├── desktop.nix    # rofi, swaylock, bluetooth, browser, moonlight/sunshine
    ├── development.nix # dev packages, imports ai-*.nix modules
    ├── theming.nix    # stylix, fonts, theme-switch script
    ├── wm.nix         # sway + waybar (large, own file)
    ├── nvf/           # neovim config (14 files)
    ├── ai/            # provider-agnostic AI skills, rules, assets
    │   ├── skills/    # shared skills (SKILL.md + references/)
    │   ├── rules/     # shared rules (markdown)
    │   ├── assets/    # templates (envrc, flake starters)
    │   ├── agent-skills/  # agent-only skills
    │   └── agent-rules/   # agent-only rules
    ├── claude/        # Claude-specific agent personality files only
    │   └── agents/
    ├── ai-skills.nix  # shared data module (myHome.ai.skills, myHome.ai.rules)
    ├── ai-claude.nix  # Claude Code provider config
    ├── ai-codex.nix   # Codex provider config
    └── ai-agent.nix   # agent VM overlay (autonomous mode for all providers)

hosts/
├── gaia/              # Desktop (Framework 13 AMD)
├── server/            # Base template for Proxmox VMs
├── agent/             # Agent sandbox VM
├── llama/             # LLM inference VM
├── media/, git/, vpn/ # Homelab service VMs
├── lxc-*/             # LXC service containers
└── nvr/               # Network video recorder VM

systemModules/         # NixOS services: forgejo, frigate, homeassistant, jellyfin,
                       # llama, manga, matrix(+agent bridge), media, monitoring,
                       # nas, sops, sunshine-server, tailscale, wger, wireguard
themes/                # 58 curated base16 color schemes with polarity metadata
docs/                  # Documentation
```

### AI Tools Architecture
- Provider-agnostic skills and rules live in `home/modules/ai/`
- `ai-skills.nix` exposes them via `myHome.ai.skills` and `myHome.ai.rules` options
- Each tool has a dedicated module (`ai-claude.nix`, `ai-codex.nix`) that maps shared data to the tool's native config format
- Agent-specific skills overlay via `ai-agent.nix` for autonomous VM operation
- Canonical discovery directory at `~/.local/share/ai/` (env var `AI_SKILLS_DIR`) for non-Nix tools
- To add a new AI tool: create `ai-<tool>.nix` that reads `config.myHome.ai.*`, add `enable<Tool>` option, import in `development.nix`

### Theme System
- 58 base16 color schemes in `themes/<name>/` with YAML, polarity, wallpaper URL, and SHA256
- Stylix sources schemes from local `themes/` directory (not nixpkgs)
- `theme-switch` script opens Rofi picker, writes selection to `~/.config/active-theme`, runs `home-manager switch`
- Sway keybinding: `$mod+Shift+T` to open theme picker
- Polarity (dark/light) automatically applied per theme

### Homelab VM Workflow
1. Build VMA image: `nixos-rebuild build-image --image-variant proxmox --flake .#initialProxmoxVMA`
2. Transfer `.vma.zst` to Proxmox host
3. Restore: `qmrestore /var/lib/vz/dump/<file>.vma.zst <VM_ID> --storage local-zfs --force`
4. Adjust resources: `qm set <vmid> --cores <n>` or `--memory <mb>`
5. Push config: `nixos-rebuild switch --target-host sandmhan@<ip> --flake .#<config> --sudo`

## Proxmox Safety Rules

These rules exist because an autonomous agent crashed the Dell Proxmox node on 2026-04-24 by spamming `qm` commands without backoff, triggering an Intel NIC hardware hang that required a physical power cycle.

- **Never run VM lifecycle commands (`qm stop`, `qm start`, `qm reboot`) in a loop.** Wait at least 60 seconds between attempts. Maximum 3 retries, then stop and report the failure.
- **Never spam `qm guest exec` or QMP guest-ping commands.** If the QEMU guest agent is not responding, the fix is inside the VM's NixOS config (enable `services.qemuGuest`), not repeated polling from the host.
- **Do not modify GRUB or boot configuration to troubleshoot guest agent issues.** The QEMU guest agent is a userspace service, not a boot-level concern.
- **Do not modify keyboard, HID, or peripheral configurations on Proxmox hosts.** These are physical hardware concerns, not VM configuration concerns.
- **Rate limit all Proxmox API/CLI operations.** No more than 1 VM lifecycle operation per 60 seconds. No more than 1 QMP query per 30 seconds.
- **If a VM won't start or respond after 3 attempts, stop and ask the user.** Do not continue retrying. The Dell node has limited resources (i7-3520M, 15GB RAM) and is fragile under sustained load.
- **Never run `nixos-rebuild switch --target-host` against the Proxmox host itself.** Only target NixOS VMs.

## Code Conventions

- Format Nix files with `nixfmt` (or `nix fmt`)
- Use `lib.mkDefault` in profiles for easy overrides
- Use `lib.mkIf` to gate module config behind `myHome.*` options
- User settings flow through `userSettings` attribute set; system settings through `systemSettings`
- Home Manager modules conditionally include packages based on `pkgs.stdenv.isLinux` vs Darwin
- Stylix handles theming consistently across NixOS (system-level) and Home Manager (user-level)
