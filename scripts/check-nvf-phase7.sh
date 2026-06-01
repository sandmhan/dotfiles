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
    && grep -q 'https://api.openai.com' home/modules/nvf/ai-companion.nix \
    && grep -q 'show_default_prompt_library = false' home/modules/nvf/ai-companion.nix \
    && grep -q 'http = {' home/modules/nvf/ai-companion.nix \
    && grep -q 'buffer = { enabled = false }' home/modules/nvf/ai-companion.nix \
    && grep -q 'run_command = { enabled = false }' home/modules/nvf/ai-companion.nix
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

assert_phase7_runtime_codecompanion_config() {
  local tmpdir nvim_bin runtime_lua fallback_lua
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir:-}"' RETURN

  nix build --no-write-lock-file --impure --expr \
    "(builtins.getFlake \"path:$repo_root\").homeConfigurations.terminalman.config.programs.nvf.finalPackage" \
    -o "$tmpdir/nvim" >/dev/null
  nvim_bin="$tmpdir/nvim/bin/nvim"
  runtime_lua="$tmpdir/codecompanion-runtime.lua"
  fallback_lua="$tmpdir/codecompanion-fallback.lua"

  cat >"$runtime_lua" <<'LUA'
local config = require('codecompanion.config').config
assert(config.adapters.openai_compatible == nil, 'adapter must not be configured at deprecated top-level adapters.openai_compatible')
assert(type(config.adapters.http.openai_compatible) == 'function', 'http.openai_compatible adapter override missing')
assert(config.interactions.chat.adapter == 'openai_compatible', 'chat interaction is not using openai_compatible')
assert(config.interactions.inline.adapter == 'openai_compatible', 'inline interaction is not using openai_compatible')

local adapter = require('codecompanion.adapters').resolve(config.interactions.chat.adapter)
assert(adapter.name == 'openai_compatible', 'resolved adapter name mismatch: ' .. vim.inspect(adapter.name))
assert(adapter.type == 'http', 'resolved adapter type mismatch: ' .. vim.inspect(adapter.type))
assert(adapter.model and adapter.model.name == 'phase7-runtime-model', 'OPENAI_MODEL was not applied: ' .. vim.inspect(adapter.model))

local adapter_utils = require('codecompanion.utils.adapters')
adapter_utils.get_env_vars(adapter, { timeout = 1000 })
assert(adapter.env_replaced.api_key == 'phase7-runtime-key', 'OPENAI_API_KEY was not resolved')
assert(adapter.env_replaced.url == 'https://phase7.example.invalid/openai', 'OPENAI_BASE_URL was not resolved: ' .. vim.inspect(adapter.env_replaced.url))
assert(adapter_utils.set_env_vars(adapter, adapter.url) == 'https://phase7.example.invalid/openai/v1/chat/completions', 'resolved request URL mismatch')

local slash_filter = require('codecompanion.interactions.chat.slash_commands.filter')
local slash = slash_filter.filter_enabled_slash_commands(config.interactions.chat.slash_commands, { adapter = adapter })
for _, name in ipairs({ 'buffer', 'command', 'compact', 'fetch', 'file', 'help', 'image', 'mcp', 'mode', 'now', 'rules', 'symbols' }) do
  assert(config.interactions.chat.slash_commands[name].enabled == false, 'slash command not configured disabled: ' .. name)
  assert(slash[name] == nil, 'slash command still enabled after filtering: ' .. name)
end

local tool_filter = require('codecompanion.interactions.chat.tools.filter')
local tools = tool_filter.filter_enabled_tools(config.interactions.chat.tools, { adapter = adapter })
for _, name in ipairs({ 'ask_questions', 'create_file', 'delete_file', 'fetch_webpage', 'file_search', 'get_changed_files', 'get_diagnostics', 'grep_search', 'insert_edit_into_file', 'memory', 'read_file', 'run_command', 'web_search' }) do
  assert(config.interactions.chat.tools[name].enabled == false, 'tool not configured disabled: ' .. name)
  assert(tools[name] == nil, 'tool still enabled after filtering: ' .. name)
end
assert(vim.tbl_isempty(tools.groups or {}), 'tool groups should be empty after filtering: ' .. vim.inspect(tools.groups))
assert(config.interactions.chat.tools.opts.auto_submit_errors == false, 'tool auto_submit_errors should be disabled')
assert(config.interactions.chat.tools.opts.auto_submit_success == false, 'tool auto_submit_success should be disabled')
assert(config.interactions.chat.tools.opts.system_prompt.enabled == false, 'tool system prompt should be disabled')
LUA

  cat >"$fallback_lua" <<'LUA'
local config = require('codecompanion.config').config
local adapter = require('codecompanion.adapters').resolve(config.interactions.chat.adapter)
local adapter_utils = require('codecompanion.utils.adapters')
adapter_utils.get_env_vars(adapter, { timeout = 1000 })
assert(adapter.env_replaced.url == 'https://api.openai.com', 'OPENAI_BASE_URL fallback mismatch: ' .. vim.inspect(adapter.env_replaced.url))
assert(adapter_utils.set_env_vars(adapter, adapter.url) == 'https://api.openai.com/v1/chat/completions', 'fallback request URL mismatch')
LUA

  env \
    OPENAI_API_KEY='phase7-runtime-key' \
    OPENAI_BASE_URL='https://phase7.example.invalid/openai' \
    OPENAI_MODEL='phase7-runtime-model' \
    "$nvim_bin" --headless -c "luafile $runtime_lua" -c 'qa!'

  env \
    -u OPENAI_BASE_URL \
    OPENAI_API_KEY='phase7-runtime-key' \
    OPENAI_MODEL='phase7-runtime-model' \
    "$nvim_bin" --headless -c "luafile $fallback_lua" -c 'qa!'

  rm -rf "$tmpdir"
  trap - RETURN
}

check 'Phase 7 AI companion module exists and avoids committed credentials/repo slash tools' assert_phase7_ai_companion_module_exists
check 'Phase 7 default.nix import and README inventory are synchronized' assert_phase7_import_inventory_sync
check 'terminal profile enables NVF AI companion feature flag' assert_phase7_feature_flag_enabled_for_terminal_profile
check 'terminalman enables CodeCompanion config, selected-code keymaps, and guarded bridge keys' assert_phase7_terminalman_codecompanion_config
check 'built terminalman NVF package resolves CodeCompanion adapter and disabled defaults at runtime' assert_phase7_runtime_codecompanion_config
check 'operations guide documents CodeCompanion decision, privacy, Codex CLI, and Pi boundaries' assert_phase7_docs_cover_boundaries
check 'Phase 7 evidence file is indexed and records the plugin decision' assert_phase7_evidence_documented
check 'NVF-031 ticket files and index consistently mark completed work done' assert_phase7_ticket_status_done

if ((failures > 0)); then
  exit 1
fi
