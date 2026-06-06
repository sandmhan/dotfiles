---
title: NVF Sandvim Portability Evidence
status: accepted
---

# NVF Sandvim Portability Evidence

Date: 2026-06-05

## Scope

Validated the portable `homeManagerModules.sandvim` export, single-option public API, and safe runtime checks for the built Sandvim Neovim package. No Home Manager activation was performed.

## Commands and results

- `nixfmt flake.nix home/modules/nvf/*.nix home/modules/terminal.nix` — passed.
- `nixfmt --check flake.nix home/modules/nvf/*.nix home/modules/terminal.nix` — passed.
- `nix build --no-write-lock-file .#checks.x86_64-linux.sandvimExternalConsumer -o result-sandvim-external-smoke` — passed; built a minimal external-consumer Home Manager activation package importing only `homeManagerModules.sandvim` with `programs.sandvim.enable = true`.
- `nix build --no-write-lock-file .#homeConfigurations.terminalman.config.programs.nvf.finalPackage -o result-sandvim-nvim` — passed.
- `./result-sandvim-nvim/bin/nvim --headless "+checkhealth" "+qa"` — passed; checkhealth completed for blink.cmp, conform, dap, haskell-tools, lspconfig, markdown preview, null-ls, nvim-treesitter, render-markdown, vim health/LSP/treesitter/provider, and which-key.
- `./result-sandvim-nvim/bin/nvim --headless -c 'if exists(":CodeCompanionChat") != 2 | cquit | endif' -c 'qa!'` — passed.
- `./result-sandvim-nvim/bin/nvim --headless -c 'if exists(":AvanteAsk") == 2 | cquit | endif' -c 'if exists(":NvfAiAsk") == 2 | cquit | endif' -c 'qa!'` — passed.
- `bash scripts/check-nvf-baseline.sh && bash scripts/check-nvf-phase2.sh && bash scripts/check-nvf-phase3.sh && bash scripts/check-nvf-phase4.sh && bash scripts/check-nvf-phase5.sh && bash scripts/check-nvf-phase6.sh && bash scripts/check-nvf-phase7.sh` — passed.
- `nix flake show --no-write-lock-file` — passed.
- `nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage` — passed.
- `nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage` — passed.
- `nix build --dry-run --no-write-lock-file .#homeConfigurations.wslman.activationPackage` — passed.
- `nix build --dry-run --no-write-lock-file .#homeConfigurations.macman.activationPackage` — passed.

## Notes

True activation was intentionally skipped. The runtime checks invoked the built `programs.nvf.finalPackage` directly, which validates packaged Neovim startup and command registration without mutating the active user profile. Activation would only be required to validate Home Manager activation hooks, shell integration, or the user's active `nvim` command.

The public Sandvim option API remains intentionally minimal: `programs.sandvim.enable`. CodeCompanion/Codex ACP is included whenever Sandvim is enabled.
