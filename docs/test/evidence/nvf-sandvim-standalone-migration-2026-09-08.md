---
title: SandVim standalone repository migration evidence
status: accepted
date: 2026-09-08
---

# SandVim standalone repository migration evidence

## Scope

Published the NVF configuration as the public `github:sandmhan/sandvim` flake, migrated this dotfiles flake to consume the pinned remote module, and removed the duplicate local NVF module and check implementation. The dotfiles-local `myHome.features.enableNixvim` adapter and tmux-side smart-splits configuration remain local. No Home Manager activation or deployment was performed.

## Published source

- Repository: `https://github.com/sandmhan/sandvim`
- Initial extraction revision: `2f25d427b062ed045cf60624de0c4d429932a6c9`
- Initial consumed release: `v0.1.0` at `85a2ee4e8e00062bb0f6c8ecf96e27404d75c842`
- Current consumed release: `v0.2.0` at `29c3ebfbe26a185e514422872bcf108647df073e`
- Visibility: public
- Anonymous `git ls-remote` and `nix flake metadata github:sandmhan/sandvim` — passed.
- `nix flake show --all-systems --no-write-lock-file github:sandmhan/sandvim` — passed.

## Standalone validation

- `nixfmt --check flake.nix modules/*.nix templates/home-manager/flake.nix` — passed.
- `deadnix --fail .` and `statix check .` — passed in the standalone repository.
- GitHub Actions YAML parsing and `actionlint` — passed.
- Offline Markdown link checking — passed.
- All standalone `x86_64-linux` external-consumer and runtime checks built successfully.
- A separate Home Manager flake imported only the public module and built a customized workplace activation package.
- `aarch64-linux`, `x86_64-darwin`, and `aarch64-darwin` package/check outputs evaluated successfully. Native execution was skipped locally because matching builders were unavailable.
- Public CI run [34249739876](https://github.com/sandmhan/sandvim/actions/runs/34249739876) passed native minimal consumer/runtime checks on Linux, Intel macOS, and Apple Silicon macOS, plus ARM Linux evaluation and comprehensive Linux runtime checks.

## Closure parity

With identical Nixpkgs, Home Manager, and NVF pins, the pre-extraction dotfiles outputs, standalone local outputs, anonymous GitHub outputs, and independent Home Manager consumer outputs had identical package output paths and sorted recursive closure sets:

| Preset | Output path | Closure |
|---|---|---:|
| Minimal | `/nix/store/g92hdxsg8f5k3b2lqixfp004mxmpn8rc-nvf-with-helpers` | 304.9 MiB |
| Standard | `/nix/store/jx76l4n5fzj5vlzsjd9sp20xgxgb7zfn-nvf-with-helpers` | 13.7 GiB |
| Full | `/nix/store/a227xqldibp937c33lgl789fmzj3qr1v-nvf-with-helpers` | 14.4 GiB |

The profile-specific `terminalman.config.programs.nvf.finalPackage` was also evaluated from a detached pre-migration worktree and from the remote-input working tree. Both resolved to:

`/nix/store/qfdc8awwbl9r0fdchdy7s0cqak3jf8i5-nvf-with-helpers`

The remote-backed package then built and completed `nvim --headless "+checkhealth" "+qa"` with exit status 0 and no `ERROR`/`FAILED` markers.

## Dotfiles validation

- `nixfmt --check flake.nix` — passed.
- `nix flake show --all-systems --no-write-lock-file` — passed.
- `nix build --no-write-lock-file --no-link .#checks.x86_64-linux.sandvimMinimalRuntime` — passed through the proxied remote check.
- `nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage --show-trace` — passed.
- `nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage --show-trace` — passed.
- `nix build --dry-run --no-write-lock-file .#homeConfigurations.wslman.activationPackage --show-trace` — passed.
- `nix build --dry-run --no-write-lock-file .#homeConfigurations.macman.activationPackage --show-trace` — passed.

## Theme ownership follow-up

SandVim v0.2.0 made the standalone default explicit as Base16 Gruvbox dark hard. The dotfiles adapter sets `programs.sandvim.colorScheme = "none"` so Stylix remains the sole theme owner for personal profiles. With the pinned public v0.2.0 release, `terminalman` retained both its exact pre-upgrade package path and effective colors:

```text
package=/nix/store/qfdc8awwbl9r0fdchdy7s0cqak3jf8i5-nvf-with-helpers
background=#1d2021
foreground=#d5c4a1
```

The re-exported standalone minimal package used the new SandVim-owned theme and reported the same effective colors. Upstream theme option/runtime checks covered all four bundled Gruvbox variants. Public CI run [34279896577](https://github.com/sandmhan/sandvim/actions/runs/34279896577) passed comprehensive Linux checks and native default-theme minimal runtime checks on Linux, Intel macOS, and Apple Silicon macOS. See the upstream [theme validation evidence](https://github.com/sandmhan/sandvim/blob/v0.2.0/docs/test/evidence/gruvbox-theme-2026-09-08.md).

The dotfiles all-system output evaluation, all four Home Manager profile dry-runs, proxied minimal/theme option/theme runtime checks, Nix formatting/lint, and diff checks passed without activation.

## Ownership result

- The editor implementation, runtime Lua harnesses, fixture, profiler, and flake checks now live only in the standalone repository.
- This repository retains the remote input, compatibility re-exports, local `myHome` preset adapter, terminal/tmux integration, historical planning records, and migration evidence.
