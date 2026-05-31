---
title: NVF Phase 2 Enterprise Language Evidence
status: draft
updated: 2026-05-31
---

# NVF Phase 2 Enterprise Language Evidence

## Scope

Phase 2 validation for NVF core enterprise language coverage (`NVF-010` through `NVF-013`): Python, JavaScript/TypeScript/JSON, and infrastructure languages.

## RED validation

Command:

```bash
bash scripts/check-nvf-phase2.sh
```

Result: expected failure before the Phase 2 modules, imports, and documentation were implemented.

```text
not ok - Phase 2 NVF module files exist
not ok - Phase 2 NVF modules are imported immediately after languages.nix
evaluation warning: The default value of `gtk.gtk4.theme` has changed from `config.gtk.theme` to `null`.
                    You are currently using the legacy default (`config.gtk.theme`) because `home.stateVersion` is less than "26.05".
                    To silence this warning and keep legacy behavior, set:
                      gtk.gtk4.theme = config.gtk.theme;
                    To adopt the new default behavior, set:
                      gtk.gtk4.theme = null;
not ok - terminalman enables Python, web, and infrastructure Phase 2 language ownership
not ok - README, operations guide, and evidence index document Phase 2 modules
```

## Option schema validation

Pinned NVF source used for option checks:

```text
/nix/store/w95a27ylfdhd0ky3plxqc04wmc1ndxk0-source
```

Confirmed option families before implementation:

- `vim.languages.python`: `basedpyright`, `ruff`, `debugpy`, Python formatters, and DAP support.
- `vim.languages.ts`: `ts_ls`, `prettierd`, and `eslint_d` diagnostics.
- `vim.languages.json`: `jsonls` and JSON formatting.
- `vim.languages.terraform`, `hcl`, `yaml`, `bash`, and `toml`: LSP, formatter, Treesitter, and diagnostics options required by Phase 2.
- Custom integrations: `vim.lsp.servers`, `vim.diagnostics.nvim-lint`, and `vim.debugger.nvim-dap.sources`.

## GREEN validation

Pending implementation.
