---
title: Neovim IDE Operations Guide
status: draft
updated: 2026-05-31
---

# Neovim IDE Operations Guide

This guide is the implementation-facing companion to the [NVF Enterprise Polyglot IDE Improvement Report](./nvf-enterprise-polyglot-ide-improvement-report.md). The report remains the canonical architecture plan for language ownership, keymap taxonomy, rollout order, and validation expectations.

## Current implementation

The Home Manager NVF configuration is composed from `home/modules/nvf/default.nix` and enabled for terminal-derived profiles through `home/modules/terminal.nix`.

Supported editor language coverage today is intentionally limited to the modules already imported by `default.nix`:

- Markdown with Marksman and rendered/preview workflows.
- Nix with `nixd` as the default language server and `nixfmt` formatting.
- Typst with Tinymist and Typstyle.
- C/C++ with Clang tooling and the existing DAP settings.
- Python with basedpyright, Ruff formatting/linting, and debugpy from `home/modules/nvf/languages-python.nix`.
- JavaScript/TypeScript with `ts_ls`, prettierd, eslint_d, and JS debug adapter ownership from `home/modules/nvf/languages-web.nix`.
- JSON with `jsonls` and `jsonfmt` from `home/modules/nvf/languages-web.nix`.
- Terraform/OpenTofu, HCL, YAML/Kubernetes/Compose, Dockerfile, Bash, and TOML support from `home/modules/nvf/languages-infra.nix`.
- Haskell/Tidal live-coding support from `home/modules/nvf/tidal.nix`.

## Phase 0 decisions

- The approved improvement report is the canonical plan for the NVF IDE rollout.
- Nix LSP ownership is singular by default: `nixd` is enabled and `nil_ls` is disabled unless a later ticket documents a deliberate split.
- `home/modules/nvf/languages.nix` remains the shared/core language module. Future Python, web, infrastructure, testing, hardening, and AI work should use focused modules before being imported by `default.nix`.
- The keymap taxonomy from the report is adopted as the namespace policy. Mapping descriptions are the current WhichKey label source and must stay synchronized with implemented keys.
- Tidal keeps its existing buffer-local `<leader>t*` mappings for now. Future global test mappings under `<leader>t` must avoid those chords or migrate Tidal to `<localleader>` in the same change.

## Keymap namespaces

| Prefix | Owner |
|---|---|
| `<leader><leader>` | File picker |
| `<leader>/` | Live grep |
| `<leader>f` | Find/search |
| `<leader>g` | Git |
| `<leader>l` | LSP navigation and ergonomics |
| `<leader>x` | Diagnostics/trouble |
| `<leader>r` | Planned refactoring actions |
| `<leader>t` | Planned tests/tasks; currently reserved around Tidal buffer-local mappings |
| `<leader>d` | Planned debugging actions |
| `<leader>a` | Planned AI actions |
| `<leader>u` | UI toggles |
| `<localleader>` | Language-local actions when global namespaces would collide |

## Validation

Run these checks after changing NVF behavior:

```bash
bash scripts/check-nvf-baseline.sh
bash scripts/check-nvf-phase2.sh
nixfmt home/modules/nvf/*.nix
nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage
nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage
```

Activate with `make terminalman` only when it is safe to update the local profile. After activation, run `nvim --headless "+checkhealth" "+qa"` when runtime health evidence is needed.

## Project CI parity

Phase 2 editor integrations intentionally mirror project-local CI commands without adding Phase 3 task runner keymaps:

- Python: run project-selected pytest commands such as `pytest`, `uv run pytest`, or `nix develop -c pytest` alongside Ruff checks (`ruff check`, `ruff format --check`).
- JavaScript/TypeScript/JSON: run package-manager checks such as `npm test`, `npm run lint`, `pnpm test`, `pnpm lint`, `yarn test`, or `yarn lint` according to each repository.
- Infrastructure: run project checks such as `tofu fmt -check`, `tofu validate`, `terraform fmt -check`, `yamllint`, `kubeconform`, `docker compose config`, `hadolint`, `shellcheck`, `shfmt -d`, `taplo fmt --check`, and `tombi lint` where applicable.

## Planned, not yet implemented

Later phases will fill in Rust, Go, Lua, SQL, test runner, debug keymap, workspace hardening, and AI bridge workflows. This guide does not claim those behaviors are available until their implementation tickets land.
