---
name: nix-home-manager
description: Use when configuring user environments with Home Manager, writing HM modules, or managing dotfiles through Nix.
---

## Intent Router

| Intent | Reference |
|---|---|
| HM option patterns, module authoring, program/service config | [hm-option-patterns.md](references/hm-option-patterns.md) |

## CLI Commands

```bash
home-manager switch --flake .#username   # Apply configuration
home-manager build --flake .#username    # Build without activating
home-manager generations                 # List past generations
home-manager packages                    # List installed packages
```

## Standalone Flake Pattern

```nix
{
  outputs = { nixpkgs, home-manager, ... }: {
    homeConfigurations.user = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      modules = [ ./home.nix ];
      extraSpecialArgs = { inherit userSettings; };
    };
  };
}
```

## Option Search

- Unstable: `https://home-manager-options.extranix.com/?query=&release=master`
- Stable: `https://home-manager-options.extranix.com/?query=&release=release-24.11`
- Local: `manix "programs.git"` (if installed)

## Three Modes

| Mode | Integration | Entry point |
|---|---|---|
| **Standalone** (primary) | None — runs independently | `home-manager switch --flake` |
| NixOS module | `imports = [ home-manager.nixosModules.home-manager ]` | `home-manager.users.<name>` in NixOS config |
| nix-darwin module | `imports = [ home-manager.darwinModules.home-manager ]` | `home-manager.users.<name>` in darwin config |

NixOS/nix-darwin modes rebuild with the system; standalone rebuilds separately.

## Key home.* Options

- **`home.packages`** — list of packages to install into user profile
- **`home.file."path"`** — manage arbitrary dotfiles (`.source` or `.text`)
- **`home.sessionVariables`** — environment variables set on login
- **`home.activation`** — custom activation scripts (run on `home-manager switch`)
