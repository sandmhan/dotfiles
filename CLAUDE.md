# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Nix flake-based configuration repository managing NixOS systems and Home Manager user environments. It supports both a personal desktop (Framework laptop) and a Proxmox-based homelab with VMs for services like Frigate, Jellyfin, and Matrix.

## Common Commands

```bash
# Home Manager configurations
make sandmhan      # Linux desktop (full GUI environment)
make macman        # macOS (terminal-focused)
make wslman        # WSL (terminal-focused)
make terminalman   # Linux terminal-only (headless/server)

# NixOS system configurations
make gaia          # Rebuild NixOS system configuration
make full          # Full rebuild (NixOS + Home Manager)

# Maintenance
make update        # Update flake inputs
make clean         # Garbage collect old generations

# Proxmox homelab management
nixos-rebuild build-image --image-variant proxmox --flake .#initialProxmoxVMA
nixos-rebuild switch --target-host sandmhan@<host> --flake .#<config> --sudo
```

## Architecture

### Flake Structure (`flake.nix`)
- **Inputs**: nixpkgs (unstable), nixos-hardware, home-manager, stylix (theming), nixvim, nvf (Neovim)
- **Settings**: `baseUserSettings`, `linuxUserSettings`, `macUserSettings` define shared config; `systemSettings` for NixOS-specific options
- **specialArgs**: User and system settings are passed to modules via `specialArgs`/`extraSpecialArgs`

### NixOS Configurations
- `gaia` - Primary desktop (Framework 13 AMD), uses `configuration.nix` + hardware module + stylix
- `initialProxmoxVMA` - Base image for creating new Proxmox VMs
- `proxmoxVM` - Generic Proxmox VM configuration
- `nvr` - Network Video Recorder VM (Frigate)

### Home Manager Configurations
- `sandmhan` - Linux desktop with full GUI environment (x86_64-linux)
- `macman` - macOS terminal-focused configuration (aarch64-darwin)
- `wslman` - WSL terminal-focused configuration (x86_64-linux)
- `terminalman` - Linux terminal-only for headless systems (x86_64-linux)

### Module Organization

#### Legacy Structure
- `homeModules/` - Original user environment modules (maintained for compatibility)
  - Individual modules: terminal, browser, git, wm, stylix, nvf, rofi, login, bluetooth, claude
- `homeModules/nvf/` - Modular Neovim configuration via nvf:
  - `default.nix` - Entry point, imports all nvf modules
  - `options.nix` - Editor options (clipboard, line numbers, tabs)
  - `keymaps.nix` - Key mappings and leader key
  - `visuals.nix` - Visual plugins (devicons, cursorline, bufferline)
  - `lsp.nix` - LSP servers (clangd, nixd, tinymist, marksman)
  - `languages.nix` - Language configs (nix, typst, clang)
  - `completion.nix` - Autocomplete (blink-cmp)
  - `treesitter.nix` - Treesitter grammars
  - `utility.nix` - Utility plugins (mini.files, flash-nvim, whichKey)
- `homeModules/claude/` - Claude Code configuration:
  - `skills/` - Custom skills (nix-flake development)
  - `rules/` - Project rules (nix-conventions, homelab)

#### New Option-Based Profile System
- `home/options.nix` - Comprehensive option definitions using `lib.mkEnableOption` and `lib.mkOption`
- `home/profiles/` - Composable configuration profiles that set options:
  - `terminal.nix` - Base terminal-focused profile (git, nvim, tmux, shell tools)
  - `desktop.nix` - Full desktop profile (extends terminal + GUI apps)
  - `macos.nix` - macOS-optimized terminal configuration
  - `wsl.nix` - WSL-optimized configuration with container tools
  - `README.md` - Documentation for creating custom profiles
- `home/implementations/` - Implementation modules that respond to options:
  - `core.nix` - Essential modules (git, home-manager, nixpkgs config)
  - `terminal.nix` - Terminal tools (shell, tmux, nvim, terminal utilities)
  - `development.nix` - Development tools (claude, containers, virtualization)
  - `theming.nix` - Visual customization (stylix, fonts)
  - `desktop.nix` - GUI applications (browser, wm, rofi, bluetooth, media, office)
- `systemModules/` - System services (frigate, jellyfin, matrix)
- `hosts/server/` - Base Proxmox VM config (default.nix, ssh.nix, networking.nix, hardware-configuration.nix, image.nix)
- `hosts/nvr/` - NVR-specific config extending server base

### Homelab VM Workflow
1. Build VMA image: `nixos-rebuild build-image --image-variant proxmox --flake .#initialProxmoxVMA`
2. Transfer `.vma.zst` to Proxmox host
3. Restore: `qmrestore /var/lib/vz/dump/<file>.vma.zst <VM_ID> --storage local-zfs --force`
4. Adjust resources: `qm set <vmid> --cores <n>` or `--memory <mb>`
5. Push config: `nixos-rebuild switch --target-host sandmhan@<ip> --flake .#<config> --sudo`

## Code Conventions

- Format Nix files with `nixfmt`
- User settings flow through `userSettings` attribute set; system settings through `systemSettings`
- Home Manager modules conditionally include packages based on `pkgs.stdenv.isLinux` vs Darwin
- Stylix handles theming consistently across both NixOS and Home Manager

## Option-Based Configuration Benefits

The new profile system provides:
- **Declarative Configuration**: Enable/disable features using boolean options instead of manual imports
- **Composable Profiles**: Inherit from base profiles and override specific options
- **Platform Awareness**: Automatic detection and handling of Linux/macOS/WSL differences
- **Conflict Resolution**: Uses `lib.mkDefault` for easy overrides without conflicts
- **Extensibility**: Easy to add new profiles or customize existing ones
- **Type Safety**: Options are properly typed and validated
- **Documentation**: Self-documenting through option descriptions
