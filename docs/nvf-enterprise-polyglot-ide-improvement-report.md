# NVF Enterprise Polyglot IDE Improvement Report

## Overview

This report defines a phased plan for evolving the repository's current NVF/Neovim configuration into a documented, production-grade enterprise polyglot IDE. It documents the current implementation, identifies gaps against enterprise development workflows, assigns target ownership for language servers, formatters, linters, test runners, debug adapters, and CI parity commands, and provides an implementation roadmap with validation commands. This is a planning and architecture document only; it does not implement configuration changes.

## Executive Summary

The current NVF configuration is reproducible, modular, and already usable for Nix, Markdown, Typst, C/C++, and Haskell/Tidal workflows. It is delivered through Home Manager, imports the upstream NVF Home Manager module in multiple profiles, and makes `nvim` the default terminal editor.

The next maturity step is not to add every plugin at once. The configuration needs explicit ownership policies, predictable keymap namespaces, test/debug foundations, workspace hardening, and documentation. The highest-priority implementation work is to remove duplicate Nix LSP ownership, add missing LSP ergonomics, split large language concerns into focused modules, and document supported workflows in a dedicated operational guide.

## Current-State Architecture

### Delivery Path

| Concern | Current implementation |
|---|---|
| NVF input | `flake.nix:14-17` defines the `nvf` input from `github:NotAShelf/nvf` and follows `nixpkgs`. |
| NixOS agent profile | `flake.nix:273-278` imports `nvf.homeManagerModules.default` for the agent Home Manager user. |
| Desktop Home Manager profile | `flake.nix:407` imports `nvf.homeManagerModules.default` for `sandmhan`. |
| macOS profile | `flake.nix:414` imports `nvf.homeManagerModules.default` for `macman`. |
| WSL profile | `flake.nix:421` imports `nvf.homeManagerModules.default` for `wslman`. |
| Terminal-only profile | `flake.nix:428` imports `nvf.homeManagerModules.default` for `terminalman`. |
| Terminal integration | `home/modules/terminal.nix:43-51` imports `./nvf` and sets `EDITOR = "nvim"`. |
| NVF composition root | `home/modules/nvf/default.nix:7-22` imports the local NVF modules and enables `programs.nvf`. |

This architecture is strong because editor behavior is declarative, reusable across profiles, and evaluated by Nix before activation.

### Local NVF Module Inventory

`home/modules/nvf/default.nix:7-22` currently imports:

| Module | Role |
|---|---|
| `options.nix` | Core editor options such as aliases, clipboard, line numbers, and indentation. |
| `keymaps.nix` | Global leader key and navigation, finder, Git, LSP, and diagnostics mappings. |
| `visuals.nix` | Visual plugins and presentation settings. |
| `lsp.nix` | Global LSP enablement and explicit server enablement. |
| `languages.nix` | Current language-specific defaults for Markdown, Nix, Typst, and C/C++. |
| `completion.nix` | Completion stack. |
| `treesitter.nix` | Treesitter configuration. |
| `utility.nix` | Mini.files, flash.nvim, Markdown preview, nix-develop integration, color tools, and WhichKey. |
| `finder.nix` | FZF-based search/navigation configuration. |
| `editing.nix` | Editing helpers such as comments, surround, autopairs, and undo tooling. |
| `git.nix` | Git integrations such as signs, status, and conflict tooling. |
| `notes.nix` | TODO/FIXME/NOTE highlighting. |
| `tidal.nix` | Haskell/Tidal language support and live-coding commands. |
| `toggles.nix` | UI/editor toggles. |
| `ui.nix` | Statusline, messages, breadcrumbs, bufferline, and related UI modules. |

`README.md:214-228` is stale because it lists only part of this inventory and omits several modules imported by `default.nix`.

## Current Language and Tooling Coverage

| Language/domain | Current source | Current behavior |
|---|---|---|
| Markdown | `home/modules/nvf/languages.nix:14-28` | Enables Markdown, Treesitter, Marksman, Prettierd, and in-buffer rendered Markdown. `home/modules/nvf/utility.nix:17` also enables Markdown preview. |
| Nix | `home/modules/nvf/languages.nix:31-39` | Enables Nix, Treesitter, extra diagnostics, `nixfmt`, and `nixd`. |
| Typst | `home/modules/nvf/languages.nix:42-49` | Enables Typst, Treesitter, Tinymist, and Typstyle. |
| C/C++ | `home/modules/nvf/languages.nix:52-63` | Enables Clang language support, Treesitter, `clangd`, and DAP with `lldb-vscode`. |
| Haskell/Tidal | `home/modules/nvf/tidal.nix` | Enables Haskell, HLS, Haskell Tools, Ormolu/Cabal formatting settings, bundled Tidal fallback, and buffer-local Tidal live-coding mappings. |
| Notes/TODOs | `home/modules/nvf/notes.nix`; `home/modules/nvf/lsp.nix` | Enables TODO-style comment highlighting, with global `harper-ls` spell/style diagnostics enabled in the LSP layer. |
| AI tooling outside Neovim | `home/modules/ai-claude.nix`, `home/modules/ai-codex.nix`, `home/modules/ai-pi.nix`, `home/modules/ai-skills.nix` | Provides Claude, Codex, Pi, and shared skill/rule foundations, but no direct NVF bridge yet. |

## Enterprise Gap Analysis

### Duplicate Nix LSP Ownership

The current configuration appears to attach multiple Nix language servers:

- `home/modules/nvf/lsp.nix:17-18` enables both `nixd` and `nil_ls`.
- `home/modules/nvf/languages.nix:38` also selects `nixd` as the language-level Nix server.

This should be resolved first. Use one default Nix LSP unless a split is explicitly documented. `nixd` is the recommended default for this repository because `languages.nix` already selects it.

### Narrow Enterprise Language Coverage

The current first-class language set does not cover several common enterprise domains: Python, JavaScript/TypeScript, Terraform/OpenTofu, YAML, JSON, Docker, Bash, Kubernetes, Rust, Go, Lua, TOML, and SQL. These should be added incrementally in focused modules rather than expanding `languages.nix` into a monolith.

### Formatter and Linter Policy Is Implicit

Global formatting and extra diagnostics are enabled in `home/modules/nvf/languages.nix:8-11`, but the repository does not yet define which tool owns formatting, linting, diagnostics, test execution, debugging, and CI parity for each language.

### Testing and Debugging Are Incomplete

C/C++ has DAP enabled, but there is no shared testing/debugging layer for nearest test, file test, suite test, failed-test reruns, debug-nearest, DAP UI, or coverage. The target IDE should expose a consistent workflow across languages while allowing language-specific adapters.

### Keymaps Need a Stable Taxonomy

`home/modules/nvf/keymaps.nix` already includes finder, Git, LSP discovery, code actions, and diagnostics mappings. Missing ergonomics include hover, rename, implementation, type definition, signature help, test actions, debug actions, AI actions, and refactoring actions.

Tidal currently uses buffer-local `<leader>t*` mappings in `home/modules/nvf/tidal.nix:218-229`, including `<leader>tt` and `<leader>tr`. Future global test mappings must avoid collisions or move Tidal to `<localleader>`.

### Workspace Hardening Is Missing

The broader environment includes `direnv`/`nix-direnv` and NVF `nix-develop` support, but the editor does not yet encode enterprise workspace behavior such as root-marker selection, local config trust, internal task commands, secret scanning, large-file guards, or monorepo diagnostics throttling.

### AI Workflows Are Not Editor-Native

Claude, Codex, Pi, and shared skills already exist in Home Manager modules, but Neovim does not yet expose safe actions for reviewing a diff, explaining diagnostics, generating tests, or asking about selected text. Any editor bridge must require confirmation and redact or block secret-like content by default.

## Target-State Language Ownership Matrix

Use this matrix as the source of truth for future implementation. Tool names are target defaults and should be validated against the current NVF option schema before implementation.

| Language/domain | Primary LSP | Formatter | Linter/diagnostics | Test runner | Debug adapter | CI parity command | Owning NVF module |
|---|---|---|---|---|---|---|---|
| C/C++ | `clangd` | `clang-format` | `clang-tidy`, compiler diagnostics | CTest or project task | `lldb-vscode` or `codelldb` | `cmake --build`, `ctest`, project-specific compile command | Existing `home/modules/nvf/languages.nix`, later optional `languages-cpp.nix` |
| Python | `basedpyright` or `pyright` | `ruff format` | `ruff check`, optional `mypy` | `pytest` | `debugpy` | `ruff check .`, `ruff format --check .`, `pytest` | New `home/modules/nvf/languages-python.nix` |
| JavaScript/TypeScript | `vtsls` or `typescript-language-server` | Prettier or Biome | ESLint or Biome | Jest, Vitest, npm/pnpm/yarn scripts | `js-debug-adapter` | `npm test`, `npm run lint`, `npm run typecheck` or package-manager equivalents | New `home/modules/nvf/languages-web.nix` |
| Nix | `nixd` | `nixfmt` / repo formatter | Nix evaluation, `statix`, `deadnix` if adopted | Nix build/eval checks | Not normally required | `nix build --dry-run .#homeConfigurations.<profile>.activationPackage` | Existing `home/modules/nvf/languages.nix` and `home/modules/nvf/lsp.nix` after cleanup |
| Haskell/Tidal | HLS | `ormolu`, `cabal-fmt` | HLS diagnostics, optional HLint | Cabal/Stack tests; Tidal live evaluation | Haskell DAP only if needed | `cabal test`, `stack test`, or project-specific commands | Existing `home/modules/nvf/tidal.nix` |
| Terraform/OpenTofu | `terraformls` | `terraform fmt` / `tofu fmt` | `tflint`, `tfsec` or `checkov` | `terraform validate` / `tofu validate` | Usually task-based, not DAP | `terraform fmt -check`, `terraform validate`, `tflint`; OpenTofu equivalents | New `home/modules/nvf/languages-infra.nix` |
| YAML | `yaml-language-server` | Prettier | `yamllint`, schema validation | Workflow/chart/config validation tasks | Not applicable | `yamllint .`, schema-specific validators | New `home/modules/nvf/languages-infra.nix` |
| JSON | `json-language-server` | Prettier or Biome | Schema validation | Config/package validation tasks | Not applicable | `biome check`, `prettier --check`, schema-specific validators | New `home/modules/nvf/languages-web.nix` or `languages-infra.nix` |
| Markdown | `marksman` | Prettier/Prettierd | `markdownlint`, Harper | Link checks and doc build tasks | Not applicable | `markdownlint`, doc build command | Existing `home/modules/nvf/languages.nix`; possibly `languages-docs.nix` later |
| Obsidian-flavored Markdown | `marksman` plus Obsidian-aware plugin if adopted | Prettier/Prettierd with compatible prose policy | `markdownlint` with wikilink/frontmatter exceptions, Harper | Vault link checks | Not applicable | `markdownlint` with repository/vault config | Existing Markdown ownership plus future notes/docs module |
| Docker/Compose | `dockerls`, Compose LSP if available | Formatter if adopted | `hadolint`, Compose validation | Container build/test tasks | Container attach only if needed | `hadolint Dockerfile`, `docker compose config` | New `home/modules/nvf/languages-infra.nix` |
| Bash/Shell | `bash-language-server` | `shfmt` | `shellcheck` | Script-specific tasks or Bats | Bash debug adapter only if needed | `shellcheck`, `shfmt -d`, Bats if present | New `home/modules/nvf/languages-infra.nix` |
| Kubernetes | `yaml-language-server` with Kubernetes schemas | Prettier | kubeconform/kubeval, policy tools | Manifest/chart validation | Not applicable | `kubeconform`, `helm lint`, `kubectl --dry-run=server` where available | New `home/modules/nvf/languages-infra.nix` |
| Rust | `rust-analyzer` | `rustfmt` | `clippy` | `cargo test` | `codelldb` | `cargo fmt --check`, `cargo clippy`, `cargo test` | Future `languages-rust.nix` or shared core module |
| Go | `gopls` | `gofumpt`, `goimports` | `golangci-lint` | `go test` | `delve` | `go test ./...`, `golangci-lint run` | Future `languages-go.nix` or shared core module |
| Lua | `lua-language-server` | `stylua` | `luacheck` where needed | Busted/plenary tests | Local Neovim/plugin debugging | `stylua --check`, plugin test command | Future shared/core language module |
| TOML | `taplo` | `taplo format` | `taplo lint` | Config validation tasks | Not applicable | `taplo lint`, project-specific validation | New `home/modules/nvf/languages-infra.nix` |
| SQL | Dialect-aware SQL language server | `sqlfluff fix` or dialect formatter | `sqlfluff lint` | Migration/test task runner | Database/client-specific | `sqlfluff lint`, migration validation | Future `languages-data.nix` or shared core module |

## Target Module Architecture

Keep `home/modules/nvf/languages.nix` as the shared/core module. Add focused modules as coverage expands:

```text
home/modules/nvf/languages.nix          # current shared/core language defaults
home/modules/nvf/languages-python.nix   # Python LSP, Ruff, pytest, debugpy
home/modules/nvf/languages-web.nix      # JS/TS, JSON, frontend tooling
home/modules/nvf/languages-infra.nix    # YAML, Docker, Terraform/OpenTofu, Kubernetes, Bash, TOML
home/modules/nvf/testing.nix            # Neotest/DAP orchestration and keymaps
home/modules/nvf/hardening.nix          # root detection, trust, large-file, secret/performance controls
home/modules/nvf/ai.nix                 # safe bridge to Claude/Codex/Pi workflows
```

Import new modules from `home/modules/nvf/default.nix` only after validating the NVF schema for each plugin and option.

## Keymap Taxonomy

Adopt a stable taxonomy and keep WhichKey labels synchronized.

| Prefix | Owner | Notes |
|---|---|---|
| `<leader><leader>` | File picker | Existing FZF files mapping. |
| `<leader>/` | Live grep | Existing FZF grep mapping. |
| `<leader>f` | Find/search | Files, buffers, help, old files, grep word. |
| `<leader>g` | Git | Status, commits, branches, files, hunks, blame, conflict actions. |
| `<leader>l` | LSP | References, definitions, symbols, code actions, hover, rename, implementation, type definition, signature help. |
| `<leader>x` | Diagnostics/trouble | Existing diagnostics mapping can remain, or migrate under `<leader>l` if preferred. |
| `<leader>r` | Refactoring | Extract, inline, move, and language-specific refactors. |
| `<leader>t` | Tests/tasks | Nearest, file, suite, failed, output, task runner. Avoid Tidal global collisions. |
| `<leader>d` | Debugging | Continue, step, breakpoints, REPL, scopes, debug test. |
| `<leader>a` | AI | Ask, review diff, generate tests, explain diagnostics, skill picker. |
| `<leader>u` | UI toggles | Preserve existing toggle ownership. |
| `<localleader>` | Language-local actions | Recommended for Tidal live-coding actions if global `<leader>t` becomes test-owned. |

## Testing and Debugging Strategy

### Testing

Add `home/modules/nvf/testing.nix` after validating NVF support for the selected plugins.

| Capability | Target behavior |
|---|---|
| Nearest test | Run test under cursor through language adapter. |
| File tests | Run all tests in the current file. |
| Suite tests | Run all tests in the detected project root. |
| Failed rerun | Rerun only failed tests when supported. |
| Test output | Open output panel or quickfix list. |
| CI parity | Prefer commands that match repository CI scripts. |

### Debugging

| Capability | Target behavior |
|---|---|
| Breakpoints | Toggle, conditional, and clear breakpoints. |
| Session control | Continue, pause, step over, step into, step out, restart, terminate. |
| Debug nearest test | Start adapter-specific debug session for the current test. |
| Debug UI | Scopes, watches, call stack, console/REPL if NVF supports it. |
| Adapter ownership | Use `debugpy`, `js-debug-adapter`, `codelldb`, `delve`, and language-specific adapters only where needed. |

Start with Python and JavaScript/TypeScript tests, then add Rust, Go, and C/C++ once the base DAP workflow is stable.

## Workspace, Security, Reliability, and Performance Hardening

### Workspace Policy

A future `home/modules/nvf/hardening.nix` or `workspace.nix` should define:

- Root markers by ecosystem: `flake.nix`, `.envrc`, `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle`, `terraform.tf`, `.git`.
- Monorepo root selection rules and fallback behavior.
- Safe project task commands for build, test, lint, format, and code generation.
- Integration with `direnv` and `nix-develop` without silently executing untrusted project code.

### Enterprise and Company-Specific Hooks

Reserve extension points for organization-specific policy without hard-coding one employer's environment:

| Hook | Examples |
|---|---|
| Internal CLIs | Project bootstrap, code generation, service catalog lookup, incident tooling. |
| Internal registries | npm, PyPI, Maven, OCI, Terraform module registries. |
| Corporate certificates | CA bundle notes for language servers and package managers. |
| Code ownership | CODEOWNERS lookup, review metadata, ownership hints. |
| Policy checks | Pre-commit, license checks, dependency audits, SAST/DAST commands. |
| Deployment metadata | Kubernetes context safety, Terraform workspace display, environment banners. |

### Security Controls

| Risk | Target control |
|---|---|
| Secret exposure to AI | Require confirmation before sending buffers, selections, or diffs; run secret-like pattern checks first. |
| Secret commits | Provide `gitleaks` or equivalent task integration. |
| Untrusted local config | Disable automatic execution of project-local editor code unless explicitly trusted. |
| Generated/large files | Disable LSP, Treesitter, formatting, and expensive diagnostics over size or path thresholds. |
| Duplicate diagnostics | Enforce one default LSP and one primary linter per filetype unless documented. |
| Supply chain drift | Track pinned external plugins and review updates, especially custom GitHub plugins such as Tidal. |

### Reliability and Performance Controls

- Document `:checkhealth`, LSP status, Treesitter status, and DAP health checks.
- Add startup profiling guidance before adding large plugin groups.
- Prefer lazy-loading or filetype-loading where NVF supports it.
- Throttle diagnostics in large monorepos.
- Keep language additions incremental and validate each profile before activation.

## AI-in-Editor Strategy

The editor should reuse the existing AI stack instead of creating a separate system:

- `home/modules/ai-claude.nix` for Claude Code configuration and permissions.
- `home/modules/ai-codex.nix` for Codex configuration with workspace-write sandboxing and on-request approvals.
- `home/modules/ai-pi.nix` for Pi integration.
- `home/modules/ai-skills.nix` for shared provider-agnostic skills and rules.

A future `home/modules/nvf/ai.nix` should expose safe commands under `<leader>a`:

| Key | Action | Guardrail |
|---|---|---|
| `<leader>aa` | Ask about selected text or current file | Confirm exact context before sending. |
| `<leader>ar` | Review current Git diff | Show target provider and diff size first. |
| `<leader>at` | Generate or improve tests | Include only selected file/context after confirmation. |
| `<leader>ad` | Explain diagnostic under cursor | Send diagnostic text and minimal surrounding code. |
| `<leader>as` | Pick a shared skill/prompt | Use skills from `home/modules/ai-skills.nix`. |

Default behavior should block or redact secret-like content and never send full buffers automatically.

## Phased Implementation Roadmap

### Phase 0: Documentation and Decisions

Priority: immediate.

- Treat this report as the canonical architecture plan.
- Decide Nix LSP ownership, with `nixd` as the recommended default.
- Adopt the keymap taxonomy before adding more global mappings.
- Decide whether Tidal keeps `<leader>t*` buffer-local mappings or moves to `<localleader>`.
- Create `docs/neovim-ide.md` after implementation begins.

Expected outcome: the team has a shared source of truth for language ownership, keymaps, and rollout order.

### Phase 1: Baseline Cleanup

Priority: highest implementation priority.

- Update `home/modules/nvf/lsp.nix` to avoid enabling both `nixd` and `nil_ls` by default.
- Keep `home/modules/nvf/languages.nix` as shared/core language configuration.
- Add missing LSP ergonomics in `home/modules/nvf/keymaps.nix` near the existing LSP mappings starting around `home/modules/nvf/keymaps.nix:139`.
- Update the stale NVF inventory in `README.md:214-228`.

Expected outcome: fewer duplicate diagnostics, clearer LSP ownership, and better daily navigation/refactoring ergonomics.

### Phase 2: Core Enterprise Languages

Priority: high.

- Add `home/modules/nvf/languages-python.nix` for Python.
- Add `home/modules/nvf/languages-web.nix` for JavaScript/TypeScript and JSON.
- Add `home/modules/nvf/languages-infra.nix` for Terraform/OpenTofu, YAML, Docker, Bash, Kubernetes, and TOML.
- Import new modules from `home/modules/nvf/default.nix` after `./languages.nix` once options are validated.

Expected outcome: the editor supports common enterprise application, web, and infrastructure repositories with explicit tool ownership.

### Phase 3: Testing and Debugging

Priority: high after Phase 2.

- Add `home/modules/nvf/testing.nix` if current NVF options support the selected Neotest/DAP plugins.
- Add test keymaps under `<leader>t` without breaking Tidal mappings.
- Add debug keymaps under `<leader>d`.
- Start with Python and JavaScript/TypeScript adapters, then expand.

Expected outcome: developers can run and debug tests from consistent editor workflows that mirror CI commands.

### Phase 4: Workspace and Hardening

Priority: medium-high.

- Add `home/modules/nvf/hardening.nix` or `home/modules/nvf/workspace.nix`.
- Implement root detection guidance, large-file guards, trusted local config policy, and secret-scanning tasks.
- Add performance profiling and diagnostic throttling guidance.

Expected outcome: the IDE remains reliable in monorepos, handles generated files safely, and reduces the chance of secret exposure.

### Phase 5: AI Bridge

Priority: medium, after security policy is explicit.

- Add `home/modules/nvf/ai.nix`.
- Bridge to Claude/Codex/Pi workflows rather than adding an unrelated AI stack.
- Add `<leader>a` mappings for ask, review diff, generate tests, explain diagnostics, and skill picker.
- Require confirmation and redaction before context sharing.

Expected outcome: AI workflows become accessible in-editor without bypassing existing sandboxing and approval policies.

### Phase 6: Onboarding and Maintenance

Priority: ongoing.

- Add `docs/neovim-ide.md` with supported languages, required tools, keymaps, troubleshooting, validation, and how to add a language.
- Keep `README.md` synchronized with `home/modules/nvf/default.nix`.
- Add validation evidence expectations to PRs that change editor behavior.
- Review pinned plugin sources and language tool versions periodically.

Expected outcome: new users can understand and extend the IDE safely without reverse-engineering the NVF modules.

## Validation Commands

Run these commands after future implementation changes. This report update itself does not require Nix evaluation.

```bash
# Format Nix modules after implementation changes.
nixfmt home/modules/nvf/*.nix

# Validate Home Manager profiles.
nix build --dry-run .#homeConfigurations.sandmhan.activationPackage
nix build --dry-run .#homeConfigurations.terminalman.activationPackage

# Activate only when safe on the target machine.
make terminalman

# Runtime health check after activation.
nvim --headless "+checkhealth" "+qa"
```

For NixOS host-level changes, also run:

```bash
nix build --dry-run .#nixosConfigurations.<host>.config.system.build.toplevel
```

## Expected Outcomes

- Nix uses one default language server, eliminating duplicate diagnostics and code actions.
- Each supported language has documented ownership for LSP, formatting, linting, tests, debugging, and CI parity.
- Python, JavaScript/TypeScript, infrastructure formats, Docker, Bash, Kubernetes, Rust, Go, Lua, TOML, and SQL have a clear adoption path.
- Keymaps are predictable across LSP, Git, tests, debugging, UI toggles, AI, and language-local actions.
- Test and debug workflows are editor-native and aligned with CI commands.
- Workspace behavior is safer for monorepos, generated files, and untrusted local config.
- AI workflows reuse the existing Claude/Codex/Pi foundation and require explicit confirmation before context sharing.
- README and future `docs/neovim-ide.md` documentation match the real module structure.

## Risks and Maintenance Policy

| Risk | Mitigation |
|---|---|
| NVF option names differ from examples | Validate the current NVF schema before adding each module. |
| Too many LSPs slow startup | Add languages in phases and profile startup after each phase. |
| Duplicate diagnostics from overlapping tools | Assign one primary owner per filetype and document intentional exceptions. |
| Tidal `<leader>t` mappings collide with test mappings | Keep test mappings conflict-free or migrate Tidal workflows to `<localleader>`. |
| AI sends sensitive data | Require confirmation, redact/block secret-like content, and show destination provider. |
| Cross-platform package availability differs | Validate Linux, macOS, WSL, and terminal profiles independently where affected. |
| Documentation drifts | Update README and `docs/neovim-ide.md` in the same change as module imports. |

## References

- `flake.nix`
- `README.md`
- `home/modules/terminal.nix`
- `home/modules/development.nix`
- `home/modules/nvf/default.nix`
- `home/modules/nvf/options.nix`
- `home/modules/nvf/keymaps.nix`
- `home/modules/nvf/lsp.nix`
- `home/modules/nvf/languages.nix`
- `home/modules/nvf/utility.nix`
- `home/modules/nvf/notes.nix`
- `home/modules/nvf/tidal.nix`
- `home/modules/ai-claude.nix`
- `home/modules/ai-codex.nix`
- `home/modules/ai-pi.nix`
- `home/modules/ai-skills.nix`
