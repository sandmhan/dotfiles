---
title: NVF Phase 7 AI Companion Evidence
status: accepted
updated: 2026-06-01
---

# NVF Phase 7 AI Companion Evidence

## Decision

Chosen tool: CodeCompanion.nvim.

Avante.nvim was not adopted for this production-safe rollout. NVF packages Avante.nvim and exposes `vim.assistant.avante-nvim`, so it is feasible, but its Cursor-like workflow, heavier Rust-backed package surface, auto-suggestion/auto-keymap behavior, and diff/application ergonomics are a worse fit for this repository's guardrail-first policy. CodeCompanion.nvim is also NVF-supported and provides the needed chat, selected-code inline edit, action palette, OpenAI-compatible adapter, prompt library, and diff display while preserving `home/modules/nvf/ai.nix` as the guarded Claude/Codex/Pi bridge.

## Implemented behavior

- Added `myHome.features.enableNvfAiCompanion` and enabled it by default in the terminal profile.
- Added `home/modules/nvf/ai-companion.nix` with CodeCompanion.nvim behind the feature flag.
- Configured the active CodeCompanion HTTP `openai_compatible` adapter path using `OPENAI_API_KEY`, optional `OPENAI_BASE_URL` (fallback `https://api.openai.com`), and optional `OPENAI_MODEL`; no credentials are committed.
- Disabled default prompt-library display; configured CodeCompanion built-in slash commands (`/file`, `/buffer`, `/symbols`, and related commands) and built-in chat tools (`run_command`, file edit/read/search tools, web fetch/search, and related agent groups) as disabled; chat variables remain empty.
- Added curated selected-code prompt-library entries for review, edit, tests, and explanation.
- Preserved existing guarded AI bridge keymaps and commands in `home/modules/nvf/ai.nix`.

## Keymaps and commands

Guarded bridge remains unchanged:

- `<leader>aa` / visual `<leader>aa` → `:NvfAiAsk`
- `<leader>ar` → `:NvfAiReviewDiff`
- `<leader>at` / visual `<leader>at` → `:NvfAiTests`
- `<leader>ad` → `:NvfAiDiagnostic`
- `<leader>as` → `:NvfAiSkills`

CodeCompanion plugin path:

- `<leader>ac` → `:CodeCompanionChat`
- `<leader>aA` → `:CodeCompanionActions`
- Visual `<leader>ae` → selected-code edit prompt through `:CodeCompanion`
- Visual `<leader>aR` → selected-code review prompt through `:CodeCompanion`
- Visual `<leader>aT` → selected-code test-generation prompt through `:CodeCompanion`

## Validation results

Validation was run from `/home/sandmhan/dotfiles` on 2026-06-01.

| Command | Result | Notes |
|---|---|---|
| `bash scripts/check-nvf-baseline.sh` | pass | Re-run after staging new files so the flake source included `ai-companion.nix` |
| `bash scripts/check-nvf-phase2.sh` | pass | Existing language assertions unchanged |
| `bash scripts/check-nvf-phase3.sh` | pass | Existing testing/DAP assertions unchanged |
| `bash scripts/check-nvf-phase4.sh` | pass | Existing hardening assertions unchanged |
| `bash scripts/check-nvf-phase5.sh` | pass | Guarded AI bridge regression checks still pass; one transient Nix eval-cache SQLite busy warning was ignored by Nix |
| `bash scripts/check-nvf-phase6.sh` | pass | README import inventory remains synchronized with `default.nix` |
| `bash scripts/check-nvf-phase7.sh` | pass | Revised script builds the terminalman NVF package and inspects resolved runtime CodeCompanion config: active `adapters.http.openai_compatible`, env-driven URL/model/key resolution, `OPENAI_BASE_URL` fallback, and disabled slash commands/tools after CodeCompanion filtering |
| `bash -n scripts/check-nvf-phase7.sh` | pass | Script syntax OK |
| `nix run --no-write-lock-file nixpkgs#shellcheck -- scripts/check-nvf-phase7.sh` | pass | Fixed SC2016 findings by using fixed-string/double-quoted grep patterns |
| `nixfmt --check home/options.nix home/profiles/terminal.nix home/modules/nvf/*.nix` | pass | Nix formatting OK |
| `git diff --check` | pass | No whitespace errors |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage` | pass | Evaluates/build-plans CodeCompanion for Linux headless profile |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage` | pass | Evaluates/build-plans CodeCompanion for Linux desktop profile |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.wslman.activationPackage` | pass | Evaluates/build-plans CodeCompanion for WSL profile |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.macman.activationPackage` | pass | Cross-system dry-run evaluated from Linux and produced a build plan |
| `nix build --no-write-lock-file --impure --expr '(builtins.getFlake "path:/home/sandmhan/dotfiles").homeConfigurations.terminalman.config.programs.nvf.finalPackage' -o /tmp/nvf-phase7-nvim` | pass | Built the terminalman NVF package for runtime smoke checks without activating Home Manager |
| `/tmp/nvf-phase7-nvim/bin/nvim --headless "+checkhealth" "+qa"` | pass | Build-local NVF package completed checkhealth |
| `/tmp/nvf-phase7-nvim/bin/nvim --headless -c 'if exists(":CodeCompanionChat") != 2 \| cquit \| endif' -c 'qa!'` | pass | CodeCompanion command registered in the built package |
| `/tmp/nvf-phase7-nvim/bin/nvim --headless -c 'if exists(":NvfAiAsk") != 2 \| cquit \| endif' -c 'qa!'` | pass | Guarded bridge command still registered in the built package |
| `OPENAI_API_KEY=phase7-runtime-key OPENAI_BASE_URL=https://phase7.example.invalid/openai OPENAI_MODEL=phase7-runtime-model /tmp/nvf-phase7-nvim/bin/nvim --headless ...` | pass | Runtime inspection confirmed CodeCompanion resolves the active HTTP `openai_compatible` adapter with the env-provided key, base URL, and model, and that built-in slash commands/tools are filtered disabled |
| `env -u OPENAI_BASE_URL OPENAI_API_KEY=phase7-runtime-key OPENAI_MODEL=phase7-runtime-model /tmp/nvf-phase7-nvim/bin/nvim --headless ...` | pass | Runtime inspection confirmed the documented `https://api.openai.com` base URL fallback |

A control check against the currently activated `nvim` also completed `checkhealth` and still exposed `:NvfAiAsk`, but `:CodeCompanionChat` was unavailable before activation. The build-local package above is the runtime evidence for this change without switching the user's profile.

## Limitations

- CodeCompanion does not inherit the bridge's redaction, sensitive-path blocking, confirmation summary, or full-buffer-selection guardrails; its disabled slash commands/tools reduce plugin context/tool surface but are not a substitute for the guarded bridge.
- Codex subscription/OAuth remains a Codex CLI concern; the plugin uses OpenAI-compatible API credentials or endpoint configuration from the runtime environment.
- Local OpenAI-compatible endpoints should be secured before use.
- Runtime checks used a build-local NVF package instead of activating Home Manager, so profile activation behavior was not tested.
