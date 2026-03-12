# NixOS & Home Manager Configuration

This directory contains all configuration files for managing both **NixOS** systems and **Home Manager** environments using a unified **flake-based** setup.

---

## Folder Structure

```plaintext
.
├── configs                      # Non-nix configurations
│   └── keyboard
│       └── silakka54
│           └── sandmhan
│               ├── config.h
│               └── keymap.c
├── configuration.nix            # Desktop configuration
├── flake.lock
├── flake.nix                    # High-level flake for DD host and homelab
├── hardware-configuration.nix   # Desktop hardware config
├── homeModules                  # Home Manager configurations
│   ├── bluetooth.nix
│   ├── browser.nix
│   ├── claude.nix               # Claude Code configuration
│   ├── claude
│   │   ├── rules
│   │   │   ├── homelab.md       # Homelab development rules
│   │   │   └── nix-conventions.md
│   │   └── skills
│   │       └── nix-flake.md     # Nix flake development skill
│   ├── git.nix
│   ├── login.nix
│   ├── nvf                      # Modular Neovim configuration
│   │   ├── default.nix          # Entry point
│   │   ├── options.nix          # Editor options
│   │   ├── keymaps.nix          # Key mappings
│   │   ├── visuals.nix          # Visual plugins
│   │   ├── lsp.nix              # LSP servers
│   │   ├── languages.nix        # Language configs
│   │   ├── completion.nix       # Autocomplete
│   │   ├── treesitter.nix       # Treesitter
│   │   └── utility.nix          # Utility plugins
│   ├── nvim.nix
│   ├── rofi.nix
│   ├── stylix.nix
│   ├── terminal.nix
│   └── wm.nix
├── home.nix                     # Base Home Manager module
├── hosts                        # Hosts for homelab
│   ├── nvr                      # Video recorder
│   │   ├── default.nix
│   │   └── frigate.nix
│   └── server                   # Baseline Proxmox server config
│       ├── default.nix
│       ├── hardware-configuration.nix
│       ├── networking.nix
│       └── ssh.nix
├── Makefile                     # Recipes for easy rebuilds
├── README.md                    # You are here!
├── scripts
│   └── webcam.sh
└── systemModules                # NixOS system modules
    ├── frigate.nix
    ├── jellyfin.nix
    └── matrix.nix
```

---

## Overview

This repository uses **Nix flakes** to declaratively manage both system and user environments.
It unifies **NixOS**, **Home Manager**, and **Stylix** configuration into one reproducible setup that can be applied to multiple systems or users.

Key components:
- **NixOS** for system-level configuration
- **Home Manager** for user-level configuration
- **Stylix** for theming and font consistency
- **nvf** for modular Neovim configuration
- **Claude Code** for AI-assisted development with custom skills and rules
- **Makefile** for quick rebuild commands

---

## Home Manager

### Configuration

Your user configuration lives in [`home.nix`](./home.nix).
It manages:
- Shell setup and environment variables
- Terminal and editor configuration (Alacritty, Neovim via nvf)
- Fonts and color themes (via Stylix)
- Installed CLI tools and desktop apps
- Claude Code settings, skills, and rules

### Usage

The provided `Makefile` defines shortcuts for applying specific Home Manager profiles:

```bash
# Apply Home Manager configuration for macOS user
make macman

# Apply Home Manager configuration for Linux user
make sandmhan
```

Each target corresponds to a `homeConfigurations` entry in `flake.nix`.

---

## NixOS (System-Level)

Your system-level configuration is defined in:
- `configuration.nix`
- `hardware-configuration.nix`

To rebuild your NixOS system:

```bash
sudo nixos-rebuild switch --flake .#gaia
```

---

## Neovim Configuration (nvf)

The Neovim configuration uses [nvf](https://github.com/notashelf/nvf) and is modularized into separate files under `homeModules/nvf/`:

| File | Description |
|------|-------------|
| `default.nix` | Entry point, imports all modules |
| `options.nix` | Editor options (clipboard, line numbers, tabs) |
| `keymaps.nix` | Key mappings and leader key |
| `visuals.nix` | Visual plugins (devicons, cursorline, bufferline) |
| `lsp.nix` | LSP servers (clangd, nixd, tinymist, marksman) |
| `languages.nix` | Language configs (nix, typst, clang with DAP) |
| `completion.nix` | Autocomplete (blink-cmp, snippets) |
| `treesitter.nix` | Treesitter grammars and highlighting |
| `utility.nix` | Utility plugins (mini.files, flash-nvim, whichKey) |

---

## Claude Code Configuration

Claude Code is configured declaratively via Home Manager in `homeModules/claude.nix`. Configuration includes:

- **Settings**: Permissions, model selection, theme
- **Skills**: Custom guidance for specific tasks (e.g., `nix-flake.md` for Nix development)
- **Rules**: Project conventions (e.g., `nix-conventions.md`, `homelab.md`)

Skills and rules are stored as markdown files in `homeModules/claude/` and loaded with `builtins.readFile`.

---

## HomeLab

This homelab is currently set up on Proxmox with NixOS VMs defined for various services:

- **Frigate** for network video recording
- **Jellyfin** for media serving
- **Matrix** for communication

### Spinning up a new VM

Create a VMA image using the `initialProxmoxVMA` host:

```bash
nixos-rebuild build-image --image-variant proxmox --flake .#initialProxmoxVMA
```

Transfer the `.vma.zst` file to the Proxmox host and restore:

```bash
qmrestore /var/lib/vz/dump/<file>.vma.zst <VM_ID> --storage local-zfs --force
```

> **Note**: CPU cores and RAM can be modified with `qm set <vmid> --cores <n>` or `--memory <mb>`

### Deploying configuration to a VM

Build locally and push to the remote host:

```bash
nixos-rebuild switch --target-host sandmhan@<ip> --flake .#<config> --sudo
```

