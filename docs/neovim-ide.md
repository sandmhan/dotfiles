---
title: Neovim IDE Operations Guide
status: accepted
updated: 2026-08-09
---

# Neovim IDE Operations Guide

This guide is the implementation-facing companion to the [NVF Enterprise Polyglot IDE Improvement Report](./nvf-enterprise-polyglot-ide-improvement-report.md). It is the current source of truth for implemented behavior and supersedes older roadmap items that proposed IDE-integrated test runners.

## Current implementation

The Home Manager NVF configuration is composed from `home/modules/nvf/default.nix` and exported as the reusable flake module `homeManagerModules.sandvim` (also aliased as `homeManagerModules.default`). The exported module imports upstream `nvf.homeManagerModules.default` plus this repository's Sandvim modules, and external consumers enable it with `programs.sandvim.enable = true`.

This repository's local profiles preserve the existing `myHome` interface through a flake-local adapter, which maps `myHome.features.enableNixvim` to `programs.sandvim.enable`. The reusable Sandvim module itself does not depend on `home/options.nix` or `config.myHome`.

### Portable API, presets, and smoke tests

The public Sandvim option API is `programs.sandvim.enable`, `programs.sandvim.preset`, and explicit `programs.sandvim.packs.*` overrides from `home/modules/nvf/options.nix`. External consumers import `dotfiles.homeManagerModules.sandvim`, set `programs.sandvim.enable = true`, and do not need this repo's local profiles, Stylix module, or `myHome` options.

| Preset | AI | Debugging | Notes | Tidal | Workflow | Legacy general | Documentation | Nix | Python | Web | Infrastructure | Systems | Data/mobile | Java |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `minimal` | Off | Off | Off | Off | Off | Off | Off | Off | Off | Off | Off | Off | Off | Off |
| `standard` | On | On | On | On | On | Off | On | On | On | On | On | On | On | Off |
| `full` | On | On | On | On | On | Off | On | On | On | On | On | On | On | On |

`minimal` keeps core editor behavior plus workspace hardening only. `standard` is the external-consumer default and backward-compatible historical set without Java. `full` adds Java to the standard set.

Local dotfiles profiles use a flake-local adapter that maps `myHome.features.enableNixvim` to `programs.sandvim.enable` and defaults those local users to `programs.sandvim.preset = "full"`. External consumers remain on `standard` unless they select another preset.

The pack leaves are:

- `programs.sandvim.packs.ai`
- `programs.sandvim.packs.debugging`
- `programs.sandvim.packs.notes`
- `programs.sandvim.packs.tidal`
- `programs.sandvim.packs.workflow`
- `programs.sandvim.packs.languages.general` (deprecated compatibility umbrella for documentation, Nix, and Clang defaults)
- `programs.sandvim.packs.languages.documentation`
- `programs.sandvim.packs.languages.nix`
- `programs.sandvim.packs.languages.python`
- `programs.sandvim.packs.languages.web`
- `programs.sandvim.packs.languages.infrastructure`
- `programs.sandvim.packs.languages.systems`
- `programs.sandvim.packs.languages.dataMobile`
- `programs.sandvim.packs.languages.java`

Explicit pack settings override preset defaults. `programs.sandvim.packs.notes` requires `programs.sandvim.packs.languages.documentation` because Obsidian and Markdown LSP features share one owner. The deprecated `programs.sandvim.packs.languages.general` compatibility umbrella stays available for external users: when explicitly enabled it defaults documentation and Nix support on and still enables Clang, while explicit `documentation` or `nix` overrides win. Notes expose `programs.sandvim.notes.attachmentsFolder` and `programs.sandvim.notes.templatesFolder`, defaulting to `attachments` and `templates`. The Tidal pack owns its Haskell language server and participates in shared LSP policy even when no grouped language pack is selected. Language DAP integrations are gated by both the language pack and `programs.sandvim.packs.debugging`; for example Python DAP requires the Python and debugging packs. Java DAP remains off.

The repo-native portability checks are:

```bash
nix build --no-write-lock-file .#checks.x86_64-linux.sandvimExternalConsumer
nix build --no-write-lock-file .#checks.x86_64-linux.sandvimMinimalConsumer
```

Supported editor language and workflow coverage today is intentionally limited to the modules already imported by `default.nix` and enabled by the selected packs:

- Markdown and Obsidian-style notes from `home/modules/nvf/documentation.nix` and `home/modules/nvf/notes.nix`, with markdown-oxide, markdownlint-cli2 structural lint, Harper prose diagnostics, mdformat, markdown/markdown-inline Treesitter, render-markdown Blink completion, rendered/preview workflows, wiki-link/backlink navigation, and dynamic current-directory workspaces.
- Nix with `nixd` as the default language server and `nixfmt` formatting from `home/modules/nvf/languages-nix.nix`.
- Typst with Tinymist and Typstyle from `home/modules/nvf/documentation.nix`.
- C/C++ with Clang tooling and the existing DAP settings from `home/modules/nvf/languages-systems.nix`; it is enabled by systems support or the deprecated general compatibility umbrella.
- Python with basedpyright, Ruff formatting/linting, and debugpy from `home/modules/nvf/languages-python.nix`.
- JavaScript/TypeScript with `typescript-language-server`, prettier, eslint_d, and JS debug adapter ownership from `home/modules/nvf/languages-web.nix`.
- JSON with `vscode-json-language-server` and `jsonfmt` from `home/modules/nvf/languages-web.nix`.
- Terraform/OpenTofu, HCL, YAML/Kubernetes/Compose, Dockerfile, Bash, and TOML support from `home/modules/nvf/languages-infra.nix`.
- Rust, Go, and Lua support from `home/modules/nvf/languages-systems.nix`, including rust-analyzer/rustfmt/crates.nvim, gopls/gofmt/golangci-lint, and lua-language-server/lazydev/stylua/luacheck.
- SQL and Dart/Flutter support from `home/modules/nvf/languages-data-mobile.nix`, including SQLS/sqlfluff and Dart LSP/flutter-tools with the Flutter SDK resolved from PATH or a project devshell rather than bundled in every profile. `enableNoResolvePatch` is intentionally disabled because NVF's current patch fails against the pinned flutter-tools.nvim source; prefer a non-Nix Flutter SDK on PATH until the NVF/input pin is updated.
- Java support from `home/modules/nvf/languages-java.nix` is available in the `full` Sandvim preset with jdt-language-server, Treesitter, and AStyle formatting; Java DAP remains disabled. Sandvim does not bundle project JDKs, Maven or Gradle plugins, Google Java Format, Checkstyle, Java test runners, or Java DAP profiles.
- DAP UI and supplemental debug keymaps from `home/modules/nvf/debugging.nix`; IDE-integrated test runners are intentionally not configured.
- Workspace hardening from `home/modules/nvf/hardening.nix`: root discovery commands, explicit local trust policy, large/generated-file guards, diagnostic throttling, expanded polyglot root markers, and an on-demand gitleaks secret scan task.
- Workflow tooling from `home/modules/nvf/workflow.nix`: Trouble diagnostics, GrugFar search/replace, Diffview review, fastaction, code-action lightbulb, mini.align/splitjoin/move, and vim-sleuth.
- Smart split and tmux pane navigation from `home/modules/nvf/utility.nix` plus the tmux-side `smart-splits.tmux` integration in `home/modules/terminal.nix`.
- CodeCompanion.nvim from `home/modules/nvf/ai-codecompanion.nix` as the only in-editor AI tool, using Codex ACP through `codex-acp` with ChatGPT authentication when the AI pack is enabled.
- Haskell/Tidal live-coding support from `home/modules/nvf/tidal.nix`.

Behavior not listed above is optional, project-local, or planned. IDE-integrated test runners, per-project task runners, and broader language-specific debug profiles remain project-local until their modules and tickets land.

## Required tools and ownership

Most tools are provided by NVF or by Nix packages referenced from the Home Manager modules. Project-local test runners, dependencies, and devshells own CI parity and are run outside Neovim.

| Area | Implemented editor owner | Required or expected tools |
|---|---|---|
| Markdown/Obsidian | `documentation.nix`, `notes.nix`, `ui.nix` | markdown-oxide, markdownlint-cli2 structural lint, Harper prose diagnostics, mdformat with GFM/frontmatter/footnote plugins, markdown/markdown-inline Treesitter, render-markdown-nvim Blink completions/markdown preview, and obsidian.nvim; markdown-oxide owns nvim-navic breadcrumbs while obsidian-ls remains attached for note-aware LSP features |
| Nix | `languages-nix.nix`, `lsp.nix` | `nixd`, `nixfmt`; keep `nil_ls` disabled unless a ticket documents a split |
| Typst | `documentation.nix` | Tinymist and Typstyle |
| C/C++ | `languages-systems.nix` | Clangd plus the configured LLDB DAP adapter; enabled by systems support or legacy general compatibility |
| Python | `languages-python.nix` | basedpyright, Ruff, and debugpy; run pytest from the project CLI/devshell when needed |
| JavaScript/TypeScript | `languages-web.nix` | `typescript-language-server`, prettier, eslint_d, and vscode-js-debug; run Jest/Vitest/package-manager tests from the project CLI when needed |
| JSON | `languages-web.nix` | vscode-json-language-server and jsonfmt |
| Terraform/OpenTofu and HCL | `languages-infra.nix` | tofuls, `tofu fmt`, hclfmt; project validation still runs `tofu validate` or `terraform validate` where applicable |
| YAML/Kubernetes/Compose | `languages-infra.nix` | yaml-language-server; project validation may add yamllint, kubeconform, or `docker compose config` |
| Dockerfile | `languages-infra.nix` | dockerfile-language-server, Dockerfile Treesitter grammar, hadolint |
| Bash | `languages-infra.nix` | bash-language-server, shfmt, shellcheck |
| TOML | `languages-infra.nix` | taplo and tombi |
| Rust | `languages-systems.nix` | rust-analyzer, rustfmt, crates.nvim; Rust DAP remains intentionally disabled until a project-owned profile is documented |
| Go | `languages-systems.nix` | gopls, gofmt, golangci-lint; Delve DAP remains intentionally disabled until a project-owned profile is documented |
| Lua | `languages-systems.nix` | lua-language-server, lazydev.nvim, stylua, luacheck |
| SQL | `languages-data-mobile.nix` | sqls, sqlfluff with `ansi` dialect defaults; project config may override dialect/lint policy outside the editor |
| Dart/Flutter | `languages-data-mobile.nix` | Dart LSP from Nix; flutter-tools resolves `flutter` from PATH/devshell because `flutterPackage = null` keeps the shared wrapper lightweight; `enableNoResolvePatch` stays disabled until NVF's patch applies to the pinned flutter-tools.nvim source |
| Java | `languages-java.nix` | Enabled by the `full` preset with jdt-language-server, Treesitter, and AStyle formatting; Java DAP is disabled. Project-owned JDK, build, lint, and test conventions stay in the repository or devshell that owns the Java project |
| Debugging | `debugging.nix`, language modules | DAP UI, debugpy, vscode-js-debug, and supplemental debug keymaps; Rust, Go, Dart, and Java DAP are disabled by default |
| Workspace safety | `hardening.nix` | root marker policy, disabled local config/modelines, generated-file guards, gitleaks scan wrapper |
| Workflow tooling | `workflow.nix` | Trouble, grug-far.nvim, diffview.nvim, fastaction.nvim, nvim-lightbulb, mini.align/splitjoin/move, and vim-sleuth |
| Tmux/Vim navigation | `utility.nix`, `terminal.nix` | smart-splits.nvim and the packaged `smart-splits.tmux` script |
| Neovim AI | `ai-codecompanion.nix` | CodeCompanion.nvim through NVF; `codex-acp` installed by the feature; ChatGPT authentication (`auth_method = "chatgpt"`) from a prior Codex/ChatGPT login rather than an API key |
| Standalone AI CLIs | `home/modules/ai-*.nix` | Claude, Codex, and Pi remain Home Manager CLI/TUI tools outside Neovim |
| Tidal/Haskell | `tidal.nix` | haskell-language-server, haskell-tools, `tidal.nvim`, `tidal-ghci` from the project or bundled fallback |

### Markdown and Obsidian format policy

- Conform runs NVF's packaged `mdformat` environment with GFM, YAML frontmatter, footnote, and wikilink plugins. It preserves Obsidian callouts, embeds, comments, and block IDs; normal formatting may align table columns and move footnote definitions to the end of the document.
- `markdownlint-cli2` owns structural linting. Sandvim supplies a base MD025 setting that permits the common Obsidian combination of a frontmatter `title` and one Markdown H1. Repository- or vault-local markdownlint files are still discovered and may override the base policy.
- Harper owns prose and spelling diagnostics, while markdown-oxide owns document/link intelligence. Do not add Vale, Marksman, or another Markdown formatter globally without first defining which existing owner it replaces.
- `render-markdown.nvim` uses its pinned GitHub and Obsidian callout, checkbox, table, and wikilink rendering defaults and registers callout/checkbox completion with Blink. Browser preview supports Mermaid, PlantUML, and KaTeX; use the Obsidian application when exact Obsidian-flavored rendering is required.
- `<leader>np` uses `wl-paste` from the existing Wayland clipboard provider, `xclip` on Linux/X11, `pngpaste` on Darwin, or Obsidian's PowerShell path on WSL. Attachments and templates default to vault-relative `attachments/` and `templates/` and can be changed through the Sandvim note options.

## Java support boundaries

`home/modules/nvf/languages-java.nix` enables NVF Java support only when `programs.sandvim.packs.languages.java = true`, which is included by the `full` preset. The module configures:

- `jdt-language-server` for LSP attachment.
- Java Treesitter highlighting.
- AStyle formatting through the Nix-provided `astyle` package.
- `dap.enable = false`.

Java projects own their JDK choice, build tool, test commands, and quality gates through repository files, CI, or a devshell. Sandvim does not claim Java DAP, IDE-integrated Java test running, Maven or Gradle plugin management, Google Java Format, Checkstyle, or project SDK bundling.

The Java runtime flake check uses a tiny isolated Java workspace with a local `.git` root marker to validate that JDTLS attaches and exposes symbols without network access. It is not a Maven or Gradle integration test and does not install project dependencies.

## Flake packages and checks

The flake exports prebuilt Sandvim Neovim packages for supported external-consumer presets:

| Attribute | Systems | Description |
|---|---|---|
| `packages.<system>.sandvimMinimal` | `x86_64-linux`, `aarch64-darwin` | Minimal preset final Neovim package |
| `packages.<system>.sandvimStandard` | `x86_64-linux`, `aarch64-darwin` | Standard preset final Neovim package |
| `packages.<system>.sandvimFull` | `x86_64-linux`, `aarch64-darwin` | Full preset final Neovim package |

Linux flake checks are exported under `checks.x86_64-linux`:

| Check | Purpose |
|---|---|
| `sandvimExternalConsumer` | Standard external-consumer Home Manager activation package |
| `sandvimMinimalConsumer` | Minimal external-consumer Home Manager activation package |
| `sandvimMinimalRuntime` | Hermetic minimal Neovim runtime harness |
| `sandvimMarkdownRuntime` | Hermetic documentation-only Markdown/Obsidian runtime harness using minimal + documentation + notes and a tracked fixture |
| `sandvimJavaRuntime` | Hermetic Java/JDTLS attachment and symbol harness |
| `sandvimStartupProfile` | Hermetic startup-budget smoke check |

The runtime/profile checks run inside Nix builders and do not call nested `nix` commands from `runCommand` bodies. Build the checks from the outer Nix invocation:

```bash
nix build --no-write-lock-file .#checks.x86_64-linux.sandvimMinimalRuntime
nix build --no-write-lock-file .#checks.x86_64-linux.sandvimMarkdownRuntime
nix build --no-write-lock-file .#checks.x86_64-linux.sandvimJavaRuntime
nix build --no-write-lock-file .#checks.x86_64-linux.sandvimStartupProfile
```

## Performance profiling

Use `scripts/profile-nvf.sh` to compare closure size and startup samples without activating a profile:

```bash
scripts/profile-nvf.sh minimal
scripts/profile-nvf.sh standard
scripts/profile-nvf.sh full
scripts/profile-nvf.sh all
```

The script builds the selected final package, reports `nix path-info -Sh` closure size, and records Neovim `--startuptime` samples. Startup timings are host-, cache-, storage-, and load-dependent. Treat the closure delta, not startup timing, as the primary feature-pack benefit.

Current observed 3-run sample from 2026-08-09:

| Preset | Closure | Startup min | Startup median | Startup max |
|---|---:|---:|---:|---:|
| `minimal` | 304.9 MiB | 57 ms | 58 ms | 101 ms |
| `standard` | 13.7 GiB | 93 ms | 116 ms | 153 ms |
| `full` | 14.4 GiB | 80 ms | 85 ms | 87 ms |

The startup-profile flake check enforces broad budgets of 1000 ms for `minimal` and 2000 ms for `full`; these budgets catch regressions but are not a guarantee for every machine.

## Phase 0 decisions

- The approved improvement report is the canonical plan for the NVF IDE rollout.
- Nix LSP ownership is singular by default: `nixd` is enabled and `nil_ls` is disabled unless a later ticket documents a deliberate split.
- `home/modules/nvf/documentation.nix` owns Markdown and Typst; `home/modules/nvf/languages-nix.nix` owns Nix; `home/modules/nvf/languages-systems.nix` owns Clang, Rust, Go, and Lua. Future language or workflow work should follow that focused-module pattern.
- The keymap taxonomy from the report is adopted as the namespace policy. Mapping descriptions are the current WhichKey label source and must stay synchronized with implemented keys.
- Tidal live-coding mappings are buffer-local under `<localleader>t*`, leaving global `<leader>t*` chords available for explicit workspace tasks.

## Keymap namespaces

| Prefix | Owner |
|---|---|
| `<leader><leader>` | File picker |
| `<leader>/` | Live grep |
| `<leader>f` | Find/search |
| `<leader>g` | Git, including Diffview review on unused `gd/gD/gh/gH/gt` chords |
| `<leader>l` | LSP navigation and ergonomics |
| `<leader>n` | Obsidian/Markdown note navigation |
| `<leader>s` | Search/replace workflows such as GrugFar |
| `<leader>x` | Diagnostics/Trouble |
| `<leader>r` | Planned refactoring actions |
| `<leader>t` | Explicit workspace tasks only; currently `<leader>tS` runs the secret scan |
| `<leader>d` | Debugging via NVF DAP defaults plus supplemental pause, conditional breakpoint, clear, and scopes actions |
| `<leader>a` | AI actions: CodeCompanion chat on `ac`; command/inline action-palette workflows are not exposed for the Codex ACP adapter |
| `<leader>u` | UI toggles |
| `<localleader>` | Language-local actions when global namespaces would collide |

Implemented Phase 8 workflow keys:

| Key | Command | Scope |
|---|---|---|
| `<leader>nn` | `:Obsidian new` | New note |
| `<leader>no` | `:Obsidian open` | Open note in Obsidian |
| `<leader>nq` | `:Obsidian quick_switch` | Quick note switcher |
| `<leader>ns` | `:Obsidian search` | Note search |
| `<leader>nb` | `:Obsidian backlinks` | Backlinks |
| `<leader>nl` | `:Obsidian links` | Link picker |
| `<leader>nf` | `:Obsidian follow_link` | Follow wiki/Markdown link |
| `<leader>nt` | `:Obsidian tags` | Tag picker |
| `<leader>nr` | `:Obsidian rename` | Rename note/link |
| `<leader>np` | `:Obsidian paste_img` | Paste clipboard image to `programs.sandvim.notes.attachmentsFolder` |
| `<leader>nx` | `:Obsidian toggle_checkbox` | Toggle Markdown task checkbox |
| `<leader>nT` | `:Obsidian template` | Insert a note template from `programs.sandvim.notes.templatesFolder` |
| `<leader>sr` | `:GrugFar` | Workspace search/replace |
| `<leader>sR` | `:GrugFarWithin` | Buffer search/replace |
| `<leader>ls` / `<leader>lw` | `:FzfLua lsp_document_symbols` / `:FzfLua lsp_workspace_symbols` | Fuzzy document and workspace symbol search; requires an attached LSP with symbol support |
| `<leader>fs` | `:FzfLua treesitter` | Current-buffer Treesitter symbol search when no LSP is attached |
| `<leader>lci` / `<leader>lco` | `:FzfLua lsp_incoming_calls` / `:FzfLua lsp_outgoing_calls` | Incoming and outgoing LSP call hierarchy for servers that support it |
| `<leader>lk` | NVF LSP signature help | Buffer-local signature help without shadowing document-symbol search |
| `<leader>lS` / `<leader>xs` | NVF document symbols / `:Trouble symbols` | Alternate document-symbol list and persistent symbol outline |
| `<leader>xw` / `<leader>xd` / `<leader>xR` | `:Trouble ...` | Workspace diagnostics, document diagnostics, references |
| `<leader>xq` / `<leader>xl` / `<leader>xs` | `:Trouble ...` | Quickfix, location list, symbols |
| `<leader>gd` / `<leader>gD` | `:DiffviewOpen` / `:DiffviewClose` | Diff review open/close |
| `<leader>gh` / `<leader>gH` / `<leader>gt` | `:DiffviewFileHistory %` / `:DiffviewFileHistory` / `:DiffviewToggleFiles` | Git file history and file list |

## Workspace hardening

`home/modules/nvf/hardening.nix` defines the Phase 4 workspace policy without silently executing project-local code.

- Root detection uses the first matching marker from `flake.nix`, `.envrc`, `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pubspec.yaml`, `.sqlfluff`, `sqlfluff.toml`, `.luarc.json`, `stylua.toml`, JVM build files, Terraform/OpenTofu files, or `.git`. Use `:NvfWorkspaceRoot` to inspect the detected root for the current buffer or `:NvfWorkspaceRoot <path>` for another path.
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
- Symbol search unavailable: use `<leader>ls` for fuzzy document symbols and `<leader>lw` for workspace symbols after an LSP attaches. Workspace results may take several seconds during initial indexing. Use `<leader>fs` for a Treesitter-backed current-buffer fallback, `<leader>lS` for NVF's document-symbol list, or `<leader>xs` for the Trouble symbol outline. Call hierarchy on `<leader>lci` and `<leader>lco` depends on server support.
- Duplicate diagnostics: check the owning language module and disable overlapping project plugins before adding a second NVF source. Nix should stay on `nixd` only by default; Markdown should stay on markdown-oxide rather than also enabling Marksman.
- Slow or noisy workspaces: inspect `:NvfWorkspaceRoot`, `:NvfWorkspacePolicy`, `:echo b:nvf_workspace_guard`, and `nvim --startuptime /tmp/nvim-startuptime.log +qa` before changing global defaults.
- Debug adapter failures: reproduce with the matching CLI command outside Neovim when possible, then inspect `:DapShowLog` and `:messages`. The editor does not install project dependencies or run project tests.
- CodeCompanion unavailable: confirm `programs.sandvim.enable` is true for the active profile, run `:CodeCompanionChat`, and verify `codex-acp` is on `PATH`. Do not use `:CodeCompanionCmd` or inline/action-palette prompts with the Codex ACP adapter unless a supported HTTP adapter is configured separately.
- Obsidian navigation unavailable: confirm `:Obsidian` exists, check that the buffer is inside the intended workspace root, and use `:NvfWorkspaceRoot` to inspect the dynamic current-directory workspace. For image paste failures, verify `wl-paste`, `xclip`, `pngpaste`, or PowerShell is available for the current platform and that the configured attachment directory is writable. A non-fatal `client.opts is deprecated` warning during `:checkhealth render-markdown` is currently upstream-owned: pinned `render-markdown.nvim` checks `obsidian.get_client().opts`, while pinned `obsidian.nvim` v3.16.0 wants `Obsidian.opts`.
- Flutter tooling unavailable: enter the project devshell or otherwise put `flutter` on PATH before opening Neovim. Sandvim intentionally sets `flutterPackage = null` and does not bundle the full Flutter SDK. Because NVF's no-resolve patch currently fails to apply to the pinned flutter-tools.nvim source, use a non-Nix Flutter SDK on PATH or revisit `enableNoResolvePatch` after updating NVF/flutter-tools.
- Tmux navigation issues: confirm the activated tmux config contains `run-shell .../smart-splits.tmux` and no unconditional `bind -n C-h select-pane` bindings. In Neovim, smart-splits owns `<C-h/j/k/l>` and tmux falls back to pane selection only outside Vim-aware panes.
- Codex ACP authentication failures: complete the Codex/ChatGPT login flow outside Neovim first. This configuration uses `auth_method = "chatgpt"` and does not read `OPENAI_API_KEY` from Nix.
- Tidal issues: prefer a project `tidal-ghci` when available; otherwise the bundled fallback from `tidal.nix` is used. Tidal mappings are buffer-local under `<localleader>`.

## Health checks and profiling

Use runtime checks after activation when editor behavior changes or performance regresses:

```bash
nvim --headless "+checkhealth" "+qa"
nvim --headless -c 'if exists(":CodeCompanionChat") != 2 | cquit | endif' -c 'qa!'
nvim --headless -c 'if exists(":AvanteAsk") == 2 | cquit | endif' -c 'qa!'
nvim --headless -c 'if exists(":NvfAiAsk") == 2 | cquit | endif' -c 'qa!'
nvim --headless -c 'if exists(":Obsidian") != 2 | cquit | endif' -c 'qa!'
nvim --headless -c 'if exists(":GrugFar") != 2 | cquit | endif' -c 'if exists(":DiffviewOpen") != 2 | cquit | endif' -c 'if exists(":Trouble") != 2 | cquit | endif' -c 'qa!'
nvim --headless "+checkhealth vim.lsp" "+qa"
nvim --headless "+checkhealth nvim-treesitter" "+qa"
nvim --headless "+checkhealth dap" "+qa"
nvim --startuptime /tmp/nvim-startuptime.log +qa
```

Inside Neovim, inspect `:LspInfo`, `:checkhealth`, `:TSModuleInfo`, `:DapShowLog`, `:messages`, and guarded-buffer state with `:echo b:nvf_workspace_guard`. Prefer filetype-scoped or lazy-loaded additions when NVF supports them, and update this guide with validation evidence whenever a new language, adapter, or plugin changes startup behavior.

## Adding or changing a language

1. Open a ticket tied to the NVF report or a follow-up maintenance finding. State the filetypes, LSP, formatter, linter, debug ownership, CLI validation commands, keymaps, and affected profiles.
2. Add focused module code under `home/modules/nvf/` when the language is large enough to own separately. Keep documentation and Nix ownership in `documentation.nix` and `languages-nix.nix` rather than reintroducing a shared `languages.nix`.
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
bash scripts/check-nvf-phase8.sh
bash scripts/check-nvf-phase9.sh
bash scripts/check-nvf-phase10.sh
nixfmt home/modules/nvf/*.nix flake.nix home/modules/terminal.nix
nix flake show --no-write-lock-file
nix build --no-write-lock-file .#checks.x86_64-linux.sandvimExternalConsumer
nix build --no-write-lock-file .#checks.x86_64-linux.sandvimMarkdownRuntime
nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage
nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage
```

For runtime validation without activation, build the configured Neovim package and invoke it directly:

```bash
nix build --no-write-lock-file .#homeConfigurations.terminalman.config.programs.nvf.finalPackage -o result-sandvim-nvim
./result-sandvim-nvim/bin/nvim --headless "+checkhealth" "+qa"
./result-sandvim-nvim/bin/nvim --headless -c 'if exists(":CodeCompanionChat") != 2 | cquit | endif' -c 'qa!'
./result-sandvim-nvim/bin/nvim --headless -c 'if exists(":AvanteAsk") == 2 | cquit | endif' -c 'if exists(":NvfAiAsk") == 2 | cquit | endif' -c 'qa!'
./result-sandvim-nvim/bin/nvim --headless -c 'if exists(":Obsidian") != 2 | cquit | endif' -c 'qa!'
./result-sandvim-nvim/bin/nvim --headless -c 'if exists(":GrugFar") != 2 | cquit | endif' -c 'if exists(":DiffviewOpen") != 2 | cquit | endif' -c 'if exists(":Trouble") != 2 | cquit | endif' -c 'qa!'
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
- Rust: run project checks such as `cargo fmt --check`, `cargo clippy --all-targets --all-features`, and `cargo test` from the project CLI/devshell.
- Go: run `gofmt -w` or `gofmt -l`, `go test ./...`, and project-selected `golangci-lint run` from the project CLI/devshell.
- Lua: run project-selected `stylua --check`, `luacheck`, or plugin test harnesses outside Neovim.
- SQL: run project-selected `sqlfluff lint`, migrations, and database integration tests outside Neovim; choose dialect/project config in the repository owning the SQL.
- Dart/Flutter: run `dart format`, `dart analyze`, `flutter analyze`, and `flutter test` from a devshell or SDK environment that provides `flutter` on PATH.

## Planned, not yet implemented

Later phases may add per-language debug profiles, project-local task runner UX, and explicit project override recipes. This guide does not claim those behaviors are available until their implementation tickets land.
