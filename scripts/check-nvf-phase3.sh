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

assert_phase3_testing_module_exists() {
  [[ -f home/modules/nvf/testing.nix ]]
}

assert_phase3_import_order() {
  local default_nix="home/modules/nvf/default.nix"
  local infra_line testing_line completion_line

  infra_line="$(grep -n '^[[:space:]]*./languages-infra\.nix$' "$default_nix" | cut -d: -f1)"
  testing_line="$(grep -n '^[[:space:]]*./testing\.nix$' "$default_nix" | cut -d: -f1)"
  completion_line="$(grep -n '^[[:space:]]*./completion\.nix$' "$default_nix" | cut -d: -f1)"

  [[ -n "$infra_line" && -n "$testing_line" && -n "$completion_line" ]] || return 1
  (( infra_line < testing_line && testing_line < completion_line ))
}

assert_terminalman_phase3_testing_debugging() {
  local expr result
  expr=$(cat <<'NIX'
let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  vim = flake.homeConfigurations.terminalman.config.programs.nvf.settings.vim;
  keymaps = vim.keymaps or [];
  extraPlugins = vim.extraPlugins or {};
  neotestConfig = extraPlugins.neotest.setup or "";
  has = name: set: builtins.hasAttr name set;
  hasNormalMode = mode: if builtins.isList mode then builtins.elem "n" mode else mode == "n";
  hasMapping = key: action: desc:
    builtins.any
      (mapping:
        mapping.key == key
        && mapping.action == action
        && mapping.desc == desc
        && hasNormalMode mapping.mode)
      keymaps;
  hasText = needle: builtins.length (builtins.split needle neotestConfig) > 1;
in
if
  vim.debugger.nvim-dap.enable
  && vim.debugger.nvim-dap.ui.enable
  && vim.debugger.nvim-dap.ui.autoStart
  && has "neotest" extraPlugins
  && has "neotest-python" extraPlugins
  && has "neotest-jest" extraPlugins
  && has "neotest-vitest" extraPlugins
  && hasText "neotest-python"
  && hasText "neotest-jest"
  && hasText "neotest-vitest"
  && hasMapping "<leader>tn" "<cmd>lua require('neotest').run.run()<cr>" "Test nearest"
  && hasMapping "<leader>tf" "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<cr>" "Test file"
  && hasMapping "<leader>ta" "<cmd>lua require('neotest').run.run(vim.uv.cwd())<cr>" "Test suite"
  && hasMapping "<leader>tr" "<cmd>lua require('neotest').run.run_last()<cr>" "Test last failed"
  && hasMapping "<leader>to" "<cmd>lua require('neotest').output.open({ enter = true, auto_close = true })<cr>" "Test output"
  && hasMapping "<leader>ts" "<cmd>lua require('neotest').summary.toggle()<cr>" "Test summary"
  && hasMapping "<leader>tw" "<cmd>lua require('neotest').watch.toggle(vim.fn.expand('%'))<cr>" "Test watch file"
  && hasMapping "<leader>tD" "<cmd>lua require('neotest').run.run({ strategy = 'dap' })<cr>" "Debug nearest test"
  && hasMapping "<leader>dc" "require('dap').continue" "Continue"
  && hasMapping "<leader>dR" "require('dap').restart" "Restart"
  && hasMapping "<leader>dq" "require('dap').terminate" "Terminate"
  && hasMapping "<leader>dr" "require('dap').repl.toggle" "Toggle Repl"
  && hasMapping "<leader>db" "require('dap').toggle_breakpoint" "Toggle breakpoint"
  && hasMapping "<leader>dgi" "require('dap').step_into" "Step into function"
  && hasMapping "<leader>dgo" "require('dap').step_out" "Step out of function"
  && hasMapping "<leader>dgj" "require('dap').step_over" "Next step"
  && hasMapping "<leader>dgk" "require('dap').step_back" "Step back"
  && hasMapping "<leader>dp" "<cmd>lua require('dap').pause()<cr>" "Debug pause"
  && hasMapping "<leader>dB" "<cmd>lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>" "Debug conditional breakpoint"
  && hasMapping "<leader>dx" "<cmd>lua require('dap').clear_breakpoints()<cr>" "Debug clear breakpoints"
  && hasMapping "<leader>ds" "<cmd>lua require('dap.ui.widgets').centered_float(require('dap.ui.widgets').scopes)<cr>" "Debug scopes"
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

assert_tidal_uses_localleader_for_t_mappings() {
  ! grep -q '"<leader>t' home/modules/nvf/tidal.nix \
    && grep -q '"<localleader>tl"' home/modules/nvf/tidal.nix \
    && grep -q '"<localleader>tb"' home/modules/nvf/tidal.nix \
    && grep -q '"<localleader>tn"' home/modules/nvf/tidal.nix
}

assert_phase3_evidence_exists() {
  [[ -f docs/test/evidence/nvf-phase3-testing-debugging-2026-05-31.md ]] \
    && grep -q 'NVF Phase 3 Testing and Debugging Evidence' docs/test/evidence/README.md
}

assert_phase3_ticket_statuses_done() {
  local ticket
  for ticket in NVF-014 NVF-029 NVF-015 NVF-016 NVF-017; do
    grep -q '^status: done$' "docs/tickets/${ticket}.md" || return 1
    grep -F "| [${ticket}](${ticket}.md) " docs/tickets/index.md \
      | grep -F '| done | NVF Phase 3 |' >/dev/null || return 1
  done
}

check 'Phase 3 testing module exists' assert_phase3_testing_module_exists
check 'Phase 3 testing module is imported after infra languages and before completion' assert_phase3_import_order
check 'terminalman enables shared DAP UI, Neotest plugins/adapters, and test/debug keymaps' assert_terminalman_phase3_testing_debugging
check 'Tidal live-coding mappings no longer own leader-t chords' assert_tidal_uses_localleader_for_t_mappings
check 'Phase 3 evidence file exists and is linked from the evidence index' assert_phase3_evidence_exists
check 'Phase 3 ticket files and index consistently mark completed work done' assert_phase3_ticket_statuses_done

if ((failures > 0)); then
  exit 1
fi
