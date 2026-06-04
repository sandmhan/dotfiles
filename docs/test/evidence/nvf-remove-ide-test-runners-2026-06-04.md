---
title: NVF IDE Test Runner Removal Evidence
status: accepted
updated: 2026-06-04
---

# NVF IDE Test Runner Removal Evidence

Validation for removing IDE-integrated test runner wiring while preserving DAP/debugging.

## Commands and results

```bash
nixfmt home/modules/nvf/debugging.nix home/modules/nvf/default.nix home/modules/nvf/languages-python.nix home/modules/nvf/languages-web.nix
```

Result: passed; no output.

```bash
nixfmt --check home/modules/nvf/debugging.nix home/modules/nvf/default.nix home/modules/nvf/languages-python.nix home/modules/nvf/languages-web.nix
```

Result: passed; no output.

```bash
bash -n scripts/check-nvf-phase3.sh scripts/check-nvf-phase4.sh
```

Result: passed; no output.

```bash
bash scripts/check-nvf-phase3.sh
```

Result: passed. The check confirmed `debugging.nix` is imported, `testing.nix` is absent, DAP UI/debug keymaps remain, and Neotest plugins/test keymaps are absent from `terminalman`. Nix emitted the existing `gtk.gtk4.theme` state-version warning.

```bash
bash scripts/check-nvf-phase4.sh
```

Result: passed. The check confirmed hardening still imports after debugging and before completion. Nix emitted the existing `gtk.gtk4.theme` state-version warning.

```bash
bash scripts/check-nvf-phase6.sh
```

Result: passed. README NVF inventory and operations-guide drift checks passed.

```bash
nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage
```

Initial result: failed because new `home/modules/nvf/debugging.nix` was not yet tracked by Git, so the flake source copy omitted it. After `git add -N home/modules/nvf/debugging.nix` for validation source inclusion, rerun result: passed dry-run; Nix reported 13 derivations that would be built and emitted the dirty-tree warning plus the existing `gtk.gtk4.theme` state-version warning.

```bash
nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage
```

Result: passed dry-run after `git add -N home/modules/nvf/debugging.nix`; Nix reported 13 derivations that would be built and emitted the dirty-tree warning.

```bash
! rg -n "neotest|Neotest|vim-test|coverage UI|Test nearest|Test file|Test suite|Debug nearest test" home/modules/nvf README.md docs/neovim-ide.md docs/nvf-enterprise-polyglot-ide-improvement-report.md
```

Result: passed; no active NVF module, README entry, operations-guide section, or architecture-report entry still advertises the removed IDE test-runner integrations.

## Notes

Runtime `nvim --headless` checks were not run because the Home Manager profile was not activated in this task. Historical tickets and older evidence files still describe the previous Phase 3 Neotest implementation as history, not current behavior.
