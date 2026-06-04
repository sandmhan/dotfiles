---
title: NVF Phase 7 CodeCompanion Codex ACP Evidence
status: accepted
updated: 2026-06-04
---

# NVF Phase 7 CodeCompanion Codex ACP Evidence

## Decision

CodeCompanion Codex ACP is the current NVF in-editor AI workflow. The active NVF configuration enables CodeCompanion.nvim, installs `codex-acp`, and authenticates the Codex ACP adapter with ChatGPT auth (`auth_method = "chatgpt"`). Avante.nvim and the old `NvfAi*` bridge commands are not active in NVF.

## Implemented behavior

- `home/modules/nvf/default.nix` imports `home/modules/nvf/ai-codecompanion.nix` after `hardening.nix` and before `completion.nix`.
- `home/modules/nvf/ai-codecompanion.nix` is gated by `myHome.features.enableNvfAiCodeCompanion`.
- The feature installs `pkgs.codex-acp` and enables `vim.assistant.codecompanion-nvim`.
- CodeCompanion chat uses adapter `codex`; the adapter command is `codex-acp`; adapter defaults set `auth_method = "chatgpt"`, `mcpServers = {}`, and a 20 second timeout.
- CodeCompanion command (`:CodeCompanionCmd`) and inline/action-palette interactions are HTTP-adapter-only upstream, so the Codex ACP adapter is not assigned to those interactions and action-palette prompt/action display is hidden.
- API-key and OpenAI-compatible HTTP provider wiring are not configured in Nix.
- Avante modules/imports and `NvfAi*` bridge modules/imports are removed from active NVF.
- Terminal profile enables `enableNvfAiCodeCompanion` by default.

## Validation results

Validation was initially run from `/home/sandmhan/dotfiles` on 2026-06-02. The chat-only Codex ACP revision was revalidated on 2026-06-04 with `git diff --check`, `bash -n scripts/check-nvf-phase7.sh`, and `bash scripts/check-nvf-phase7.sh`; Home Manager dry-run rows below are retained from the original rollout evidence.

| Command | Result | Notes |
|---|---|---|
| `bash scripts/check-nvf-phase5.sh` | pass | Verifies the retired Phase 5 `NvfAi*` bridge is not active in NVF while historical evidence remains indexed. |
| `bash scripts/check-nvf-phase6.sh` | pass | Verifies the README NVF module inventory is synchronized with `home/modules/nvf/default.nix`. |
| `bash scripts/check-nvf-phase7.sh` | pass | Verifies chat-only CodeCompanion Codex ACP module wiring, terminal profile feature flag, `codex-acp` installation, ChatGPT auth configuration, hidden unsupported command/inline/action-palette workflows, absence of API-key/OpenAI-compatible/Avante/`NvfAi*` wiring, docs/evidence/ticket synchronization, build-local `checkhealth`, `:CodeCompanionChat` availability, and absence of `:AvanteAsk`/`:NvfAiAsk`. |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage` | pass | Affected by shared terminal NVF profile; dry-run evaluated successfully. Would build 5 derivations and fetch `codex-acp-0.9.2`. |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage` | pass | Affected through desktop → terminal profile; dry-run evaluated successfully. Would build 5 derivations and fetch `codex-acp-0.9.2`. |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.wslman.activationPackage` | pass | Affected through WSL → terminal profile; dry-run evaluated successfully. Would build 5 derivations and fetch `codex-acp-0.9.2`. |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.macman.activationPackage` | pass | Affected through macOS → terminal profile; cross-platform dry-run evaluated successfully. Would build 144 derivations and fetch 1349 paths, including `codex-acp-0.9.2`. |
| `bash -n scripts/check-nvf-phase5.sh scripts/check-nvf-phase7.sh` | pass | Shell syntax OK. |
| `git diff --check` | pass | No whitespace errors in the working-tree diff. |

## Runtime smoke expectations

When the build-local `terminalman` NVF package can be built, `scripts/check-nvf-phase7.sh` runs:

```bash
nvim --headless "+checkhealth" "+qa"
nvim --headless -c 'if exists(":CodeCompanionChat") != 2 | cquit | endif' -c 'qa!'
nvim --headless -c 'if exists(":AvanteAsk") == 2 | cquit | endif' -c 'qa!'
nvim --headless -c 'if exists(":NvfAiAsk") == 2 | cquit | endif' -c 'qa!'
```

If that package build is unavailable, the script prints an explicit runtime skip unless `NVF_PHASE7_REQUIRE_RUNTIME=1` is set.

## Limitations

- CodeCompanion does not provide the retired bridge's pre-send redaction, sensitive-path blocking, confirmation summary, or full-buffer-selection guardrails.
- ChatGPT/Codex login state is external to Nix and must be prepared outside Neovim.
- Runtime smoke checks use a build-local NVF package rather than activating affected Home Manager profiles.
- CodeCompanion may still register upstream command/inline entry points, but this profile neither maps nor configures them for Codex ACP because those interactions require HTTP adapters.
