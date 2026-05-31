---
title: NVF Phase 2 Enterprise Language Evidence
status: accepted
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

Commands:

```bash
bash scripts/check-nvf-baseline.sh
bash scripts/check-nvf-phase2.sh
nixfmt home/modules/nvf/*.nix
nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage
nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage
nix build --dry-run --no-write-lock-file .#homeConfigurations.wslman.activationPackage
nix build --dry-run --no-write-lock-file .#homeConfigurations.macman.activationPackage
```

Result: all commands passed on 2026-05-31.

```text
ok - Nix LSP uses nixd without nil_ls by default
ok - LSP ergonomics keymaps use exact NVF Lua command actions
ok - Neovim IDE guide stub records Phase 0 decisions without overclaiming
ok - README NVF inventory mirrors imported modules and links the IDE guide
ok - Phase 2 NVF module files exist
ok - Phase 2 NVF modules are imported immediately after languages.nix
ok - terminalman enables Python, web, and infrastructure Phase 2 language ownership
ok - README, operations guide, and evidence index document Phase 2 modules
ok - nixfmt home/modules/nvf/*.nix
ok - terminalman dry-run
ok - sandmhan dry-run
ok - wslman dry-run
ok - macman dry-run
```

The Home Manager evaluations emitted the existing `gtk.gtk4.theme` state-version warning for Linux profiles. It is unrelated to NVF Phase 2 and did not block evaluation. No profiles were skipped.

## Follow-up remediation validation

Reviewer follow-up found that pinned NVF only derived `eslint_d` nvim-lint mappings for TypeScript filetypes. `languages-web.nix` now wires JavaScript filetypes explicitly, and `scripts/check-nvf-phase2.sh` asserts the effective final mappings for `javascript`, `javascriptreact`, `typescript`, and `typescriptreact`.

Commands:

```bash
bash scripts/check-nvf-phase2.sh
bash scripts/check-nvf-baseline.sh
nixfmt --check home/modules/nvf/languages-web.nix home/modules/nvf/languages-python.nix
repo_root="$(pwd)"
nix eval --json --no-write-lock-file --impure --expr "let flake = builtins.getFlake \"path:$repo_root\"; linters = flake.homeConfigurations.terminalman.config.programs.nvf.settings.vim.diagnostics.nvim-lint.linters_by_ft; in { inherit (linters) javascript javascriptreact typescript typescriptreact; }"
nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage
nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage
nix build --dry-run --no-write-lock-file .#homeConfigurations.wslman.activationPackage
nix build --dry-run --no-write-lock-file .#homeConfigurations.macman.activationPackage
```

Result: all commands passed on 2026-05-31. The focused mapping eval returned:

```json
{"javascript":["eslint_d"],"javascriptreact":["eslint_d"],"typescript":["eslint_d"],"typescriptreact":["eslint_d"]}
```
