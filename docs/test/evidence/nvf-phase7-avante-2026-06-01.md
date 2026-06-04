---
title: NVF Phase 7 Avante Evidence
status: accepted
updated: 2026-06-01
---

# NVF Phase 7 Avante Evidence

> Historical note: this file records a short-lived Avante rollout attempt from 2026-06-01. The current NVF in-editor AI workflow is CodeCompanion Codex ACP; see [NVF Phase 7 CodeCompanion Codex ACP Evidence](./nvf-phase7-codecompanion-codex-acp-2026-06-02.md).

## Decision

This historical validation captured an Avante workflow for the NVF in-editor OpenAI-compatible assistant path. That workflow is no longer active. Pi was removed only from the Neovim AI bridge during that attempt; standalone Pi, Codex, Claude, and shared AI skills Home Manager modules remained intact.

## Implemented behavior

- Replaced `home/modules/nvf/ai-companion.nix` with `home/modules/nvf/ai-avante.nix` and switched the default NVF import.
- Added `myHome.features.enableNvfAiAvante` and enabled it by default for the terminal profile.
- Configured `vim.assistant.avante-nvim.enable = true` behind the feature flag.
- Configured an inherited OpenAI-compatible provider using `OPENAI_API_KEY`, optional `OPENAI_BASE_URL` (fallback `https://api.openai.com/v1`), and optional `OPENAI_MODEL` (fallback `gpt-4o-mini`); no credentials are committed.
- Disabled Avante automatic keymaps, auto-suggestions, automatic diff application, automatic current-file attachment, tool auto-approval, automatic diagnostic checks, prompt logging, hints, cursor planning mode, Claude text-editor tool mode, and provider tools.
- Removed the Pi provider from `home/modules/nvf/ai.nix` while preserving the guarded Claude/Codex bridge commands, confirmation, redaction, and keymaps.

## Keymaps and commands

Guarded Claude/Codex bridge:

- `<leader>aa` / visual `<leader>aa` → `:NvfAiAsk`
- `<leader>ar` → `:NvfAiReviewDiff`
- `<leader>at` / visual `<leader>at` → `:NvfAiTests`
- `<leader>ad` → `:NvfAiDiagnostic`
- `<leader>as` → `:NvfAiSkills`

Avante plugin path:

- `<leader>ac` → `:AvanteAsk`
- Visual `<leader>ae` → selected-code edit prompt through `:AvanteEdit`
- Visual `<leader>aR` → selected-code review prompt through `:AvanteAsk`
- Visual `<leader>aT` → selected-code test-generation prompt through `:AvanteAsk`

## Validation results

Validation was run from `/home/sandmhan/dotfiles` on 2026-06-01.

| Command | Result | Notes |
|---|---|---|
| `bash scripts/check-nvf-phase5.sh` | pass | Updated to assert Pi is absent from the Neovim bridge while Claude/Codex guardrails remain. |
| `bash scripts/check-nvf-phase6.sh` | pass | README import inventory updated for `ai-avante.nix`. |
| `bash scripts/check-nvf-phase7.sh` | pass with runtime skip | Avante config, CodeCompanion removal, Pi bridge removal, docs, ticket, and runtime smoke gate passed. The build-local runtime smoke was skipped because Avante's Rust vendor staging attempted to fetch crates from crates.io and received HTTP 403. |
| `nixfmt --check home/options.nix home/profiles/terminal.nix home/modules/nvf/*.nix` | pass | Nix formatting verified after running `nixfmt`. |
| `git diff --check` | pass | No whitespace errors. |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage` | pass | Evaluates/build-plans Avante for the terminal profile. |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage` | pass | Evaluates/build-plans Avante for the Linux desktop profile. |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.wslman.activationPackage` | pass | Evaluates/build-plans Avante for the WSL profile. |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.macman.activationPackage` | pass | Evaluates/build-plans Avante for the macOS profile. |
| Build-local `nvim --headless` Avante smoke | skipped | Affected profiles: `terminalman`, `sandmhan`, `wslman`, and `macman`. Blocked by the Avante Rust dependency vendor fetch HTTP 403 above; rerun with `NVF_PHASE7_REQUIRE_RUNTIME=1 bash scripts/check-nvf-phase7.sh` in an environment that can build Avante. |

## Limitations

- Avante does not inherit the guarded bridge's redaction, sensitive-path blocking, confirmation summary, or full-buffer-selection guardrails.
- Codex subscription/OAuth remains a Codex CLI concern; Avante uses OpenAI-compatible API credentials or endpoint configuration from the runtime environment.
- Local OpenAI-compatible endpoints should be secured before use.
- Runtime checks may require a successful Avante package build; local validation should record any external crate-fetch or builder limitation explicitly.
