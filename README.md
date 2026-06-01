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

## Neovim Configuration (nvf)

The Neovim configuration uses [nvf](https://github.com/notashelf/nvf) and is modularized into separate files under `home/modules/nvf/`. See `docs/neovim-ide.md` for the current IDE decisions, keymap taxonomy, and validation workflow.

| File | Description |
|------|-------------|
| `default.nix` | Entry point, imports all modules |
| `options.nix` | Editor options (clipboard, line numbers, tabs) |
| `keymaps.nix` | Core key mappings, leader key, finder, Git, LSP, and diagnostics shortcuts |
| `visuals.nix` | Visual plugins and presentation settings |
| `lsp.nix` | Global LSP enablement and explicit server ownership |
| `languages.nix` | Shared/core language configs for Markdown, Nix, Typst, and C/C++ |
| `languages-python.nix` | Python IDE ownership with basedpyright, Ruff formatting/linting, and debugpy |
| `languages-web.nix` | JavaScript, TypeScript, and JSON IDE ownership with ts_ls, prettierd, eslint_d, jsonls, and JS DAP |
| `languages-infra.nix` | Infrastructure language ownership for Terraform/OpenTofu, HCL, YAML/Kubernetes/Compose, Dockerfile, Bash, and TOML |
| `testing.nix` | Neotest adapters, DAP UI, and shared test/debug keymaps |
| `hardening.nix` | Workspace root policy, large/generated-file guards, diagnostic throttling, and explicit secret-scan task hooks |
| `ai.nix` | Guarded AI bridge keymaps and commands for Claude Code, Codex CLI, and Pi with confirmation, scoped context, and redaction |
| `ai-companion.nix` | CodeCompanion.nvim OpenAI-compatible chat, selected-code edit/review/test prompts, and plugin keymaps behind `enableNvfAiCompanion` |
| `completion.nix` | Autocomplete stack (blink-cmp, snippets) |
| `treesitter.nix` | Treesitter grammars and highlighting |
| `utility.nix` | Utility plugins (mini.files, flash-nvim, markdown preview, nix-develop, whichKey) |
| `finder.nix` | FZF-based search and navigation |
| `editing.nix` | Editing helpers such as comments, surround, autopairs, and undo tooling |
| `git.nix` | Git integrations for signs, status, and conflict tooling |
| `notes.nix` | TODO/FIXME/NOTE highlighting |
| `tidal.nix` | Haskell/Tidal language support and live-coding commands |
| `toggles.nix` | UI/editor toggles |
| `ui.nix` | Statusline, messages, breadcrumbs, bufferline, and related UI modules |

When `home/modules/nvf/default.nix` imports change, update this inventory in the same patch and run `bash scripts/check-nvf-phase6.sh`. PR validation should call out README drift explicitly; stale or extra inventory rows should not be deferred to a later documentation cleanup.

---

## Claude Code Configuration

Claude Code is configured declaratively from `home/modules/ai-claude.nix` using shared content from `home/modules/ai-skills.nix`. Configuration includes:

- **Settings**: Permissions, model selection, theme
- **Skills**: Custom guidance for specific tasks (e.g., the `nix-flake` skill for Nix development)
- **Rules**: Project conventions (e.g., `nix-conventions.md`, `homelab.md`)

Skills and rules are stored under `home/modules/ai/`. Home Manager maps them into Claude's config directly and also exports a canonical copy to `~/.local/share/ai/`. The NVF AI bridge in `home/modules/nvf/ai.nix` can invoke the Claude, Codex, and Pi CLIs only after scoped context redaction and explicit confirmation.

## Codex Configuration

Codex is configured declaratively from `home/modules/ai-codex.nix` and consumes the same shared skill/rule registry as Claude.

- **Shared source**: `home/modules/ai-skills.nix` defines the provider-agnostic `myHome.ai.skills` and `myHome.ai.rules` sets
- **Canonical export**: Home Manager also writes a tool-agnostic cache to `~/.local/share/ai/`
- **Codex runtime path**: Codex reads skills from `~/.codex/skills/`
- **Important behavior**: Codex only picked up regular files reliably, so Home Manager materializes real files into `~/.codex/skills/` during activation instead of leaving Nix-store symlinks in place

This keeps the source of truth declarative while matching Codex's runtime discovery behavior. The NVF AI bridge reuses the existing `codex` CLI and keeps sandboxing/approval behavior owned by this module instead of configuring a separate AI stack.

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
