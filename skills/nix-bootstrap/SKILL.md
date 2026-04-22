---
name: nix-bootstrap
description: >
  Use when the user needs to install Nix for the first time, configure flakes,
  set up direnv/nix-direnv, or create their first flake on macOS or Linux.
---

# Nix Bootstrap

## Intent Router

| User Intent                        | Reference                                      |
| ---------------------------------- | ---------------------------------------------- |
| Install/configure Nix on macOS     | [bootstrap-macos](references/bootstrap-macos.md) |
| Install/configure Nix on Linux     | [bootstrap-linux](references/bootstrap-linux.md) |

## Quick Start (macOS with Determinate Nix)

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

After install, open a new shell and run `nix --version` to verify.

## Post-Install Essentials

Key `nix.conf` settings (usually `~/.config/nix/nix.conf`):

```ini
experimental-features = nix-command flakes
trusted-users = root @admin
```

## Direnv + nix-direnv

Install direnv and nix-direnv, add the shell hook, then use this `.envrc` pattern in projects:

```bash
use flake
```

Run `direnv allow` after creating or changing `.envrc`.

## First Flake

```bash
nix flake init
```

This creates a starter `flake.nix`. Edit it to add `devShells` for your project, then enter the shell with `nix develop` or let direnv activate it automatically.
