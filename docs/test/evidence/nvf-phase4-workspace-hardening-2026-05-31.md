---
title: NVF Phase 4 Workspace Hardening Evidence
status: accepted
updated: 2026-05-31
---

# NVF Phase 4 Workspace Hardening Evidence

## Scope

Phase 4 validation for NVF workspace hardening (`NVF-018`, `NVF-019`, and `NVF-020`): `home/modules/nvf/hardening.nix`, root detection commands, local config trust policy, large/generated-file guards, explicit gitleaks secret-scanning task, diagnostic throttling, and operations-guide health/profiling documentation.

## Option schema validation

Confirmed implementation path for the pinned NVF input before marking Phase 4 done:

- `vim.luaConfigRC` is a supported NVF DAG configuration hook and is used for the workspace hardening Lua setup.
- `vim.extraPackages` is supported by the Neovim wrapper and exposes `gitleaks` to the `:NvfScanSecrets` command.
- `vim.diagnostics.enable` and `vim.diagnostics.config` are supported and map to Neovim diagnostic configuration; Phase 4 sets insert-mode updates off and enables severity sorting.
- First-class NVF workspace trust, root, or large-file guard options were not available in the pinned schema, so Phase 4 uses explicit Lua commands/autocmds and documents the policy in `docs/neovim-ide.md`.

## GREEN validation

Commands:

```bash
bash scripts/check-nvf-baseline.sh
bash scripts/check-nvf-phase2.sh
bash scripts/check-nvf-phase3.sh
bash scripts/check-nvf-phase4.sh
nixfmt --check home/modules/nvf/*.nix
nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage
nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage
nix eval --raw --no-write-lock-file .#homeConfigurations.terminalman.config.programs.nvf.settings.vim.luaConfigRC.workspace-hardening.data >/tmp/nvf-hardening-lua.txt
nvim --headless -u NORC -c 'luafile /tmp/nvf-hardening-lua.txt' -c 'qa'
```

Result: all commands passed on 2026-05-31.

```text
ok - Nix LSP uses nixd without nil_ls by default
ok - LSP ergonomics keymaps use exact NVF Lua command actions
ok - Neovim IDE guide stub records Phase 0 decisions without overclaiming
ok - README NVF inventory mirrors imported modules and links the IDE guide
ok - Phase 2 NVF module files exist
ok - Phase 2 NVF modules are imported immediately after languages.nix
ok - terminalman enables Python, web, infrastructure, and effective ESLint linter mappings
ok - README, operations guide, and evidence index document Phase 2 modules
ok - Phase 3 testing module exists
ok - Phase 3 testing module is imported after infra languages and before completion
ok - terminalman enables shared DAP UI, Neotest plugins/adapters, and test/debug keymaps
ok - Tidal live-coding mappings no longer own leader-t chords
ok - Phase 3 evidence file exists and is linked from the evidence index
ok - Phase 3 ticket files and index consistently mark completed work done
ok - Phase 4 hardening module exists
ok - Phase 4 hardening module is imported after testing and before completion
ok - terminalman enables workspace hardening, throttled diagnostics, gitleaks, and explicit task mapping
ok - README, operations guide, and evidence index document Phase 4 hardening
ok - Phase 4 ticket files and index consistently mark completed work done
ok - nixfmt --check home/modules/nvf/*.nix
ok - terminalman dry-run
ok - sandmhan dry-run
ok - workspace hardening Lua smoke test
```

The Home Manager evaluations emitted the existing `gtk.gtk4.theme` state-version warning for Linux profiles. It is unrelated to NVF Phase 4 and did not block evaluation.

## Runtime notes

The hardening module does not execute project-local code automatically. Runtime validation of `:NvfScanSecrets` requires a workspace where running gitleaks is acceptable; findings are redacted and opened in quickfix by design.
