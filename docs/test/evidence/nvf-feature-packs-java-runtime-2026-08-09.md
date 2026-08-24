---
title: NVF Feature Packs, Java Runtime, and Profiling Evidence
status: accepted
updated: 2026-08-09
---

# NVF Feature Packs, Java Runtime, and Profiling Evidence

## Overview

This evidence records validation for the Sandvim feature-pack presets, Java runtime harness, flake runtime checks, and profiling work. It preserves the red/green TDD sequence and records current profiling as host-dependent evidence, not a startup guarantee.

## Scope

- Public Sandvim options in `home/modules/nvf/options.nix`: `programs.sandvim.enable`, `programs.sandvim.preset`, and `programs.sandvim.packs.*`.
- Java behavior in `home/modules/nvf/languages-java.nix`.
- Runtime harnesses in `scripts/check-nvf-minimal-runtime.lua` and `scripts/check-nvf-java-runtime.lua`.
- Developer profiling in `scripts/profile-nvf.sh`.
- Flake package and check exports in `flake.nix`.
- Documentation synchronization in `README.md`, `docs/neovim-ide.md`, and `scripts/check-nvf-phase9.sh`.

## Red/Green TDD Narrative

| Phase | Observation |
|---|---|
| Red | `scripts/check-nvf-phase9.sh` failed before implementation because `programs.sandvim.preset`, `programs.sandvim.packs`, and `languages-java.nix` did not exist. Later red assertions exposed general-language LSP leakage from narrow packs and required the flake check/profile exports. |
| Green | Phase 9 passed after preset resolution, pack gates, Java support, narrow-pack LSP ownership, runtime harnesses, and flake outputs were implemented. |
| Refactor/docs | Markdown/Nix utility ownership and Treesitter grammars were moved behind the general pack, the Java harness was made network-independent, and README/operations-guide prose was synchronized with the final API and measurements. |

## Check Matrix

| Check | Status | Evidence |
|---|---|---|
| `bash scripts/check-nvf-baseline.sh` through `bash scripts/check-nvf-phase9.sh` | Passed | All cumulative NVF option, module, docs, keymap, package, and runtime assertions passed. |
| `nix build --no-link --no-write-lock-file path:.#checks.x86_64-linux.{sandvimExternalConsumer,sandvimMinimalConsumer,sandvimMinimalRuntime,sandvimJavaRuntime,sandvimStartupProfile}` | Passed | Standard/minimal consumers, minimal command absence, network-independent JDTLS attachment/symbols, Java Treesitter/AStyle, and startup budgets all built. The actual command supplied each check as a separate installable. |
| `nix build --dry-run --option eval-cache false .#homeConfigurations.<profile>.activationPackage --show-trace` | Passed | Passed for `sandmhan`, `terminalman`, `wslman`, and `macman`; no profile was activated. |
| `nix build --dry-run --no-write-lock-file .#packages.aarch64-darwin.sandvimMinimal` and `.sandvimFull` | Passed | Darwin package derivations evaluate without Linux-only clipboard dependencies. |
| Full packaged `nvim --headless "+checkhealth" "+qa!"` | Passed | Completed against `packages.x86_64-linux.sandvimFull`. |
| Packaged scoped `checkhealth vim.lsp`, `checkhealth nvim-treesitter`, and `checkhealth dap` | Passed | LSP, Treesitter, and DAP health checks completed against the full package. |
| Packaged FzfLua/Trouble command smoke | Passed | Core finder and full workflow entry points are registered. |
| `nix flake show --no-write-lock-file path:.` | Passed | Linux/Darwin preset packages and Linux Sandvim checks evaluate and are exported. |
| `nixfmt --check flake.nix home/modules/nvf/*.nix` | Passed | Changed Nix is formatted. |
| `bash -n scripts/check-nvf-*.sh scripts/profile-nvf.sh` | Passed | Shell validators and profiler parse. |
| ShellCheck with intentional `SC2016` exclusions | Passed | Checked changed NVF shell scripts; literal single-quoted grep/Nix expressions intentionally retain dollar text. |
| Statix and Deadnix | Passed | Statix passed on `flake.nix` and `home/modules/nvf`; Deadnix passed on changed Nix files. |
| `git diff --check` | Passed | No whitespace errors. |

## Profiling Evidence

Observed final 3-run sample from the local developer profiler after pack refinements:

| Preset | Closure | Startup min | Startup median | Startup max |
|---|---:|---:|---:|---:|
| `minimal` | 304.9 MiB | 57 ms | 58 ms | 101 ms |
| `standard` | 13.7 GiB | 93 ms | 116 ms | 153 ms |
| `full` | 14.4 GiB | 80 ms | 85 ms | 87 ms |

Closure size, not startup time, is the primary feature-pack benefit. Startup timings vary with host hardware, storage, cache state, and system load.

## Known unrelated flake-wide failure

A broad `nix flake check --no-write-lock-file --show-trace path:.` reached the pre-existing `nixosConfigurations.agent-sandbox` output and failed because that NixOS/Home Manager integration does not provide the `codexPkgs` module argument required by `home/modules/ai-codex.nix`. The failure is outside the Sandvim module and was not hidden: every new Sandvim check was built directly and passed. No activation or deployment was performed.

## References

- `README.md`
- `docs/neovim-ide.md`
- `docs/test/evidence/README.md`
- `home/modules/nvf/options.nix`
- `home/modules/nvf/languages-java.nix`
- `scripts/check-nvf-phase9.sh`
- `scripts/profile-nvf.sh`
