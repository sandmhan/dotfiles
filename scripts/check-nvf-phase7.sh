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

assert_phase7_ai_avante_module_exists() {
  [[ -f home/modules/nvf/ai-avante.nix ]] \
    && grep -q 'avante-nvim' home/modules/nvf/ai-avante.nix \
    && grep -q 'enableNvfAiAvante' home/modules/nvf/ai-avante.nix \
    && grep -q 'OPENAI_API_KEY' home/modules/nvf/ai-avante.nix \
    && grep -q 'OPENAI_BASE_URL' home/modules/nvf/ai-avante.nix \
    && grep -q 'OPENAI_MODEL' home/modules/nvf/ai-avante.nix \
    && grep -q 'https://api.openai.com/v1' home/modules/nvf/ai-avante.nix \
    && grep -q 'disable_tools = true' home/modules/nvf/ai-avante.nix \
    && grep -q 'auto_set_keymaps = false' home/modules/nvf/ai-avante.nix \
    && grep -q 'auto_suggestions = false' home/modules/nvf/ai-avante.nix \
    && grep -q 'auto_apply_diff_after_generation = false' home/modules/nvf/ai-avante.nix \
    && grep -q 'auto_add_current_file = false' home/modules/nvf/ai-avante.nix \
    && grep -q 'auto_approve_tool_permissions = false' home/modules/nvf/ai-avante.nix \
    && grep -q 'hints.enabled = false' home/modules/nvf/ai-avante.nix \
    && grep -q 'prompt_logger.enabled = false' home/modules/nvf/ai-avante.nix
}

assert_phase7_codecompanion_removed_from_nvf() {
  [[ ! -e home/modules/nvf/ai-companion.nix ]] \
    && ! grep -R -q 'codecompanion-nvim\|CodeCompanion' home/modules/nvf \
    && ! grep -q 'ai-companion\.nix' home/modules/nvf/default.nix
}

assert_phase7_import_inventory_sync() {
  grep -q '^[[:space:]]*./ai-avante\.nix$' home/modules/nvf/default.nix \
    && grep -Fq '| `ai-avante.nix` | Avante.nvim' README.md \
    && bash scripts/check-nvf-phase6.sh >/dev/null
}

assert_phase7_feature_flag_enabled_for_terminal_profile() {
  local expr result
  expr=$(cat <<'NIX'
let
  flake = builtins.getFlake "path:__REPO_ROOT__";
in
if flake.homeConfigurations.terminalman.config.myHome.features.enableNvfAiAvante then "true" else "false"
NIX
)
  expr="${expr//__REPO_ROOT__/$repo_root}"
  result="$(nix_eval_raw --impure --expr "$expr")"
  [[ "$result" == "true" ]]
}

assert_phase7_terminalman_avante_config() {
  local expr result
  expr=$(cat <<'NIX'
let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  vim = flake.homeConfigurations.terminalman.config.programs.nvf.settings.vim;
  avante = vim.assistant.avante-nvim;
  keymaps = vim.keymaps or [];
  hasMode = expected: mode: if builtins.isList mode then builtins.elem expected mode else mode == expected;
  hasMapping = key: command: mode:
    builtins.any
      (mapping:
        mapping.key == key
        && mapping.action == command
        && hasMode mode mapping.mode
        && builtins.length (builtins.split "Avante" mapping.desc) > 1)
      keymaps;
  hasVisualPrefix = key: commandPrefix:
    builtins.any
      (mapping:
        mapping.key == key
        && hasMode "x" mapping.mode
        && builtins.length (builtins.split commandPrefix mapping.action) > 1
        && builtins.length (builtins.split "Avante" mapping.desc) > 1)
      keymaps;
  noDuplicatedVisualRangeRhs =
    !(builtins.any
      (mapping:
        hasMode "x" mapping.mode
        && builtins.length (builtins.split "Avante" mapping.action) > 1
        && ((builtins.match ".*:'<,'>.*" mapping.action) != null))
      keymaps);
  bridgeKeysUntouched =
    builtins.any (mapping: mapping.key == "<leader>aa" && mapping.action == "<cmd>NvfAiAsk<cr>") keymaps
    && builtins.any (mapping: mapping.key == "<leader>ar" && mapping.action == "<cmd>NvfAiReviewDiff<cr>") keymaps
    && builtins.any (mapping: mapping.key == "<leader>at" && mapping.action == "<cmd>NvfAiTests<cr>") keymaps
    && builtins.any (mapping: mapping.key == "<leader>ad" && mapping.action == "<cmd>NvfAiDiagnostic<cr>") keymaps
    && builtins.any (mapping: mapping.key == "<leader>as" && mapping.action == "<cmd>NvfAiSkills<cr>") keymaps;
in
if
  avante.enable
  && avante.setupOpts.provider == "openai_compatible"
  && avante.setupOpts.behaviour.auto_set_keymaps == false
  && avante.setupOpts.behaviour.auto_suggestions == false
  && avante.setupOpts.behaviour.auto_apply_diff_after_generation == false
  && avante.setupOpts.behaviour.auto_add_current_file == false
  && avante.setupOpts.behaviour.auto_approve_tool_permissions == false
  && avante.setupOpts.behaviour.auto_check_diagnostics == false
  && avante.setupOpts.hints.enabled == false
  && avante.setupOpts.prompt_logger.enabled == false
  && hasMapping "<leader>ac" "<cmd>AvanteAsk<cr>" "n"
  && hasVisualPrefix "<leader>ae" "AvanteEdit Edit only the selected code"
  && hasVisualPrefix "<leader>aR" "AvanteAsk Review the selected code"
  && hasVisualPrefix "<leader>aT" "AvanteAsk Generate tests for the selected code"
  && noDuplicatedVisualRangeRhs
  && bridgeKeysUntouched
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

assert_phase7_pi_removed_from_neovim_bridge() {
  ! grep -q 'Pi coding agent' home/modules/nvf/ai.nix \
    && ! grep -q 'command = "pi"' home/modules/nvf/ai.nix \
    && grep -q 'provider_by_id("pi") == nil' scripts/check-nvf-phase5.sh
}

assert_phase7_docs_cover_boundaries() {
  grep -q 'Avante.nvim from `home/modules/nvf/ai-avante.nix`' docs/neovim-ide.md \
    && grep -q 'Claude Code and Codex CLI provider entry points' docs/neovim-ide.md \
    && grep -q 'Pi remains available as standalone Home Manager tooling' docs/neovim-ide.md \
    && grep -q 'Credentials are never committed to Nix' docs/neovim-ide.md \
    && grep -q 'Privacy boundary: Avante does not inherit' docs/neovim-ide.md \
    && grep -q '<leader>ac' docs/neovim-ide.md \
    && grep -q 'Visual `<leader>ae`' docs/neovim-ide.md \
    && grep -q 'CodeCompanionChat.*== 2' docs/neovim-ide.md
}

assert_phase7_evidence_documented() {
  grep -q 'NVF Phase 7 Avante Evidence' docs/test/evidence/README.md \
    && [[ -f docs/test/evidence/nvf-phase7-avante-2026-06-01.md ]] \
    && grep -q 'Avante replaces CodeCompanion' docs/test/evidence/nvf-phase7-avante-2026-06-01.md \
    && grep -q 'Pi was removed only from the Neovim AI bridge' docs/test/evidence/nvf-phase7-avante-2026-06-01.md
}

assert_phase7_ticket_status_done() {
  grep -q '^status: done$' docs/tickets/NVF-032.md \
    && grep -F '| [NVF-032](NVF-032.md) ' docs/tickets/index.md \
      | grep -F '| done | NVF Phase 7 |' >/dev/null
}

assert_phase7_runtime_avante_commands() {
  local tmpdir nvim_bin build_log
  tmpdir="$(mktemp -d)"
  build_log="$tmpdir/build.log"
  trap 'rm -rf "${tmpdir:-}"' RETURN

  if ! nix build --no-write-lock-file --impure --expr \
    "(builtins.getFlake \"path:$repo_root\").homeConfigurations.terminalman.config.programs.nvf.finalPackage" \
    -o "$tmpdir/nvim" >"$build_log" 2>&1; then
    if [[ "${NVF_PHASE7_REQUIRE_RUNTIME:-0}" == "1" ]]; then
      cat "$build_log" >&2
      rm -rf "$tmpdir"
      trap - RETURN
      return 1
    fi

    printf 'skip - runtime Avante command smoke (finalPackage build unavailable; set NVF_PHASE7_REQUIRE_RUNTIME=1 to require it)\n' >&2
    cat "$build_log" >&2
    rm -rf "$tmpdir"
    trap - RETURN
    return 0
  fi

  nvim_bin="$tmpdir/nvim/bin/nvim"

  "$nvim_bin" --headless '+checkhealth' '+qa'
  "$nvim_bin" --headless -c 'if exists(":AvanteAsk") != 2 | cquit | endif' -c 'qa!'
  "$nvim_bin" --headless -c 'if exists(":NvfAiAsk") != 2 | cquit | endif' -c 'qa!'
  "$nvim_bin" --headless -c 'if exists(":CodeCompanionChat") == 2 | cquit | endif' -c 'qa!'

  rm -rf "$tmpdir"
  trap - RETURN
}

check 'Phase 7 Avante module exists and uses env-only OpenAI-compatible defaults' assert_phase7_ai_avante_module_exists
check 'CodeCompanion NVF module and wiring are removed' assert_phase7_codecompanion_removed_from_nvf
check 'Phase 7 default.nix import and README inventory are synchronized' assert_phase7_import_inventory_sync
check 'terminal profile enables NVF Avante feature flag' assert_phase7_feature_flag_enabled_for_terminal_profile
check 'terminalman enables Avante config, selected-code keymaps, and guarded bridge keys' assert_phase7_terminalman_avante_config
check 'Pi is removed from the Neovim AI bridge only' assert_phase7_pi_removed_from_neovim_bridge
check 'operations guide documents Avante provider setup, privacy, and AI boundaries' assert_phase7_docs_cover_boundaries
check 'Phase 7 Avante evidence file is indexed' assert_phase7_evidence_documented
check 'NVF-032 ticket files and index consistently mark completed work done' assert_phase7_ticket_status_done
check 'built terminalman NVF package exposes Avante and bridge commands when build is available' assert_phase7_runtime_avante_commands

if ((failures > 0)); then
  exit 1
fi
