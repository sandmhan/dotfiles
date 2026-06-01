---
title: NVF Phase 5 AI Bridge Evidence
status: accepted
updated: 2026-05-31
---

# NVF Phase 5 AI Bridge Evidence

## Scope

Phase 5 validation for the guarded NVF AI bridge (`NVF-021`, `NVF-022`, `NVF-023`, and `NVF-024`): `home/modules/nvf/ai.nix`, import order after workspace hardening, `<leader>a` keymaps, Claude/Codex/Pi provider discovery, confirmation prompts, scoped context, sensitive-path blocking, secret-like redaction, and documentation updates.

## Option schema validation

Confirmed implementation path for the pinned NVF input before marking Phase 5 done:

- `vim.luaConfigRC` remains the supported NVF DAG hook for custom Lua setup; Phase 5 uses `luaConfigRC.ai-bridge.after = [ "workspace-hardening" ]` so workspace root helpers are available first.
- `vim.keymaps` remains the WhichKey label source through mapping `desc` fields; Phase 5 adds `<leader>aa`, `<leader>ar`, `<leader>at`, `<leader>ad`, and `<leader>as` mappings.
- No first-class NVF AI-provider options were introduced. The bridge is intentionally thin and reuses existing Home Manager provider modules: `ai-claude.nix`, `ai-codex.nix`, `ai-pi.nix`, and shared skills from `AI_SKILLS_DIR`.

## Guardrail behavior

- Provider CLIs are discovered with `vim.fn.exepath`; actions fail safely when `claude`, `codex`, or `pi` are unavailable.
- Provider invocations are built as argv lists and executed with `vim.system`; shell command strings are not used. Claude and Codex keep stdin prompts, while Pi uses `pi -p <prompt>` so it runs in documented non-interactive mode.
- Users must confirm before invocation. The confirmation includes destination provider, action, exact scope, context size, redaction count, and workspace root.
- Full buffers are not collected automatically. Visual selections that cover the full buffer are blocked, and normal-mode ask/test actions use typed prompts instead of current-buffer contents.
- Context is limited to selected text, typed prompts, current diagnostics, current git diff, or a selected shared skill/rule. Sensitive paths such as `secrets/`, `.env`, private-key files, SOPS YAML markers even mid-file or with git-diff `+`/`-` line prefixes, and key material are blocked; quoted, escaped-quote, unquoted, and multiple same-line secret-like values are redacted before confirmation.

## GREEN validation

Commands:

```bash
bash scripts/check-nvf-baseline.sh
bash scripts/check-nvf-phase2.sh
bash scripts/check-nvf-phase3.sh
bash scripts/check-nvf-phase4.sh
bash scripts/check-nvf-phase5.sh
bash -n scripts/check-nvf-phase5.sh
nix run --no-write-lock-file nixpkgs#shellcheck -- scripts/check-nvf-phase5.sh
nixfmt --check home/modules/nvf/*.nix
git diff --check
nix eval --raw --no-write-lock-file .#homeConfigurations.terminalman.config.programs.nvf.settings.vim.luaConfigRC.ai-bridge.data >/tmp/nvf-ai-lua.txt
nvim --headless -u NORC -c 'luafile /tmp/nvf-ai-lua.txt' -c 'qa!'
nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage
nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage
```

Result: all commands passed on 2026-05-31.

```text
ok - Phase 5 AI bridge module exists
ok - Phase 5 AI bridge module is imported after hardening and before completion
ok - terminalman enables guarded AI bridge, providers, commands, and keymaps
ok - AI bridge guardrails redact and block representative unsafe contexts
ok - README, operations guide, and evidence index document Phase 5 AI bridge
ok - Phase 5 ticket files and index consistently mark completed work done
ok - bash -n scripts/check-nvf-phase5.sh
ok - shellcheck scripts/check-nvf-phase5.sh
ok - nixfmt --check home/modules/nvf/*.nix
ok - git diff --check
ok - AI bridge Lua smoke test
ok - terminalman dry-run
ok - sandmhan dry-run
```

Follow-up guardrail regression validation on 2026-05-31 added coverage for escaped quotes in quoted secret values and git-diff-prefixed SOPS markers (`+sops:` and `-sops:`). `bash -n scripts/check-nvf-phase5.sh`, `bash scripts/check-nvf-phase5.sh`, `nix run --no-write-lock-file nixpkgs#shellcheck -- scripts/check-nvf-phase5.sh`, `nixfmt --check home/modules/nvf/*.nix`, and `git diff --check` passed.

The Home Manager evaluations emitted the existing `gtk.gtk4.theme` state-version warning for Linux profiles. It is unrelated to NVF Phase 5 and did not block evaluation.

## Runtime notes

Runtime provider execution still depends on each CLI being installed and authenticated in the user profile. The bridge does not enable autonomous modes and does not change Codex sandbox or approval policy. The Phase 5 validator now includes a headless Lua guardrail harness for quoted/unquoted redaction, escaped quotes inside quoted secret values, multiple same-line JSON/env/YAML secret assignments, mid-file and git-diff-prefixed SOPS blocking, private-key markers, sensitive paths, full-buffer range blocking, and Pi argv construction. The harness also forces Neovim Lua assertion errors to fail the shell check instead of being masked by the final `qa!` command.
