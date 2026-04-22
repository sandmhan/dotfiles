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
- **Theme resolution**: Reads `~/.config/active-theme` at eval time for hot-swap, falls back to `gruvbox-dark-hard`
- **specialArgs**: User and system settings are passed to modules via `specialArgs`/`extraSpecialArgs`

### NixOS Configurations
- `gaia` — Primary desktop (Framework 13 AMD) at `hosts/gaia/`
- `initialProxmoxVMA` — Base image for creating new Proxmox VMs
- `proxmoxVM` — Generic Proxmox VM configuration
- `nvr` — Network Video Recorder VM (Frigate)
- `llama` — LLM inference server VM
- `matrix` — Matrix homeserver VM
- `agent-sandbox` — Autonomous agent development VM
- `agentVMA` — Agent VM Proxmox image

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
    ├── development.nix # claude code, containers, dev tools
    ├── theming.nix    # stylix, fonts, theme-switch script
    ├── wm.nix         # sway + waybar (large, own file)
    ├── nvf/           # neovim config (14 files)
    ├── claude/        # claude code skills, rules, assets
    └── claude-agent.nix # agent VM claude config

hosts/
├── gaia/              # Desktop (Framework 13 AMD)
├── server/            # Base template for Proxmox VMs
├── agent/             # Agent sandbox VM
├── llama/             # LLM inference VM
└── nvr/               # Network video recorder VM

systemModules/         # NixOS system services (frigate, jellyfin, matrix, llama)
themes/                # 58 curated base16 color schemes with polarity metadata
docs/                  # Documentation
```

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

## Code Conventions

- Format Nix files with `nixfmt` (or `nix fmt`)
- Use `lib.mkDefault` in profiles for easy overrides
- Use `lib.mkIf` to gate module config behind `myHome.*` options
- User settings flow through `userSettings` attribute set; system settings through `systemSettings`
- Home Manager modules conditionally include packages based on `pkgs.stdenv.isLinux` vs Darwin
- Stylix handles theming consistently across NixOS (system-level) and Home Manager (user-level)
