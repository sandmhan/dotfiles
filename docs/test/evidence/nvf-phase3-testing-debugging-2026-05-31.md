---
title: NVF Phase 3 Testing and Debugging Evidence
status: accepted
updated: 2026-05-31
---

# NVF Phase 3 Testing and Debugging Evidence

## Scope

Phase 3 validation for NVF testing and debugging workflows (`NVF-014`, `NVF-029`, `NVF-015`, `NVF-016`, and `NVF-017`): shared `testing.nix`, Neotest Python/Jest/Vitest adapters, DAP UI, global test/debug keymaps, and Tidal `<leader>t` migration.

## RED validation

Reviewer follow-up found the Phase 3 implementation structurally valid but incomplete as a tracked milestone because ticket files still had `status: open` and this evidence file was linked from the evidence index before it existed.

## Option schema validation

Confirmed implementation path for the pinned NVF input before marking Phase 3 done:

- `vim.debugger.nvim-dap.enable`, `vim.debugger.nvim-dap.ui.enable`, and `vim.debugger.nvim-dap.ui.autoStart` are valid for shared DAP UI ownership.
- NVF provides default DAP keymaps for continue, restart, terminate, REPL, breakpoints, and step controls when nvim-dap is enabled.
- First-class Neotest adapter options were not available in the pinned NVF schema, so `home/modules/nvf/testing.nix` uses `vim.extraPlugins` with explicit plugin packages and Lua `require("neotest").setup(...)`.
- Python `debugpy` ownership remains in `home/modules/nvf/languages-python.nix`; JavaScript/TypeScript `pwa-node` ownership remains in `home/modules/nvf/languages-web.nix`.

## GREEN validation

Commands:

```bash
bash scripts/check-nvf-baseline.sh
bash scripts/check-nvf-phase2.sh
bash scripts/check-nvf-phase3.sh
nixfmt --check home/modules/nvf/*.nix
nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage
nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage
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
ok - nixfmt --check home/modules/nvf/*.nix
ok - terminalman dry-run
ok - sandmhan dry-run
```

The Home Manager evaluations emitted the existing `gtk.gtk4.theme` state-version warning for Linux profiles. It is unrelated to NVF Phase 3 and did not block evaluation.

## Runtime notes

No project-specific Python/Jest/Vitest fixture is stored in this dotfiles repository. Runtime Neotest and DAP launches should be smoke-tested inside a target project that provides its own test dependencies and CI parity commands.
