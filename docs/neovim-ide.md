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
- Neotest Python, Jest, and Vitest adapters plus DAP UI and shared test/debug keymaps from `home/modules/nvf/testing.nix`.
- Workspace hardening from `home/modules/nvf/hardening.nix`: root discovery commands, explicit local trust policy, large/generated-file guards, diagnostic throttling, and an on-demand gitleaks secret scan task.
- Haskell/Tidal live-coding support from `home/modules/nvf/tidal.nix`.

## Phase 0 decisions

- The approved improvement report is the canonical plan for the NVF IDE rollout.
- Nix LSP ownership is singular by default: `nixd` is enabled and `nil_ls` is disabled unless a later ticket documents a deliberate split.
- `home/modules/nvf/languages.nix` remains the shared/core language module. Python, web, infrastructure, testing, and hardening now use focused modules before being imported by `default.nix`; future AI work should follow that pattern.
- The keymap taxonomy from the report is adopted as the namespace policy. Mapping descriptions are the current WhichKey label source and must stay synchronized with implemented keys.
- Tidal live-coding mappings are buffer-local under `<localleader>t*`, leaving global `<leader>t*` chords available for test workflows.

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
| `<leader>t` | Tests/tasks via Neotest (`tn`, `tf`, `ta`, `tr`, `to`, `ts`, `tw`, `tD`) plus explicit workspace tasks (`tS` for secret scan) |
| `<leader>d` | Debugging via NVF DAP defaults plus supplemental pause, conditional breakpoint, clear, and scopes actions |
| `<leader>a` | Planned AI actions |
| `<leader>u` | UI toggles |
| `<localleader>` | Language-local actions when global namespaces would collide |

## Workspace hardening

`home/modules/nvf/hardening.nix` defines the Phase 4 workspace policy without silently executing project-local code.

- Root detection uses the first matching marker from `flake.nix`, `.envrc`, `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, JVM build files, Terraform/OpenTofu files, or `.git`. Use `:NvfWorkspaceRoot` to inspect the detected root for the current buffer or `:NvfWorkspaceRoot <path>` for another path.
- Local Neovim config execution is disabled with `exrc = false` and modelines disabled. Use `:NvfWorkspacePolicy` to show the active policy; trusted project bootstrapping must stay explicit through shell/devshell commands rather than automatic editor hooks.
- Large/generated-file guards apply to files above 1 MiB, buffers above 20,000 lines, and dependency/generated paths such as `.git`, `node_modules`, `dist`, `build`, `target`, `.terraform`, `.next`, coverage output, lock files, minified JavaScript, and generated paths. Guarded buffers disable diagnostics, stop Treesitter when possible, and detach LSP clients to reduce monorepo and generated-file churn.
- Secret scanning is an explicit task only. `:NvfScanSecrets` and `<leader>tS` run `gitleaks detect --no-git --redact --source <workspace-root>` using the Nix-provided wrapper package. Pass a directory to scan a different root. Findings open in the quickfix list.
- Diagnostic throttling is intentionally conservative: diagnostics do not update in insert mode, severity sorting is enabled, and guarded buffers disable diagnostics entirely.

## Health checks and profiling

Use runtime checks after activation when editor behavior changes or performance regresses:

```bash
nvim --headless "+checkhealth" "+qa"
nvim --headless "+checkhealth vim.lsp" "+qa"
nvim --headless "+checkhealth nvim-treesitter" "+qa"
nvim --headless "+checkhealth dap" "+qa"
nvim --startuptime /tmp/nvim-startuptime.log +qa
```

Inside Neovim, inspect `:LspInfo`, `:checkhealth`, `:TSModuleInfo`, `:DapShowLog`, `:messages`, and guarded-buffer state with `:echo b:nvf_workspace_guard`. Prefer filetype-scoped or lazy-loaded additions when NVF supports them, and update this guide with validation evidence whenever a new language, adapter, or plugin changes startup behavior.

## Validation

Run these checks after changing NVF behavior:

```bash
bash scripts/check-nvf-baseline.sh
bash scripts/check-nvf-phase2.sh
bash scripts/check-nvf-phase3.sh
bash scripts/check-nvf-phase4.sh
nixfmt home/modules/nvf/*.nix
nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage
nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage
```

Activate with `make terminalman` only when it is safe to update the local profile. After activation, run `nvim --headless "+checkhealth" "+qa"` when runtime health evidence is needed.

## Project CI parity

Neotest keymaps are convenience wrappers for interactive local feedback; project-local commands remain the source of truth for CI parity:

- Python: run project-selected pytest commands such as `pytest`, `uv run pytest`, or `nix develop -c pytest` alongside Ruff checks (`ruff check`, `ruff format --check`). The editor adapter uses pytest and depends on project-local test dependencies being available.
- JavaScript/TypeScript/JSON: run package-manager checks such as `npm test`, `npm run lint`, `pnpm test`, `pnpm lint`, `yarn test`, or `yarn lint` according to each repository. The editor adapters call project-local Jest/Vitest through `npx`.
- Debugging: NVF supplies continue/restart/terminate/step/REPL/UI mappings for nvim-dap. `testing.nix` adds pause, conditional breakpoints, clear breakpoints, and scopes float mappings, while Python and JavaScript/TypeScript adapter ownership remains in the language modules.
- Infrastructure: run project checks such as `tofu fmt -check`, `tofu validate`, `terraform fmt -check`, `yamllint`, `kubeconform`, `docker compose config`, `hadolint`, `shellcheck`, `shfmt -d`, `taplo fmt --check`, and `tombi lint` where applicable.

## Planned, not yet implemented

Later phases will fill in Rust, Go, Lua, SQL, and AI bridge workflows. This guide does not claim those behaviors are available until their implementation tickets land.
