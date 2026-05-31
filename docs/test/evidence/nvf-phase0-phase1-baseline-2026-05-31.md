---
title: NVF Phase 0 and Phase 1 Baseline Evidence
status: accepted
updated: 2026-05-31
---

# NVF Phase 0 and Phase 1 Baseline Evidence

## RED

```bash
bash scripts/check-nvf-baseline.sh
```

Initial result before implementation: failed because `nil_ls` was still enabled, the new LSP ergonomics mappings were absent, `docs/neovim-ide.md` did not exist, and the README NVF inventory was stale.

## GREEN

```bash
bash scripts/check-nvf-baseline.sh
nixfmt home/modules/nvf/*.nix
nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage
nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage
```

Final result: all baseline assertions passed, Nix files were formatted, and both Home Manager dry-runs evaluated successfully.
