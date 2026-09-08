---
title: SandVim Integration Guide
status: accepted
updated: 2026-09-08
---

# SandVim Integration Guide

The Neovim/NVF configuration is maintained in the standalone public [SandVim repository](https://github.com/sandmhan/sandvim). That repository owns the `programs.sandvim` API, NVF modules, preset packages, runtime checks, profiling tools, security guidance, and detailed editor operations documentation.

This document covers only the integration boundary in this dotfiles repository.

## Flake integration

`flake.nix` pins `github:sandmhan/sandvim` and aligns its primary dependencies with this repository:

```nix
sandvim = {
  url = "github:sandmhan/sandvim/v0.1.0";
  inputs.nixpkgs.follows = "nixpkgs";
  inputs.home-manager.follows = "home-manager";
  inputs.nvf.follows = "nvf";
};
```

The repository consumes `sandvim.homeManagerModules.default` and re-exports the standalone flake's modules, packages, and checks under its own outputs for backward compatibility. The editor implementation is not copied into this repository.

## Local profile adapter

Existing profiles retain the local `myHome` interface:

```nix
config.programs.sandvim = {
  enable = lib.mkDefault config.myHome.features.enableNixvim;
  preset = lib.mkDefault "full";
};
```

This adapter belongs to the dotfiles repository because `myHome.features.enableNixvim` is a personal profile option. SandVim itself has no dependency on `myHome`, host settings, Stylix, secrets, or other dotfiles modules.

## Ownership boundary

SandVim owns:

- `programs.sandvim.enable`, presets, packs, and note options;
- Neovim plugins, LSPs, formatters, linters, DAP integrations, and keymaps;
- workspace hardening and explicit secret scanning;
- CodeCompanion/Codex ACP integration;
- preset packages and flake-native runtime checks;
- Intel and Apple Silicon macOS compatibility documentation.

This repository owns:

- whether each personal profile enables SandVim;
- the local default of the `full` preset;
- terminal/tmux configuration, including loading `smart-splits.tmux`;
- standalone Claude, Codex, and Pi tooling outside Neovim.

## Closure parity

At extraction, the local implementation, standalone flake, anonymous GitHub source, and an independent Home Manager consumer produced identical `x86_64-linux` Neovim output paths and recursive closures with aligned inputs:

| Preset | Output path | Closure |
|---|---|---:|
| Minimal | `/nix/store/g92hdxsg8f5k3b2lqixfp004mxmpn8rc-nvf-with-helpers` | 304.9 MiB |
| Standard | `/nix/store/jx76l4n5fzj5vlzsjd9sp20xgxgb7zfn-nvf-with-helpers` | 13.7 GiB |
| Full | `/nix/store/a227xqldibp937c33lgl789fmzj3qr1v-nvf-with-helpers` | 14.4 GiB |

See `docs/test/evidence/nvf-sandvim-standalone-migration-2026-09-08.md` and the upstream [extraction evidence](https://github.com/sandmhan/sandvim/blob/main/docs/test/evidence/standalone-extraction-2026-09-08.md).

## Validation

Validate the remote integration without activation:

```bash
nix flake show --all-systems --no-write-lock-file
nix build --no-write-lock-file .#checks.x86_64-linux.sandvimMinimalRuntime
nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage --show-trace
nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage --show-trace
nix build --dry-run --no-write-lock-file .#homeConfigurations.wslman.activationPackage --show-trace
nix build --dry-run --no-write-lock-file .#homeConfigurations.macman.activationPackage --show-trace
```

Build and run the packaged full editor directly when runtime evidence is required:

```bash
nix build --no-write-lock-file .#homeConfigurations.terminalman.config.programs.nvf.finalPackage -o result-sandvim-nvim
./result-sandvim-nvim/bin/nvim --headless "+checkhealth" "+qa"
```

Do not activate or deploy a profile solely for validation.

## Consumer and operations documentation

- [SandVim README](https://github.com/sandmhan/sandvim)
- [Consumer guide](https://github.com/sandmhan/sandvim/blob/main/docs/consumer-guide.md)
- [Editor operations guide](https://github.com/sandmhan/sandvim/blob/main/docs/neovim-ide.md)
