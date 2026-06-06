---
title: Neovim IDE Operations Guide
status: accepted
updated: 2026-06-04
---

# Neovim IDE Operations Guide

This guide is the implementation-facing companion to the [NVF Enterprise Polyglot IDE Improvement Report](./nvf-enterprise-polyglot-ide-improvement-report.md). It is the current source of truth for implemented behavior and supersedes older roadmap items that proposed IDE-integrated test runners.

## Current implementation

The Home Manager NVF configuration is composed from `home/modules/nvf/default.nix` and exported as the reusable flake module `homeManagerModules.sandvim` (also aliased as `homeManagerModules.default`). The exported module imports upstream `nvf.homeManagerModules.default` plus this repository's Sandvim modules, and external consumers enable it with `programs.sandvim.enable = true`.

This repository's local profiles preserve the existing `myHome` interface through a flake-local adapter, which maps `myHome.features.enableNixvim` to `programs.sandvim.enable`. The reusable Sandvim module itself does not depend on `home/options.nix` or `config.myHome`.

### Portable API and smoke test

The public Sandvim option API is intentionally minimal while the module remains hosted in this dotfiles flake pending extraction:

- `programs.sandvim.enable` enables the NVF-backed editor, including the CodeCompanion Codex ACP chat workflow.

External consumers import `dotfiles.homeManagerModules.sandvim` in their Home Manager module list and set `programs.sandvim.enable = true`. They do not need this repo's local profiles, Stylix module, or `myHome` options.

The flake check `checks.x86_64-linux.sandvimExternalConsumer` is the repo-native portability smoke test. It builds a minimal external-consumer Home Manager activation package using only `homeManagerModules.sandvim`, `programs.sandvim.enable = true`, and the required `home.*` identity/state options:

```bash
nix build --no-write-lock-file .#checks.x86_64-linux.sandvimExternalConsumer
```

Supported editor language coverage today is intentionally limited to the modules already imported by `default.nix`:

- Markdown with Marksman and rendered/preview workflows.
- Nix with `nixd` as the default language server and `nixfmt` formatting.
- Typst with Tinymist and Typstyle.
- C/C++ with Clang tooling and the existing DAP settings.
- Python with basedpyright, Ruff formatting/linting, and debugpy from `home/modules/nvf/languages-python.nix`.
- JavaScript/TypeScript with `ts_ls`, prettierd, eslint_d, and JS debug adapter ownership from `home/modules/nvf/languages-web.nix`.
- JSON with `jsonls` and `jsonfmt` from `home/modules/nvf/languages-web.nix`.
- Terraform/OpenTofu, HCL, YAML/Kubernetes/Compose, Dockerfile, Bash, and TOML support from `home/modules/nvf/languages-infra.nix`.
- DAP UI and supplemental debug keymaps from `home/modules/nvf/debugging.nix`; IDE-integrated test runners are intentionally not configured.
- Workspace hardening from `home/modules/nvf/hardening.nix`: root discovery commands, explicit local trust policy, large/generated-file guards, diagnostic throttling, and an on-demand gitleaks secret scan task.
- CodeCompanion.nvim from `home/modules/nvf/ai-codecompanion.nix` as the only in-editor AI tool, using Codex ACP through `codex-acp` with ChatGPT authentication when `programs.sandvim.enable` is enabled.
- Haskell/Tidal live-coding support from `home/modules/nvf/tidal.nix`.

Behavior not listed above is optional, project-local, or planned. Later adoption candidates such as Rust, Go, Lua, SQL, richer refactoring flows, and additional language-specific task runners are not implemented until their modules and tickets land.

## Required tools and ownership

Most tools are provided by NVF or by Nix packages referenced from the Home Manager modules. Project-local test runners, dependencies, and devshells own CI parity and are run outside Neovim.

| Area | Implemented editor owner | Required or expected tools |
|---|---|---|
| Markdown | `languages.nix` | Marksman, prettierd, render-markdown-nvim/markdown preview plugins from NVF/Nix |
| Nix | `languages.nix`, `lsp.nix` | `nixd`, `nixfmt`; keep `nil_ls` disabled unless a ticket documents a split |
| Typst | `languages.nix` | Tinymist and Typstyle |
| C/C++ | `languages.nix` | Clangd plus the configured LLDB DAP adapter |
| Python | `languages-python.nix` | basedpyright, Ruff, and debugpy; run pytest from the project CLI/devshell when needed |
| JavaScript/TypeScript | `languages-web.nix` | `ts_ls`, prettierd, eslint_d, and vscode-js-debug; run Jest/Vitest/package-manager tests from the project CLI when needed |
| JSON | `languages-web.nix` | jsonls and jsonfmt |
| Terraform/OpenTofu and HCL | `languages-infra.nix` | tofuls, `tofu fmt`, hclfmt; project validation still runs `tofu validate` or `terraform validate` where applicable |
| YAML/Kubernetes/Compose | `languages-infra.nix` | yaml-language-server; project validation may add yamllint, kubeconform, or `docker compose config` |
| Dockerfile | `languages-infra.nix` | dockerfile-language-server, Dockerfile Treesitter grammar, hadolint |
| Bash | `languages-infra.nix` | bash-language-server, shfmt, shellcheck |
| TOML | `languages-infra.nix` | taplo and tombi |
| Debugging | `debugging.nix`, language modules | DAP UI, debugpy, vscode-js-debug, and supplemental debug keymaps |
| Workspace safety | `hardening.nix` | root marker policy, disabled local config/modelines, generated-file guards, gitleaks scan wrapper |
| Neovim AI | `ai-codecompanion.nix` | CodeCompanion.nvim through NVF; `codex-acp` installed by the feature; ChatGPT authentication (`auth_method = "chatgpt"`) from a prior Codex/ChatGPT login rather than an API key |
| Standalone AI CLIs | `home/modules/ai-*.nix` | Claude, Codex, and Pi remain Home Manager CLI/TUI tools outside Neovim |
| Tidal/Haskell | `tidal.nix` | haskell-language-server, haskell-tools, `tidal.nvim`, `tidal-ghci` from the project or bundled fallback |

## Phase 0 decisions

- The approved improvement report is the canonical plan for the NVF IDE rollout.
- Nix LSP ownership is singular by default: `nixd` is enabled and `nil_ls` is disabled unless a later ticket documents a deliberate split.
- `home/modules/nvf/languages.nix` remains the shared/core language module. Python, web, infrastructure, debugging, hardening, and AI use focused modules before being imported by `default.nix`; future language or workflow work should follow that pattern.
- The keymap taxonomy from the report is adopted as the namespace policy. Mapping descriptions are the current WhichKey label source and must stay synchronized with implemented keys.
- Tidal live-coding mappings are buffer-local under `<localleader>t*`, leaving global `<leader>t*` chords available for explicit workspace tasks.

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
| `<leader>t` | Explicit workspace tasks only; currently `<leader>tS` runs the secret scan |
| `<leader>d` | Debugging via NVF DAP defaults plus supplemental pause, conditional breakpoint, clear, and scopes actions |
| `<leader>a` | AI actions: CodeCompanion chat on `ac`; command/inline action-palette workflows are not exposed for the Codex ACP adapter |
| `<leader>u` | UI toggles |
| `<localleader>` | Language-local actions when global namespaces would collide |

## Workspace hardening

`home/modules/nvf/hardening.nix` defines the Phase 4 workspace policy without silently executing project-local code.

- Root detection uses the first matching marker from `flake.nix`, `.envrc`, `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, JVM build files, Terraform/OpenTofu files, or `.git`. Use `:NvfWorkspaceRoot` to inspect the detected root for the current buffer or `:NvfWorkspaceRoot <path>` for another path.
- Local Neovim config execution is disabled with `exrc = false` and modelines disabled. Use `:NvfWorkspacePolicy` to show the active policy; trusted project bootstrapping must stay explicit through shell/devshell commands rather than automatic editor hooks.
- Large/generated-file guards apply to files above 1 MiB, buffers above 20,000 lines, and dependency/generated paths such as `.git`, `node_modules`, `dist`, `build`, `target`, `.terraform`, `.next`, coverage output, lock files, minified JavaScript, and generated paths. Guarded buffers disable diagnostics, stop Treesitter when possible, and detach LSP clients to reduce monorepo and generated-file churn.
- Secret scanning is an explicit task only. `:NvfScanSecrets` and `<leader>tS` run `gitleaks detect --no-git --redact --source <workspace-root>` using the Nix-provided wrapper package. Pass a directory to scan a different root. Findings open in the quickfix list.
- Diagnostic throttling is intentionally conservative: diagnostics do not update in insert mode, severity sorting is enabled, and guarded buffers disable diagnostics entirely.

## Neovim AI: CodeCompanion Codex ACP

`home/modules/nvf/ai-codecompanion.nix` is the only Neovim AI integration. It enables NVF's `vim.assistant.codecompanion-nvim`, installs `codex-acp`, and selects the CodeCompanion `codex` ACP adapter for chat.

Authentication is ChatGPT-based: the adapter sets `auth_method = "chatgpt"` and clears adapter environment variables, so no `OPENAI_API_KEY`, `OPENAI_BASE_URL`, or model secret is committed to Nix. Run the Codex/ChatGPT login flow outside Neovim first and ensure the account has the required subscription/access for Codex ACP.

Implemented mappings and commands:

| Key | Command | Scope |
|---|---|---|
| `<leader>ac` | `:CodeCompanionChat` | Chat workflow using the Codex ACP adapter |

Configured boundaries:

- CodeCompanion chat uses `adapter = "codex"`. Command (`:CodeCompanionCmd`) and inline/action-palette interactions are HTTP-adapter-only upstream, so this profile does not point them at the Codex ACP adapter and does not expose action-palette prompt workflows.
- The configured Codex adapter launches `codex-acp`, uses `auth_method = "chatgpt"`, disables inherited MCP servers with `mcpServers = {}`, and uses a 20 second adapter timeout.
- Avante.nvim, the prior `NvfAi*` bridge commands, and Neovim Pi/Claude/Codex CLI bridge mappings are removed from the active NVF imports. Claude, Codex, and Pi remain standalone Home Manager tools outside Neovim.
- API-key HTTP workflows are intentionally not configured. CodeCompanion may still register upstream default commands such as `:CodeCompanion` or `:CodeCompanionCmd`, but this profile documents and maps only `:CodeCompanionChat` / chat prompt workflows for the Codex ACP path.
- Rules chat autoload is disabled, action-palette default/preset action and prompt display is hidden, chat variables are empty, built-in slash commands are disabled, and default chat tools are not auto-loaded. These settings reduce automatic context/tool surface; they are not a substitute for reviewing what you send in chat.

Privacy boundary: CodeCompanion does not provide the retired bridge's pre-send secret redaction, sensitive-path blocking, confirmation summary, or full-buffer-selection guard. Do not send secrets, private keys, `.env` content, or broad repository context through the plugin.

## Troubleshooting

Start with the smallest scope that reproduces the issue.

- Language server missing: confirm the affected profile has activated, run `:LspInfo`, and verify the tool appears in the required-tools table above. For project-local tools, enter the project devshell or package-manager environment first.
- Duplicate diagnostics: check the owning language module and disable overlapping project plugins before adding a second NVF source. Nix should stay on `nixd` only by default.
- Slow or noisy workspaces: inspect `:NvfWorkspaceRoot`, `:NvfWorkspacePolicy`, `:echo b:nvf_workspace_guard`, and `nvim --startuptime /tmp/nvim-startuptime.log +qa` before changing global defaults.
- Debug adapter failures: reproduce with the matching CLI command outside Neovim when possible, then inspect `:DapShowLog` and `:messages`. The editor does not install project dependencies or run project tests.
- CodeCompanion unavailable: confirm `programs.sandvim.enable` is true for the active profile, run `:CodeCompanionChat`, and verify `codex-acp` is on `PATH`. Do not use `:CodeCompanionCmd` or inline/action-palette prompts with the Codex ACP adapter unless a supported HTTP adapter is configured separately.
- Codex ACP authentication failures: complete the Codex/ChatGPT login flow outside Neovim first. This configuration uses `auth_method = "chatgpt"` and does not read `OPENAI_API_KEY` from Nix.
- Tidal issues: prefer a project `tidal-ghci` when available; otherwise the bundled fallback from `tidal.nix` is used. Tidal mappings are buffer-local under `<localleader>`.

## Health checks and profiling

Use runtime checks after activation when editor behavior changes or performance regresses:

```bash
nvim --headless "+checkhealth" "+qa"
nvim --headless -c 'if exists(":CodeCompanionChat") != 2 | cquit | endif' -c 'qa!'
nvim --headless -c 'if exists(":AvanteAsk") == 2 | cquit | endif' -c 'qa!'
nvim --headless -c 'if exists(":NvfAiAsk") == 2 | cquit | endif' -c 'qa!'
nvim --headless "+checkhealth vim.lsp" "+qa"
nvim --headless "+checkhealth nvim-treesitter" "+qa"
nvim --headless "+checkhealth dap" "+qa"
nvim --startuptime /tmp/nvim-startuptime.log +qa
```

Inside Neovim, inspect `:LspInfo`, `:checkhealth`, `:TSModuleInfo`, `:DapShowLog`, `:messages`, and guarded-buffer state with `:echo b:nvf_workspace_guard`. Prefer filetype-scoped or lazy-loaded additions when NVF supports them, and update this guide with validation evidence whenever a new language, adapter, or plugin changes startup behavior.

## Adding or changing a language

1. Open a ticket tied to the NVF report or a follow-up maintenance finding. State the filetypes, LSP, formatter, linter, debug ownership, CLI validation commands, keymaps, and affected profiles.
2. Add focused module code under `home/modules/nvf/` when the language is large enough to own separately. Keep `languages.nix` for shared/core coverage.
3. Import the module from `home/modules/nvf/default.nix` in a deterministic position near related language or workflow modules.
4. Update the README NVF module inventory in the same change. The table must contain exactly the same imported modules as `default.nix`, with accurate descriptions.
5. Update this guide with implemented behavior only, including required tools, project-local CI parity, troubleshooting, validation evidence, and any explicitly planned follow-ups.
6. Add or update a targeted `scripts/check-nvf-phase*.sh` validator when the change has repeatable assertions.
7. Run formatting and validation, record evidence under `docs/test/evidence/`, and close the ticket only after the evidence is linked.

## Validation

Run these checks after changing NVF behavior:

```bash
bash scripts/check-nvf-baseline.sh
bash scripts/check-nvf-phase2.sh
bash scripts/check-nvf-phase3.sh
bash scripts/check-nvf-phase4.sh
bash scripts/check-nvf-phase5.sh
bash scripts/check-nvf-phase6.sh
bash scripts/check-nvf-phase7.sh
nixfmt home/modules/nvf/*.nix flake.nix home/modules/terminal.nix
nix flake show --no-write-lock-file
nix build --no-write-lock-file .#checks.x86_64-linux.sandvimExternalConsumer
nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage
nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage
```

For runtime validation without activation, build the configured Neovim package and invoke it directly:

```bash
nix build --no-write-lock-file .#homeConfigurations.terminalman.config.programs.nvf.finalPackage -o result-sandvim-nvim
./result-sandvim-nvim/bin/nvim --headless "+checkhealth" "+qa"
./result-sandvim-nvim/bin/nvim --headless -c 'if exists(":CodeCompanionChat") != 2 | cquit | endif' -c 'qa!'
./result-sandvim-nvim/bin/nvim --headless -c 'if exists(":AvanteAsk") == 2 | cquit | endif' -c 'if exists(":NvfAiAsk") == 2 | cquit | endif' -c 'qa!'
```

Activate with `make terminalman` only when it is safe to update the local profile. True activation is only required to validate profile activation hooks, shell integration, or the user's active `nvim` command; packaged Neovim startup and command-registration checks can run from the built `finalPackage` without activation. After activation, run `nvim --headless "+checkhealth" "+qa"` when runtime health evidence is needed.

## Validation evidence expectations

PRs or agent changes that alter editor behavior must include evidence in the PR body or in a dated file under `docs/test/evidence/`.

Required evidence for NVF changes:

- The exact validation commands run and whether each passed.
- Home Manager dry-run coverage for every affected profile. At minimum, run `nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage` and `nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage` when shared Linux NVF behavior changes; include `macman` or `wslman` if the change affects those profiles or platform-specific packages.
- Runtime health evidence after activation when plugin startup, LSP, Treesitter, DAP, or AI behavior changes. Use the headless `checkhealth` commands above, and include `:LspInfo`, `:TSModuleInfo`, `:DapShowLog`, `:messages`, or startup profiling notes when relevant.
- README and `docs/neovim-ide.md` drift checks for import, language, keymap, or workflow changes.
- Skipped validation with an explicit reason and the affected profile list, for example: `Skipped: macman dry-run (no Darwin builder available); affected profiles: macman only`.

## README import synchronization

`README.md` is the discoverable module inventory. Any change to `home/modules/nvf/default.nix` imports must update the README table in the same patch and run `bash scripts/check-nvf-phase6.sh`. Stale inventory entries should be fixed immediately rather than deferred to later documentation cleanup.

## Pinned source and tool review cadence

Review NVF-related pinned sources and language tools monthly, and immediately before a broad flake update or editor rollout.

| Source | Current pin or owner | Review expectations |
|---|---|---|
| Upstream `nvf` flake input | `flake.lock` entry for `github:NotAShelf/nvf` | Check release notes, option/schema changes, breaking migrations, open security issues, and whether existing phase validators still pass. |
| Custom Tidal plugin | `home/modules/nvf/tidal.nix` pin for `grddavies/tidal.nvim` | Check upstream commits/tags, plugin activity, hash/rev provenance, Neovim compatibility, and supply-chain risk before bumping. |
| Language tools from Nixpkgs/NVF | LSPs, formatters, linters, and DAP adapters | Review package availability across Linux, Darwin, WSL, and headless profiles. Validate schema or command changes before accepting updates. |
| Project-local runners | pytest, Jest, Vitest, Terraform/OpenTofu, Kubernetes, Docker, shell tooling | Document CI parity changes in the owning project and do not imply editor support for tools that are only optional/project-local. |

Document each review in a dated evidence file or ticket workflow log. Open follow-up tickets for risky updates, breaking schema changes, inactive external sources, security advisories, or changes that require profile-specific validation.

## Project CI parity

IDE-integrated test runners are intentionally not configured; project-local commands remain the source of truth for CI parity:

- Python: run project-selected pytest commands such as `pytest`, `uv run pytest`, or `nix develop -c pytest` alongside Ruff checks (`ruff check`, `ruff format --check`).
- JavaScript/TypeScript/JSON: run package-manager checks such as `npm test`, `npm run lint`, `pnpm test`, `pnpm lint`, `yarn test`, or `yarn lint` according to each repository.
- Debugging: NVF supplies continue/restart/terminate/step/REPL/UI mappings for nvim-dap. `debugging.nix` adds pause, conditional breakpoints, clear breakpoints, and scopes float mappings, while Python and JavaScript/TypeScript adapter ownership remains in the language modules.
- Infrastructure: run project checks such as `tofu fmt -check`, `tofu validate`, `terraform fmt -check`, `yamllint`, `kubeconform`, `docker compose config`, `hadolint`, `shellcheck`, `shfmt -d`, `taplo fmt --check`, and `tombi lint` where applicable.

## Planned, not yet implemented

Later phases will fill in Rust, Go, Lua, and SQL workflows. This guide does not claim those behaviors are available until their implementation tickets land.
