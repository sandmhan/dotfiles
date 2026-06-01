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
    && grep -q 'show_preset_actions = false' home/modules/nvf/ai-companion.nix \
    && grep -q 'show_preset_prompts = false' home/modules/nvf/ai-companion.nix \
    && ! grep -q 'stop_context_insertion = true' home/modules/nvf/ai-companion.nix \
    && grep -q 'triggers.editor_context = mkLuaInline "nil"' home/modules/nvf/ai-companion.nix \
    && grep -q 'nvf_hardening' home/modules/nvf/ai-companion.nix \
    && grep -q 'autoload = false' home/modules/nvf/ai-companion.nix \
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
  hasMappingPrefix = key: commandPrefix: mode:
    builtins.any
      (mapping:
        mapping.key == key
        && hasMode mode mapping.mode
        && builtins.length (builtins.split commandPrefix mapping.action) > 1
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
  noNormalActionPaletteMapping =
    !(builtins.any
      (mapping:
        mapping.key == "<leader>aA"
        && hasMode "n" mapping.mode
        && builtins.length (builtins.split "CodeCompanionActions" mapping.action) > 1)
      keymaps);
in
if
  companion.enable
  && companion.setupOpts.opts.log_level == "ERROR"
  && companion.setupOpts.display.diff.enabled
  && companion.setupOpts.display.diff.provider == "inline"
  && companion.setupOpts.display.diff.layout == "vertical"
  && companion.setupOpts.display.action_palette.opts.show_preset_actions == false
  && companion.setupOpts.display.action_palette.opts.show_preset_prompts == false
  && companion.setupOpts.display.action_palette.opts.show_preset_rules == false
  && !(builtins.hasAttr "show_prompt_library_builtins" companion.setupOpts.display.action_palette.opts)
  && builtins.hasAttr "nvf_hardening" companion.setupOpts.extensions
  && companion.setupOpts.rules.opts.chat.enabled == false
  && companion.setupOpts.rules.opts.chat.autoload == false
  && companion.setupOpts.rules.opts.show_presets == false
  && companion.setupOpts.interactions.chat.adapter == "openai_compatible"
  && companion.setupOpts.interactions.inline.adapter == "openai_compatible"
  && builtins.hasAttr "Review selected code" companion.setupOpts.prompt_library
  && builtins.hasAttr "Edit selected code" companion.setupOpts.prompt_library
  && builtins.hasAttr "Generate tests for selected code" companion.setupOpts.prompt_library
  && builtins.hasAttr "Explain selected code" companion.setupOpts.prompt_library
  && !(builtins.hasAttr "stop_context_insertion" companion.setupOpts.prompt_library."Review selected code".opts)
  && !(builtins.hasAttr "stop_context_insertion" companion.setupOpts.prompt_library."Edit selected code".opts)
  && !(builtins.hasAttr "stop_context_insertion" companion.setupOpts.prompt_library."Generate tests for selected code".opts)
  && !(builtins.hasAttr "stop_context_insertion" companion.setupOpts.prompt_library."Explain selected code".opts)
  && hasMapping "<leader>ac" "<cmd>CodeCompanionChat<cr>" "n"
  && noNormalActionPaletteMapping
  && hasMappingPrefix "<leader>aA" "CodeCompanionActions" "x"
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
    && grep -Fq "Visual \`<leader>aA\`" docs/neovim-ide.md \
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
assert(config.display.action_palette.opts.show_preset_actions == false, 'preset actions should be hidden from action palette')
assert(config.display.action_palette.opts.show_preset_prompts == false, 'preset prompts should be hidden from action palette')
assert(config.display.action_palette.opts.show_preset_rules == false, 'preset rules should be hidden from action palette')
assert(config.display.action_palette.opts.show_prompt_library_builtins ~= false, 'curated prompt library entries must not be hidden')

local chat_rules = config.rules and config.rules.opts and config.rules.opts.chat or {}
assert(chat_rules.enabled == false, 'rules chat autoload must be disabled via enabled=false')
assert(chat_rules.autoload == false, 'rules chat autoload must be false: ' .. vim.inspect(chat_rules.autoload))
assert(config.rules.opts.show_presets == false, 'preset rules should be hidden from rules picker')
local rules_callbacks = require('codecompanion.interactions.chat.rules.helpers').add_callbacks({})
assert(rules_callbacks == nil, 'rules helper unexpectedly injected default callbacks: ' .. vim.inspect(rules_callbacks))
for _, prompt in pairs(config.prompt_library or {}) do
  if type(prompt) == 'table' and prompt.opts and prompt.opts.short_name then
    assert(prompt.rules == 'none', 'curated prompt should explicitly opt out of rules: ' .. vim.inspect(prompt.opts.short_name))
  end
end

assert(vim.tbl_isempty(config.interactions.shared.editor_context), 'shared editor_context providers should be empty after NVF hardening: ' .. vim.inspect(config.interactions.shared.editor_context))
assert(vim.tbl_isempty(config.interactions.inline.editor_context), 'inline editor_context providers should be empty after NVF hardening: ' .. vim.inspect(config.interactions.inline.editor_context))
assert(config.opts.triggers.editor_context == nil, 'editor_context trigger should be nil after NVF hardening: ' .. vim.inspect(config.opts.triggers.editor_context))
assert(require('codecompanion.triggers').mappings.editor_context == nil, 'editor_context trigger mapping should be nil after NVF hardening')
assert(vim.tbl_isempty(require('codecompanion.providers.completion').editor_context('chat')), 'editor_context completions should be empty')
assert(vim.tbl_isempty(require('codecompanion.interactions.shared.editor_context').new('chat').editor_context), 'chat editor_context parser should have no providers')
assert(vim.tbl_isempty(require('codecompanion.interactions.shared.editor_context').new('cli').editor_context), 'cli editor_context parser should have no providers')

local action_context = { mode = 'v' }
local actions = require('codecompanion.actions')
actions.refresh_cache(action_context)
local action_items = actions.set_items(action_context)
local action_names = {}
for _, item in ipairs(action_items) do
  action_names[item.name] = true
end
for _, name in ipairs({ 'Review selected code', 'Edit selected code', 'Generate tests for selected code', 'Explain selected code' }) do
  assert(action_names[name], 'curated prompt missing from visual action palette: ' .. name .. '; got ' .. vim.inspect(vim.tbl_keys(action_names)))
end
for _, name in ipairs({ 'Chat', 'Code workflow', 'Commit message', 'Explain code', 'Inline prompt', 'Upgrade Tools' }) do
  assert(action_names[name] == nil, 'unwanted built-in action/prompt visible in action palette: ' .. name)
end
for _, name in ipairs({ 'Review selected code', 'Edit selected code', 'Generate tests for selected code', 'Explain selected code' }) do
  local prompt = config.prompt_library[name]
  assert(prompt.opts.stop_context_insertion ~= true, 'curated selected-code prompt suppresses visual selection insertion: ' .. name)
end

local selection_sentinel = 'NVF_PHASE7_SELECTED_TEXT_SENTINEL'
local source_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(source_buf, 0, -1, false, {
  'local selected_value = "' .. selection_sentinel .. '"',
})
vim.api.nvim_set_current_buf(source_buf)
vim.bo[source_buf].filetype = 'lua'
local visual_context = {
  mode = 'v',
  is_visual = true,
  bufnr = source_buf,
  winnr = vim.api.nvim_get_current_win(),
  filetype = 'lua',
  start_line = 1,
  end_line = 1,
  start_col = 0,
  end_col = 64,
  lines = { 'local selected_value = "' .. selection_sentinel .. '"' },
}
local function contains_sentinel(value)
  if type(value) == 'string' then
    return value:find(selection_sentinel, 1, true) ~= nil
  elseif type(value) == 'table' then
    for _, item in pairs(value) do
      if contains_sentinel(item) then
        return true
      end
    end
  end
  return false
end

local Interactions = require('codecompanion.interactions')
local Chat = require('codecompanion.interactions.chat')
local original_chat_submit = Chat.submit
local submitted_chat_lines
Chat.submit = function(chat)
  submitted_chat_lines = vim.api.nvim_buf_get_lines(chat.bufnr, 0, -1, false)
  return chat
end
local chat_ok, chat_err = pcall(function()
  Interactions.new({
    selected = vim.deepcopy(config.prompt_library['Review selected code']),
    buffer_context = visual_context,
  }):chat()
end)
Chat.submit = original_chat_submit
assert(chat_ok, 'selected-code chat prompt path failed: ' .. vim.inspect(chat_err))
assert(contains_sentinel(submitted_chat_lines), 'selected text did not reach auto-submitted chat prompt buffer: ' .. vim.inspect(submitted_chat_lines))

local Inline = require('codecompanion.interactions.inline')
local original_inline_submit = Inline.submit
local submitted_inline_payload
Inline.submit = function(_, payload)
  submitted_inline_payload = payload
  return payload
end
local inline_ok, inline_err = pcall(function()
  Interactions.new({
    selected = vim.deepcopy(config.prompt_library['Edit selected code']),
    buffer_context = visual_context,
  }):inline()
end)
Inline.submit = original_inline_submit
assert(inline_ok, 'selected-code inline prompt path failed: ' .. vim.inspect(inline_err))
assert(contains_sentinel(submitted_inline_payload), 'selected text did not reach inline edit prompt payload: ' .. vim.inspect(submitted_inline_payload))

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
check 'built terminalman NVF package resolves CodeCompanion adapter and disables default context/tools at runtime' assert_phase7_runtime_codecompanion_config
check 'operations guide documents CodeCompanion decision, privacy, Codex CLI, and Pi boundaries' assert_phase7_docs_cover_boundaries
check 'Phase 7 evidence file is indexed and records the plugin decision' assert_phase7_evidence_documented
check 'NVF-031 ticket files and index consistently mark completed work done' assert_phase7_ticket_status_done

if ((failures > 0)); then
  exit 1
fi
