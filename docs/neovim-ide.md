---
title: Neovim IDE Operations Guide
status: accepted
updated: 2026-06-01
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
- Guarded AI bridge workflows from `home/modules/nvf/ai.nix` for Claude Code, Codex CLI, and Pi provider entry points, with explicit confirmation, scoped context, size limits, sensitive-path blocking, and secret-like redaction before provider invocation.
- CodeCompanion.nvim from `home/modules/nvf/ai-companion.nix` for explicit OpenAI-compatible chat and selected-code edit/review/test prompts when `myHome.features.enableNvfAiCompanion` is enabled.
- Haskell/Tidal live-coding support from `home/modules/nvf/tidal.nix`.

Behavior not listed above is optional, project-local, or planned. Later adoption candidates such as Rust, Go, Lua, SQL, richer refactoring flows, and additional language-specific task runners are not implemented until their modules and tickets land.

## Required tools and ownership

Most tools are provided by NVF or by Nix packages referenced from the Home Manager modules. Project-local test runners, dependencies, and devshells still own CI parity.

| Area | Implemented editor owner | Required or expected tools |
|---|---|---|
| Markdown | `languages.nix` | Marksman, prettierd, render-markdown-nvim/markdown preview plugins from NVF/Nix |
| Nix | `languages.nix`, `lsp.nix` | `nixd`, `nixfmt`; keep `nil_ls` disabled unless a ticket documents a split |
| Typst | `languages.nix` | Tinymist and Typstyle |
| C/C++ | `languages.nix` | Clangd plus the configured LLDB DAP adapter |
| Python | `languages-python.nix`, `testing.nix` | basedpyright, Ruff, debugpy, pytest/neotest-python; project test dependencies must be available through the project environment |
| JavaScript/TypeScript | `languages-web.nix`, `testing.nix` | `ts_ls`, prettierd, eslint_d, vscode-js-debug, Jest or Vitest available from the project package manager |
| JSON | `languages-web.nix` | jsonls and jsonfmt |
| Terraform/OpenTofu and HCL | `languages-infra.nix` | tofuls, `tofu fmt`, hclfmt; project validation still runs `tofu validate` or `terraform validate` where applicable |
| YAML/Kubernetes/Compose | `languages-infra.nix` | yaml-language-server; project validation may add yamllint, kubeconform, or `docker compose config` |
| Dockerfile | `languages-infra.nix` | dockerfile-language-server, Dockerfile Treesitter grammar, hadolint |
| Bash | `languages-infra.nix` | bash-language-server, shfmt, shellcheck |
| TOML | `languages-infra.nix` | taplo and tombi |
| Tests/debugging | `testing.nix`, language modules | Neotest, DAP UI, debugpy, vscode-js-debug, and project-local pytest/Jest/Vitest commands |
| Workspace safety | `hardening.nix` | root marker policy, disabled local config/modelines, generated-file guards, gitleaks scan wrapper |
| Guarded AI | `ai.nix` plus `home/modules/ai-*.nix` | authenticated `claude`, `codex`, or `pi` CLI when used; bridge fails safely if none are on `PATH` |
| AI companion plugin | `ai-companion.nix` | CodeCompanion.nvim through NVF; an OpenAI-compatible endpoint configured at runtime with `OPENAI_API_KEY`, optional `OPENAI_BASE_URL` (falls back to `https://api.openai.com`), and optional `OPENAI_MODEL` |
| Tidal/Haskell | `tidal.nix` | haskell-language-server, haskell-tools, `tidal.nvim`, `tidal-ghci` from the project or bundled fallback |

## Phase 0 decisions

- The approved improvement report is the canonical plan for the NVF IDE rollout.
- Nix LSP ownership is singular by default: `nixd` is enabled and `nil_ls` is disabled unless a later ticket documents a deliberate split.
- `home/modules/nvf/languages.nix` remains the shared/core language module. Python, web, infrastructure, testing, hardening, and AI use focused modules before being imported by `default.nix`; future language or workflow work should follow that pattern.
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
| `<leader>a` | AI actions: lowercase bridge mappings remain guarded (`aa`, `ar`, `at`, `ad`, `as`); CodeCompanion uses `ac`, `aA`, and visual selected-code mappings `ae`, `aR`, `aT` |
| `<leader>u` | UI toggles |
| `<localleader>` | Language-local actions when global namespaces would collide |

## Workspace hardening

`home/modules/nvf/hardening.nix` defines the Phase 4 workspace policy without silently executing project-local code.

- Root detection uses the first matching marker from `flake.nix`, `.envrc`, `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, JVM build files, Terraform/OpenTofu files, or `.git`. Use `:NvfWorkspaceRoot` to inspect the detected root for the current buffer or `:NvfWorkspaceRoot <path>` for another path.
- Local Neovim config execution is disabled with `exrc = false` and modelines disabled. Use `:NvfWorkspacePolicy` to show the active policy; trusted project bootstrapping must stay explicit through shell/devshell commands rather than automatic editor hooks.
- Large/generated-file guards apply to files above 1 MiB, buffers above 20,000 lines, and dependency/generated paths such as `.git`, `node_modules`, `dist`, `build`, `target`, `.terraform`, `.next`, coverage output, lock files, minified JavaScript, and generated paths. Guarded buffers disable diagnostics, stop Treesitter when possible, and detach LSP clients to reduce monorepo and generated-file churn.
- Secret scanning is an explicit task only. `:NvfScanSecrets` and `<leader>tS` run `gitleaks detect --no-git --redact --source <workspace-root>` using the Nix-provided wrapper package. Pass a directory to scan a different root. Findings open in the quickfix list.
- Diagnostic throttling is intentionally conservative: diagnostics do not update in insert mode, severity sorting is enabled, and guarded buffers disable diagnostics entirely.

## AI bridge

`home/modules/nvf/ai.nix` is a thin editor bridge to the existing Home Manager AI tooling rather than a new provider stack. It looks for provider CLIs with `vim.fn.exepath` in this order: Claude Code (`claude`), Codex CLI (`codex`), and Pi (`pi`). If no backing CLI is available, the action fails safely and sends nothing.

Implemented mappings and commands:

| Key | Command | Scope |
|---|---|---|
| `<leader>aa` | `:NvfAiAsk` | Typed small prompt, or selected text in visual mode |
| `<leader>ar` | `:NvfAiReviewDiff` | Current `git diff --no-ext-diff` from the workspace root |
| `<leader>at` | `:NvfAiTests` | Typed test prompt, or selected code in visual mode |
| `<leader>ad` | `:NvfAiDiagnostic` | Current diagnostic under the cursor plus the current line |
| `<leader>as` | `:NvfAiSkills` | Shared skills/rules discovered from `AI_SKILLS_DIR` or `~/.local/share/ai` |

Guardrails are enforced before any provider invocation:

- Context is scoped to selected text, typed prompts, the current diagnostic, the current git diff, or an explicitly selected shared skill/rule; full buffers are not collected automatically, and full-buffer visual selections are blocked.
- Sensitive paths such as `secrets/`, `.env`, private-key material, SOPS YAML markers, and key files are blocked. Secret-like values such as passwords, tokens, quoted or unquoted API keys, bearer tokens, and common cloud/source-control token patterns are redacted before confirmation.
- The confirmation prompt shows the destination provider, action, exact scope, workspace root, context size, and redaction count. Cancelling the prompt stops before `vim.system` runs.
- Provider commands are built as argv lists and run with `vim.system` from the detected workspace root. Claude and Codex keep stdin-based prompts; Pi uses its non-interactive `pi -p <prompt>` argv form. The bridge does not enable autonomous or dangerous provider modes; sandboxing and approvals remain owned by `home/modules/ai-claude.nix`, `home/modules/ai-codex.nix`, and `home/modules/ai-pi.nix`.

## AI companion plugin

NVF-031 adopts CodeCompanion.nvim rather than Avante.nvim for the richer in-editor assistant workflow. Avante.nvim is packaged by NVF and remains technically feasible, but its Cursor-like defaults, heavier Rust-backed plugin package, auto-suggestion/auto-keymap surface, and diff/application ergonomics are a poorer fit for this repository's production-safe guardrail policy. CodeCompanion.nvim is also first-class in NVF and provides the needed chat, inline edit, action palette, OpenAI-compatible adapters, curated prompt library, and diff display without replacing the guarded bridge.

`home/modules/nvf/ai-companion.nix` is gated by `myHome.features.enableNvfAiCompanion`; terminal-derived profiles enable it with `lib.mkDefault true` after validation. Credentials are never committed to Nix. The plugin reads runtime environment variables only:

- `OPENAI_API_KEY` for the OpenAI-compatible API token.
- `OPENAI_BASE_URL` when using a non-default OpenAI-compatible endpoint such as a secured local llama.cpp server; when unset, the adapter falls back to `https://api.openai.com` and appends `/v1/chat/completions`.
- `OPENAI_MODEL` to override the default model (`gpt-4o-mini`).

Implemented CodeCompanion mappings:

| Key | Command | Scope |
|---|---|---|
| `<leader>ac` | `:CodeCompanionChat` | Plugin chat using the configured OpenAI-compatible adapter |
| `<leader>aA` | `:CodeCompanionActions` | Action palette with repository-curated selected-code prompts and the default prompt library hidden |
| Visual `<leader>ae` | `:'<,'>CodeCompanion ...` | Edit only the selected range and propose a minimal diff |
| Visual `<leader>aR` | `:'<,'>CodeCompanion ...` | Review only the selected range for correctness, safety, tests, and docs drift |
| Visual `<leader>aT` | `:'<,'>CodeCompanion ...` | Generate tests for only the selected range and ask for missing runner details |

Use the workflows as distinct paths:

- Use the guarded bridge for sensitive material, redaction-dependent prompts, Claude/Codex/Pi CLI workflows, current diff review with confirmation, and Pi orchestration/TUI tasks.
- Use CodeCompanion for explicit interactive chat, selected-code review, selected-code edits, and OpenAI-compatible API or local endpoint experiments when the selected context is safe to send.
- Use Codex CLI (`codex exec`) for subscription/OAuth-backed Codex workflows; CodeCompanion does not inherit Codex CLI authentication or sandbox settings.
- Keep Pi as a separate guarded orchestration path through `home/modules/nvf/ai.nix`; it is not routed through CodeCompanion.

Privacy boundary: CodeCompanion does not inherit the bridge's sensitive-path blocking, secret redaction, confirmation summary, or full-buffer-selection guard. Do not send secrets, private keys, `.env` content, or broad repository context through the plugin. The configured prompt library hides the default prompt library, configures built-in slash commands (`/file`, `/buffer`, `/symbols`, and related repository/context inserters) as disabled, configures built-in chat tools (`run_command`, file edit/read/search tools, web fetch/search, and related agent groups) as disabled, and keeps automatic full-buffer variables absent. These are CodeCompanion plugin controls, not equivalent to the guarded bridge's pre-send redaction and confirmation policy.

## Troubleshooting

Start with the smallest scope that reproduces the issue.

- Language server missing: confirm the affected profile has activated, run `:LspInfo`, and verify the tool appears in the required-tools table above. For project-local tools, enter the project devshell or package-manager environment first.
- Duplicate diagnostics: check the owning language module and disable overlapping project plugins before adding a second NVF source. Nix should stay on `nixd` only by default.
- Slow or noisy workspaces: inspect `:NvfWorkspaceRoot`, `:NvfWorkspacePolicy`, `:echo b:nvf_workspace_guard`, and `nvim --startuptime /tmp/nvim-startuptime.log +qa` before changing global defaults.
- Test/debug adapter failures: run the matching CI command outside Neovim, then inspect `:DapShowLog`, `:messages`, and Neotest output. The editor does not install project dependencies.
- AI bridge actions unavailable: ensure `claude`, `codex`, or `pi` is installed and authenticated in the Home Manager profile. Blocked sensitive paths or full-buffer selections are expected guardrail failures.
- CodeCompanion unavailable: confirm `myHome.features.enableNvfAiCompanion` is true for the active profile, run `:CodeCompanionChat`, and verify `OPENAI_API_KEY` plus any `OPENAI_BASE_URL`/`OPENAI_MODEL` overrides are exported in the environment that launches Neovim. Use the guarded bridge instead for sensitive prompts.
- Tidal issues: prefer a project `tidal-ghci` when available; otherwise the bundled fallback from `tidal.nix` is used. Tidal mappings are buffer-local under `<localleader>`.

## Health checks and profiling

Use runtime checks after activation when editor behavior changes or performance regresses:

```bash
nvim --headless "+checkhealth" "+qa"
nvim --headless -c 'if exists(":CodeCompanionChat") != 2 | cquit | endif' -c 'qa!'
nvim --headless -c 'if exists(":NvfAiAsk") != 2 | cquit | endif' -c 'qa!'
nvim --headless "+checkhealth vim.lsp" "+qa"
nvim --headless "+checkhealth nvim-treesitter" "+qa"
nvim --headless "+checkhealth dap" "+qa"
nvim --startuptime /tmp/nvim-startuptime.log +qa
```

Inside Neovim, inspect `:LspInfo`, `:checkhealth`, `:TSModuleInfo`, `:DapShowLog`, `:messages`, and guarded-buffer state with `:echo b:nvf_workspace_guard`. Prefer filetype-scoped or lazy-loaded additions when NVF supports them, and update this guide with validation evidence whenever a new language, adapter, or plugin changes startup behavior.

## Adding or changing a language

1. Open a ticket tied to the NVF report or a follow-up maintenance finding. State the filetypes, LSP, formatter, linter, test/debug ownership, keymaps, and affected profiles.
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
nixfmt home/modules/nvf/*.nix
nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage
nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage
```

Activate with `make terminalman` only when it is safe to update the local profile. After activation, run `nvim --headless "+checkhealth" "+qa"` when runtime health evidence is needed.

## Validation evidence expectations

PRs or agent changes that alter editor behavior must include evidence in the PR body or in a dated file under `docs/test/evidence/`.

Required evidence for NVF changes:

- The exact validation commands run and whether each passed.
- Home Manager dry-run coverage for every affected profile. At minimum, run `nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage` and `nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage` when shared Linux NVF behavior changes; include `macman` or `wslman` if the change affects those profiles or platform-specific packages.
- Runtime health evidence after activation when plugin startup, LSP, Treesitter, DAP, or AI bridge behavior changes. Use the headless `checkhealth` commands above, and include `:LspInfo`, `:TSModuleInfo`, `:DapShowLog`, `:messages`, or startup profiling notes when relevant.
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
| Language tools from Nixpkgs/NVF | LSPs, formatters, linters, DAP adapters, test adapters | Review package availability across Linux, Darwin, WSL, and headless profiles. Validate schema or command changes before accepting updates. |
| Project-local runners | pytest, Jest, Vitest, Terraform/OpenTofu, Kubernetes, Docker, shell tooling | Document CI parity changes in the owning project and do not imply editor support for tools that are only optional/project-local. |

Document each review in a dated evidence file or ticket workflow log. Open follow-up tickets for risky updates, breaking schema changes, inactive external sources, security advisories, or changes that require profile-specific validation.

## Project CI parity

Neotest keymaps are convenience wrappers for interactive local feedback; project-local commands remain the source of truth for CI parity:

- Python: run project-selected pytest commands such as `pytest`, `uv run pytest`, or `nix develop -c pytest` alongside Ruff checks (`ruff check`, `ruff format --check`). The editor adapter uses pytest and depends on project-local test dependencies being available.
- JavaScript/TypeScript/JSON: run package-manager checks such as `npm test`, `npm run lint`, `pnpm test`, `pnpm lint`, `yarn test`, or `yarn lint` according to each repository. The editor adapters call project-local Jest/Vitest through `npx`.
- Debugging: NVF supplies continue/restart/terminate/step/REPL/UI mappings for nvim-dap. `testing.nix` adds pause, conditional breakpoints, clear breakpoints, and scopes float mappings, while Python and JavaScript/TypeScript adapter ownership remains in the language modules.
- Infrastructure: run project checks such as `tofu fmt -check`, `tofu validate`, `terraform fmt -check`, `yamllint`, `kubeconform`, `docker compose config`, `hadolint`, `shellcheck`, `shfmt -d`, `taplo fmt --check`, and `tombi lint` where applicable.

## Planned, not yet implemented

Later phases will fill in Rust, Go, Lua, and SQL workflows. This guide does not claim those behaviors are available until their implementation tickets land.
