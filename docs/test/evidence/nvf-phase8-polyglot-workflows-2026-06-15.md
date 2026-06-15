---
title: NVF Phase 8 Polyglot Workflow Evidence
status: accepted
updated: 2026-06-15
---

# NVF Phase 8 Polyglot Workflow Evidence

## Scope

Phase 8 adds Sandvim/NVF support for Rust, Go, Lua, SQL, Dart/Flutter, Obsidian-style Markdown note navigation, professional workflow integrations, and Vim-aware tmux pane navigation. The implementation remains gated by `programs.sandvim.enable`.

## Validation commands

Results recorded by the implementation worker on 2026-06-15.

| Command | Result | Notes |
|---|---|---|
| `nixfmt home/modules/nvf/*.nix home/modules/terminal.nix` | passed | Formatted changed Nix modules. |
| `git diff --check` | passed | No whitespace errors. |
| `bash -n scripts/check-nvf-*.sh` | passed | All NVF validation scripts parse. |
| `bash scripts/check-nvf-baseline.sh` | passed | Existing baseline assertions still pass. |
| `bash scripts/check-nvf-phase2.sh` | passed | Existing language module assertions still pass. |
| `bash scripts/check-nvf-phase3.sh` | passed | DAP/test-runner boundary still passes. |
| `bash scripts/check-nvf-phase4.sh` | passed | Workspace hardening assertions still pass. |
| `bash scripts/check-nvf-phase5.sh` | passed | Retired AI bridge boundary still passes. |
| `bash scripts/check-nvf-phase6.sh` | passed | README/operations-guide/evidence expectations pass after updating the stale planned-language assertion. |
| `bash scripts/check-nvf-phase7.sh` | passed | CodeCompanion Codex ACP assertions and runtime command checks pass. |
| `NVF_PHASE8_REQUIRE_RUNTIME=1 bash scripts/check-nvf-phase8.sh` | passed | New polyglot/workflow/tmux assertions and required runtime command checks pass, including mapped GrugFar/Diffview commands. |
| `nix flake show --no-write-lock-file` | passed | Flake output enumeration succeeds. |
| `nix build --no-write-lock-file .#checks.x86_64-linux.sandvimExternalConsumer` | passed | Portable external-consumer Sandvim check builds. |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage` | passed | Linux terminal profile dry-run succeeds. |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage` | passed | Main Linux profile dry-run succeeds. |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.wslman.activationPackage` | passed | WSL profile dry-run succeeds. |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.macman.activationPackage` | passed | Darwin profile dry-run evaluates on this builder. |
| `nix build --no-write-lock-file .#homeConfigurations.terminalman.config.programs.nvf.finalPackage -o result-sandvim-nvim` | passed | Build-local Neovim package produced without activation. |
| `./result-sandvim-nvim/bin/nvim --headless "+checkhealth" "+qa"` | passed | Health command completes; Obsidian emits a non-fatal upstream deprecation warning about `client.opts`. |
| `./result-sandvim-nvim/bin/nvim --headless -c 'if exists(":Obsidian") != 2 \| cquit \| endif' -c 'qa!'` | passed | Obsidian command is registered. |
| `./result-sandvim-nvim/bin/nvim --headless -c 'if exists(":GrugFar") != 2 \| cquit \| endif' -c 'if exists(":GrugFarWithin") != 2 \| cquit \| endif' -c 'if exists(":DiffviewOpen") != 2 \| cquit \| endif' -c 'if exists(":DiffviewToggleFiles") != 2 \| cquit \| endif' -c 'if exists(":Trouble") != 2 \| cquit \| endif' -c 'qa!'` | passed | Workflow commands, including mapped variants, are registered. |

## Runtime smoke details

Build-local package validation used the repository output rather than activating Home Manager:

```bash
nix build --no-write-lock-file .#homeConfigurations.terminalman.config.programs.nvf.finalPackage -o result-sandvim-nvim
./result-sandvim-nvim/bin/nvim --headless "+checkhealth" "+qa"
./result-sandvim-nvim/bin/nvim --headless -c 'if exists(":Obsidian") != 2 | cquit | endif' -c 'qa!'
./result-sandvim-nvim/bin/nvim --headless \
  -c 'if exists(":GrugFar") != 2 | cquit | endif' \
  -c 'if exists(":GrugFarWithin") != 2 | cquit | endif' \
  -c 'if exists(":DiffviewOpen") != 2 | cquit | endif' \
  -c 'if exists(":DiffviewToggleFiles") != 2 | cquit | endif' \
  -c 'if exists(":Trouble") != 2 | cquit | endif' \
  -c 'qa!'
```

Observed warning during `checkhealth`:

```text
client.opts is deprecated, use Obsidian.opts instead.
client is going to be removed in the future as well.
```

Follow-up investigation found the warning is emitted during `:checkhealth render-markdown`, not by this repository's Obsidian setup. The pinned `render-markdown.nvim` health check calls `obsidian.get_client().opts.ui.enable`, while pinned `obsidian.nvim` v3.16.0 deprecates `client.opts` in favor of the global `Obsidian.opts`. There is no safe Sandvim configuration knob for that upstream health-check implementation with the current NVF pins, and the warning remains non-fatal. Track it during the next pinned NVF/render-markdown.nvim/obsidian.nvim review.

## Skipped checks

No safe no-activation checks were intentionally skipped. Home Manager activation/deploy commands were not run by design.

## Follow-up validation notes

Results recorded by the follow-up worker on 2026-06-15:

| Command | Result | Notes |
|---|---|---|
| `nix build --no-write-lock-file .#homeConfigurations.terminalman.config.programs.nvf.finalPackage -o result-sandvim-nvim` | passed | Rebuilt the packaged Sandvim Neovim for runtime follow-up checks. Before the GTK follow-up fix, this reproduced the unrelated Home Manager `gtk.gtk4.theme` legacy-default warning for `terminalman`; after the fix, only the expected dirty-tree notice remained. |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.{terminalman,sandmhan,wslman,macman}.activationPackage` | passed | Re-ran each profile separately and confirmed no `gtk.gtk4.theme` warning remains. |
| `./result-sandvim-nvim/bin/nvim --headless test.md '+checkhealth' '+qa!'` from a temporary Markdown workspace | passed with non-fatal warning | Confirmed the Obsidian deprecation appears while `checkhealth` is checking `render-markdown`; command completed successfully. |
| `patch --dry-run -p1 < .../flutter-tools.patch` against pinned `flutter-tools.nvim` source `677cc07c16e8b89999108d2ebeefcfc5f539b73c` | failed as expected | Confirms NVF's current no-resolve patch is incompatible with the pinned upstream source (`2 out of 3 hunks FAILED`), so Flutter remains PATH/devshell-owned. |

## Notes

- Flutter is intentionally PATH/devshell-owned (`flutter-tools.flutterPackage = null`) to avoid pulling the full Flutter SDK into every Sandvim profile. `flutter-tools.enableNoResolvePatch` remains disabled because NVF's current no-resolve patch fails to apply to the pinned flutter-tools.nvim source; use a non-Nix Flutter SDK on PATH or revisit after updating the NVF/input pin.
- Rust, Go, and Dart DAP are intentionally disabled pending project-specific debug profile design.
- Markdown ownership moved from Marksman/prettierd to markdown-oxide/mdformat for stronger Obsidian-style note support.
