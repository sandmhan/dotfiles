# NixOS & Home Manager Configuration

This directory contains all configuration files for managing both **NixOS** systems and **Home Manager** environments using a unified **flake-based** setup with a modern **option-based configuration system**.

Start at the [documentation hub](./docs/index.md) for architecture, ADRs, plans, operations, audits, and tickets.

## 🚀 Quick Start

**New to this configuration?**

Option 1: **Automated Setup** (Recommended)
```bash
git clone <your-forked-repository> ~/dotfiles && cd ~/dotfiles && ./scripts/bootstrap.sh
```

Option 2: **Manual Setup** - Use the profile-specific commands below and see [home/profiles/README.md](./home/profiles/README.md) for customization guidance.

**Existing users?** The configuration now uses an option-based system. See the [Migration Guide](#migration-from-old-system) below.

---

## Folder Structure

```plaintext
.
├── CLAUDE.md                    # Claude Code project documentation
├── flake.nix                    # Main flake with all configurations
├── home/                        # Option-based Home Manager system
│   ├── options.nix              # Complete option definitions
│   ├── modules/                 # Home Manager feature modules
│   │   ├── core.nix             # Essential modules (always enabled)
│   │   ├── terminal.nix         # Terminal environment
│   │   ├── development.nix      # Development tools and AI integrations
│   │   ├── ai-*.nix             # Claude/Codex/agent integrations
│   │   ├── nvf/                 # Neovim configuration
│   │   └── theming.nix          # Theming and fonts
│   └── profiles/                # Declarative configuration profiles
│       ├── README.md            # Profile customization guide
│       ├── terminal.nix         # Base terminal profile
│       ├── desktop.nix          # Full desktop profile
│       ├── macos.nix            # macOS-optimized profile
│       └── wsl.nix              # WSL-optimized profile
├── hosts/                       # NixOS host configurations
│   ├── gaia/                    # Framework laptop desktop
│   ├── server/                  # Base Proxmox VM configuration
│   ├── lxc-*/                   # LXC container hosts
│   └── media/, git/, vpn/, ...  # Homelab service hosts
├── systemModules/               # Reusable NixOS service modules
│   ├── forgejo.nix, media.nix, nas.nix, tailscale.nix
│   ├── frigate.nix, llama.nix, matrix.nix, monitoring.nix
│   └── manga/                   # Manga stack modules
├── docs/                        # Documentation hub (architecture, ADRs, plans, operations)
├── themes/                      # Stylix/base16 themes
├── Makefile                     # Build shortcuts
└── ...                          # Other files
```

---

## Overview

This repository uses **Nix flakes** to declaratively manage both system and user environments with a modern **option-based configuration system** for maximum flexibility and ease of use.

It unifies **NixOS**, **Home Manager**, and **Stylix** configuration into one reproducible setup that can be applied across multiple platforms (Linux, macOS, WSL).

### 🆕 New Option-Based System

The configuration now uses `lib.mkOption` and `lib.mkEnableOption` for:
- **Declarative Configuration**: `myHome.features.enableGitExtensions = true` vs manual imports
- **Composable Profiles**: Inherit and override settings easily
- **Platform Detection**: Automatic Linux/macOS/WSL handling
- **Type Safety**: Proper validation and documentation
- **Conflict Resolution**: Priority-based option merging

### Key Components:
- **NixOS** for system-level configuration
- **Home Manager** with option-based profiles for user environments
- **Stylix** for consistent theming and fonts
- **nvf** for modular, feature-rich Neovim configuration
- **Claude Code** and **Codex** for AI-assisted development with shared skills and rules
- **Platform Support**: Linux desktop, macOS, WSL, and headless systems

---

## Home Manager

### Available Configurations

The new option-based system provides four ready-to-use configurations:

| Configuration | Platform | Description |
|---------------|----------|-------------|
| `sandmhan` | Linux Desktop | Full desktop environment with GUI apps, window manager, development tools |
| `macman` | macOS | Terminal-focused with development tools, optimized for macOS |
| `wslman` | WSL2 | Terminal environment with container tools, WSL-optimized |
| `terminalman` | Linux Headless | Terminal-only for servers and headless systems |

### Quick Usage

```bash
# Apply configurations
make sandmhan     # Linux desktop (full GUI)
make macman       # macOS terminal environment
make wslman       # WSL development environment
make terminalman  # Linux headless/server

# Or manually with Home Manager
home-manager switch --flake .#macman
```

### What Each Configuration Includes

**Terminal Profile** (base for all):
- Git, Neovim (nvf), tmux, bash with advanced features
- Development tools: Claude Code, terminal utilities
- Cross-platform theming with Stylix

**Desktop Profile** (extends terminal):
- Window manager (Sway), browser, media apps
- GUI applications: file manager, password manager, office suite
- Audio tools, Bluetooth management

**Platform-Specific Optimizations**:
- **macOS**: Uses native system integration, excludes Linux-specific tools
- **WSL**: Includes container tools, excludes GUI components
- **Headless**: Focus on terminal productivity and development

### Customization with Options

Create custom profiles by setting options instead of manually importing modules:

```nix
# Example: Custom gaming profile
{
  imports = [ ./home/profiles/desktop.nix ];

  myHome = {
    profiles = {
      enableGaming = true;           # Enable gaming packages
      enableVirtualization = true;  # For game development
    };

    features = {
      enableContainerTools = true;  # For game servers
      enableSecurity = false;       # Disable if not needed
    };
  };
}
```

**Available Options** (see `home/options.nix` for complete list):
- `myHome.profiles.*` - High-level feature sets (desktop, development, gaming, media, office, social, virtualization)
- `myHome.features.*` - Granular controls (shell tools, git extensions, theming, security, containers)
- `myHome.platform.*` - Platform settings (headless, WSL, Linux/macOS detection)

**Custom Profile Guide**: See [home/profiles/README.md](./home/profiles/README.md) for detailed customization instructions.

---

## Migration from Old System

**Existing users**: The configuration structure has been modernized. Here's how to migrate:

### Old vs New

**Before** (old-style manual imports, illustrative only):
```nix
imports = [
  ./homeModules/terminal.nix
  ./homeModules/core.nix
] ++ lib.optionals condition [ ./homeModules/desktop.nix ];
```

Current low-level `home/modules/*` files are implementation details behind the option/profile system. Prefer importing `home/profiles/*.nix` and setting options instead of importing feature modules directly.

**After** (declarative options):
```nix
myHome.profiles.enableDesktop = true;
myHome.features.enableGitExtensions = true;
```

### Migration Steps

1. **Backup**: Save your current `home.nix` configuration
2. **Choose Profile**: Pick the closest match (`terminal`, `desktop`, `macos`, `wsl`)
3. **Test**: Apply the new configuration: `home-manager switch --flake .#profilename`
4. **Customize**: Add options to match your previous setup
5. **Verify**: Check that all your tools and settings are preserved

### What Changed

- ✅ **Easier**: Options instead of complex imports
- ✅ **Flexible**: Override settings without conflicts
- ✅ **Platform-aware**: Automatic Linux/macOS detection
- ✅ **Documented**: Self-documenting through option descriptions
- ✅ **Maintainable**: Clear separation of concerns

---

## NixOS (System-Level)

Your system-level configuration is defined in:
- `hosts/gaia/default.nix` for the Gaia desktop
- host-local hardware config files where required (for example under `hosts/server/`)

To rebuild your NixOS system:

```bash
sudo nixos-rebuild switch --flake .#gaia
```

---

## Neovim Configuration (SandVim)

The Neovim configuration is maintained in the standalone public [SandVim](https://github.com/sandmhan/sandvim) flake. This dotfiles repository consumes the pinned remote input, re-exports its Home Manager module/packages/checks for compatibility, and keeps only the local adapter that maps `myHome.features.enableNixvim` to `programs.sandvim.enable` with the `full` preset. The adapter sets `programs.sandvim.colorScheme = "none"` so Stylix remains the single theme owner for personal profiles.

Direct consumers should depend on SandVim rather than this complete dotfiles repository:

```nix
inputs.sandvim = {
  url = "github:sandmhan/sandvim/v0.2.0";
  inputs.nixpkgs.follows = "nixpkgs";
  inputs.home-manager.follows = "home-manager";
};

# In a Home Manager module list:
sandvim.homeManagerModules.default
```

SandVim exports `minimal`, `standard`, and `full` package presets for `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, and `aarch64-darwin`. Intel macOS consumers use `homeManagerModules.intelDarwin` with compatible Nixpkgs/Home Manager releases. See the upstream [consumer guide](https://github.com/sandmhan/sandvim/blob/main/docs/consumer-guide.md) and [operations guide](https://github.com/sandmhan/sandvim/blob/main/docs/neovim-ide.md).

The local tmux configuration continues to own the tmux side of smart-splits integration. SandVim owns all Neovim modules, runtime checks, profiling, and editor documentation.

---

## Claude Code Configuration

Claude Code is configured declaratively from `home/modules/ai-claude.nix` using shared content from `home/modules/ai-skills.nix`. Home Manager activation bootstraps writable regular files into Claude's runtime paths instead of leaving read-only Nix-store symlinks:

- **Settings**: `~/.claude/settings.json`
- **Skills**: `~/.claude/skills/<name>/`
- **Rules**: `~/.claude/rules/<name>.md`
- **Canonical export**: provider-agnostic copies under `~/.local/share/ai/`

Activation replaces legacy Home Manager symlinks with regular files or directories. Existing regular files are preserved and made user-writable so Claude can update them at runtime. Because preserved files are mutable, later Nix default changes are not forced over local edits; remove the specific file or directory and run Home Manager again to re-bootstrap the current declarative default.

Neovim AI is CodeCompanion-only in the standalone SandVim `modules/ai-codecompanion.nix` module, using Codex ACP with ChatGPT authentication and no API key in Nix. Claude, Codex, and Pi remain available as standalone Home Manager tooling outside Neovim.

## Codex Configuration

Codex is configured declaratively from `home/modules/ai-codex.nix` and consumes the same shared skill/rule registry as Claude. Home Manager activation treats `~/.codex/` as a writable runtime directory and bootstraps regular files inside it:

- **Config**: `~/.codex/config.toml`
- **Rules**: `~/.codex/AGENTS.md`
- **Skills**: `~/.codex/skills/<name>/`
- **Default model**: `gpt-5-codex` with `model_reasoning_effort = "medium"` for ChatGPT account compatibility

Activation replaces legacy Home Manager symlinks, preserves existing regular files, and copies only missing skill directory entries. If an existing `~/.codex` regular file is found, activation moves it to a timestamped `~/.codex.hm-backup-*` path and, when non-empty, copies it into `~/.codex/config.toml` for inspection. Remove or manually refresh existing mutable files when you want a later Nix default to take effect. This keeps source content declarative while allowing Codex to read and modify regular runtime files.

---

## HomeLab

This homelab is currently set up on Proxmox with NixOS VM and LXC configurations defined in `flake.nix`:

- **Core/deployed services**: `matrix`, `fitness` (wger), `vpn` (Tailscale router), `lxc-monitor`, `nixos-builder`, and `agent-sandbox`
- **Service hosts ready/planned for deployment**: `git` (Forgejo), `homeassistant`, `media` (Jellyfin + *arr stack), `nas`, `nvr`, `llama`, `gaming`, and the `monitor` VM output (planned unless Proxmox confirms it is live)
- **Container outputs**: `initialLXC` base tarball plus `lxc-matrix`, `lxc-monitor`, `lxc-git`, `lxc-homeassistant`, and `lxc-nas`

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
