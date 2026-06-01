#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

failures=0

check() {
  local name="$1"
  shift

  if "$@"; then
    printf 'ok - %s\n' "$name"
  else
    printf 'not ok - %s\n' "$name" >&2
    failures=$((failures + 1))
  fi
}

nix_eval_raw() {
  nix eval --raw --no-write-lock-file "$@"
}

assert_phase7_ai_companion_module_exists() {
  [[ -f home/modules/nvf/ai-companion.nix ]] \
    && grep -q 'codecompanion-nvim' home/modules/nvf/ai-companion.nix \
    && grep -q 'OPENAI_API_KEY' home/modules/nvf/ai-companion.nix \
    && grep -q 'OPENAI_BASE_URL' home/modules/nvf/ai-companion.nix \
    && grep -q 'OPENAI_MODEL' home/modules/nvf/ai-companion.nix \
    && grep -q 'show_default_prompt_library = false' home/modules/nvf/ai-companion.nix \
    && grep -q 'slash_commands = mkLuaInline "{}"' home/modules/nvf/ai-companion.nix \
    && grep -q 'tools = { }' home/modules/nvf/ai-companion.nix
}

assert_phase7_import_inventory_sync() {
  grep -q '^[[:space:]]*./ai-companion\.nix$' home/modules/nvf/default.nix \
    && grep -Fq "| \`ai-companion.nix\` | CodeCompanion.nvim" README.md \
    && bash scripts/check-nvf-phase6.sh >/dev/null
}

assert_phase7_feature_flag_enabled_for_terminal_profile() {
  local expr result
  expr=$(cat <<'NIX'
let
  flake = builtins.getFlake "path:__REPO_ROOT__";
in
if flake.homeConfigurations.terminalman.config.myHome.features.enableNvfAiCompanion then "true" else "false"
NIX
)
  expr="${expr//__REPO_ROOT__/$repo_root}"
  result="$(nix_eval_raw --impure --expr "$expr")"
  [[ "$result" == "true" ]]
}

assert_phase7_terminalman_codecompanion_config() {
  local expr result
  expr=$(cat <<'NIX'
let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  vim = flake.homeConfigurations.terminalman.config.programs.nvf.settings.vim;
  companion = vim.assistant.codecompanion-nvim;
  keymaps = vim.keymaps or [];
  hasMode = expected: mode: if builtins.isList mode then builtins.elem expected mode else mode == expected;
  hasMapping = key: command: mode:
    builtins.any
      (mapping:
        mapping.key == key
        && mapping.action == command
        && hasMode mode mapping.mode
        && builtins.length (builtins.split "CodeCompanion" mapping.desc) > 1)
      keymaps;
  hasVisualPrefix = key: text:
    builtins.any
      (mapping:
        mapping.key == key
        && hasMode "x" mapping.mode
        && builtins.length (builtins.split text mapping.action) > 1
        && builtins.length (builtins.split "CodeCompanion" mapping.desc) > 1)
      keymaps;
  reservedBridgeKeysUntouched =
    builtins.any (mapping: mapping.key == "<leader>aa" && mapping.action == "<cmd>NvfAiAsk<cr>") keymaps
    && builtins.any (mapping: mapping.key == "<leader>ar" && mapping.action == "<cmd>NvfAiReviewDiff<cr>") keymaps
    && builtins.any (mapping: mapping.key == "<leader>at" && mapping.action == "<cmd>NvfAiTests<cr>") keymaps
    && builtins.any (mapping: mapping.key == "<leader>ad" && mapping.action == "<cmd>NvfAiDiagnostic<cr>") keymaps
    && builtins.any (mapping: mapping.key == "<leader>as" && mapping.action == "<cmd>NvfAiSkills<cr>") keymaps;
  noReservedCodeCompanionReuse =
    !(builtins.any
      (mapping:
        builtins.elem mapping.key [ "<leader>aa" "<leader>ar" "<leader>at" "<leader>ad" "<leader>as" ]
        && builtins.length (builtins.split "CodeCompanion" mapping.action) > 1)
      keymaps);
in
if
  companion.enable
  && companion.setupOpts.opts.log_level == "ERROR"
  && companion.setupOpts.display.diff.enabled
  && companion.setupOpts.display.diff.provider == "inline"
  && companion.setupOpts.display.diff.layout == "vertical"
  && companion.setupOpts.display.action_palette.opts.show_default_prompt_library == false
  && companion.setupOpts.interactions.chat.adapter == "openai_compatible"
  && companion.setupOpts.interactions.inline.adapter == "openai_compatible"
  && builtins.hasAttr "Review selected code" companion.setupOpts.prompt_library
  && builtins.hasAttr "Edit selected code" companion.setupOpts.prompt_library
  && builtins.hasAttr "Generate tests for selected code" companion.setupOpts.prompt_library
  && builtins.hasAttr "Explain selected code" companion.setupOpts.prompt_library
  && hasMapping "<leader>ac" "<cmd>CodeCompanionChat<cr>" "n"
  && hasMapping "<leader>aA" "<cmd>CodeCompanionActions<cr>" "n"
  && hasVisualPrefix "<leader>ae" "CodeCompanion Edit the selected code"
  && hasVisualPrefix "<leader>aR" "CodeCompanion Review the selected code"
  && hasVisualPrefix "<leader>aT" "CodeCompanion Generate tests for the selected code"
  && reservedBridgeKeysUntouched
  && noReservedCodeCompanionReuse
then
  "true"
else
  "false"
NIX
)
  expr="${expr//__REPO_ROOT__/$repo_root}"
  result="$(nix_eval_raw --impure --expr "$expr")"
  [[ "$result" == "true" ]]
}

assert_phase7_docs_cover_boundaries() {
  grep -q 'CodeCompanion.nvim rather than Avante.nvim' docs/neovim-ide.md \
    && grep -q 'guarded bridge' docs/neovim-ide.md \
    && grep -Fq "Codex CLI (\`codex exec\`) for subscription/OAuth-backed Codex workflows" docs/neovim-ide.md \
    && grep -q 'Keep Pi as a separate guarded orchestration path' docs/neovim-ide.md \
    && grep -q 'Credentials are never committed to Nix' docs/neovim-ide.md \
    && grep -q 'Privacy boundary: CodeCompanion does not inherit' docs/neovim-ide.md \
    && grep -q '<leader>ac' docs/neovim-ide.md \
    && grep -Fq "Visual \`<leader>ae\`" docs/neovim-ide.md
}

assert_phase7_evidence_documented() {
  grep -q 'NVF Phase 7 AI Companion Evidence' docs/test/evidence/README.md \
    && [[ -f docs/test/evidence/nvf-phase7-ai-companion-2026-06-01.md ]] \
    && grep -q 'Chosen tool: CodeCompanion.nvim' docs/test/evidence/nvf-phase7-ai-companion-2026-06-01.md \
    && grep -q 'Avante.nvim was not adopted' docs/test/evidence/nvf-phase7-ai-companion-2026-06-01.md
}

assert_phase7_ticket_status_done() {
  grep -q '^status: done$' docs/tickets/NVF-031.md \
    && grep -F '| [NVF-031](NVF-031.md) ' docs/tickets/index.md \
      | grep -F '| done | NVF Phase 7 |' >/dev/null
}

check 'Phase 7 AI companion module exists and avoids committed credentials/repo slash tools' assert_phase7_ai_companion_module_exists
check 'Phase 7 default.nix import and README inventory are synchronized' assert_phase7_import_inventory_sync
check 'terminal profile enables NVF AI companion feature flag' assert_phase7_feature_flag_enabled_for_terminal_profile
check 'terminalman enables CodeCompanion config, selected-code keymaps, and guarded bridge keys' assert_phase7_terminalman_codecompanion_config
check 'operations guide documents CodeCompanion decision, privacy, Codex CLI, and Pi boundaries' assert_phase7_docs_cover_boundaries
check 'Phase 7 evidence file is indexed and records the plugin decision' assert_phase7_evidence_documented
check 'NVF-031 ticket files and index consistently mark completed work done' assert_phase7_ticket_status_done

if ((failures > 0)); then
  exit 1
fi
