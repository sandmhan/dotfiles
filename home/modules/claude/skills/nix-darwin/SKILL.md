---
name: nix-darwin
description: "Use when configuring macOS system settings, launchd services, Homebrew integration, or adopting nix-darwin for declarative macOS management."
---

# nix-darwin

## Intent Router

| Intent | Reference |
|---|---|
| Install, migrate, update, or uninstall nix-darwin | `references/darwin-setup.md` |
| Configure macOS defaults, security, Homebrew, launchd, environment | `references/darwin-defaults.md` |

## What nix-darwin Provides

Declarative macOS system configuration via Nix modules: system defaults (Dock, Finder, trackpad), launchd services, Homebrew cask/formula management, environment variables, system PATH, shell configuration, and security settings like Touch ID for sudo.

## Quick Start

```sh
darwin-rebuild switch --flake .#hostname
```

## Flake Output Pattern

```nix
darwinConfigurations.hostname = nix-darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = [ ./darwin.nix ];
};
```

## Home Manager as nix-darwin Module

```nix
modules = [
  home-manager.darwinModules.home-manager
  {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.username = import ./home.nix;
  }
];
```

## When to Adopt nix-darwin

**Use nix-darwin** when you need: system defaults, launchd services, Homebrew integration, `environment.systemPackages`, Touch ID sudo, or system-wide shell config.

**Stay with standalone HM** when you only need: user-level dotfiles, user packages, and shell configuration.
