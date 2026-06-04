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

assert_phase4_hardening_module_exists() {
  [[ -f home/modules/nvf/hardening.nix ]]
}

assert_phase4_import_order() {
  local default_nix="home/modules/nvf/default.nix"
  local debugging_line hardening_line completion_line

  debugging_line="$(grep -n '^[[:space:]]*./debugging\.nix$' "$default_nix" | cut -d: -f1)"
  hardening_line="$(grep -n '^[[:space:]]*./hardening\.nix$' "$default_nix" | cut -d: -f1)"
  completion_line="$(grep -n '^[[:space:]]*./completion\.nix$' "$default_nix" | cut -d: -f1)"

  [[ -n "$debugging_line" && -n "$hardening_line" && -n "$completion_line" ]] || return 1
  (( debugging_line < hardening_line && hardening_line < completion_line ))
}

assert_terminalman_phase4_hardening() {
  local expr result
  expr=$(cat <<'NIX'
let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  vim = flake.homeConfigurations.terminalman.config.programs.nvf.settings.vim;
  keymaps = vim.keymaps or [];
  lua = vim.luaConfigRC.workspace-hardening.data or "";
  packages = vim.extraPackages or [];
  hasNormalMode = mode: if builtins.isList mode then builtins.elem "n" mode else mode == "n";
  hasMapping = key: action: desc:
    builtins.any
      (mapping:
        mapping.key == key
        && mapping.action == action
        && mapping.desc == desc
        && hasNormalMode mapping.mode)
      keymaps;
  hasText = needle: builtins.length (builtins.split needle lua) > 1;
in
if
  builtins.any (pkg: (pkg.pname or pkg.name or "") == "gitleaks") packages
  && vim.diagnostics.enable
  && vim.diagnostics.config.update_in_insert == false
  && vim.diagnostics.config.severity_sort == true
  && hasMapping "<leader>tS" "<cmd>NvfScanSecrets<cr>" "Task scan secrets"
  && hasText "root_markers"
  && hasText "flake.nix"
  && hasText "package.json"
  && hasText "pyproject.toml"
  && hasText "vim.opt.exrc = false"
  && hasText "vim.opt.modeline = false"
  && hasText "NvfWorkspaceRoot"
  && hasText "NvfWorkspacePolicy"
  && hasText "NvfScanSecrets"
  && hasText "gitleaks"
  && hasText "vim.diagnostic.enable, false"
  && hasText "vim.treesitter.stop"
  && hasText "vim.lsp.buf_detach_client"
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

assert_phase4_docs_updated() {
  grep -q '`hardening.nix`' README.md \
    && grep -q 'Workspace hardening' docs/neovim-ide.md \
    && grep -q ':NvfWorkspaceRoot' docs/neovim-ide.md \
    && grep -q ':NvfScanSecrets' docs/neovim-ide.md \
    && grep -q 'nvim --startuptime' docs/neovim-ide.md \
    && grep -q 'NVF Phase 4 Workspace Hardening Evidence' docs/test/evidence/README.md
}

assert_phase4_ticket_statuses_done() {
  local ticket
  for ticket in NVF-018 NVF-019 NVF-020; do
    grep -q '^status: done$' "docs/tickets/${ticket}.md" || return 1
    grep -F "| [${ticket}](${ticket}.md) " docs/tickets/index.md \
      | grep -F '| done | NVF Phase 4 |' >/dev/null || return 1
  done
}

check 'Phase 4 hardening module exists' assert_phase4_hardening_module_exists
check 'Phase 4 hardening module is imported after debugging and before completion' assert_phase4_import_order
check 'terminalman enables workspace hardening, throttled diagnostics, gitleaks, and explicit task mapping' assert_terminalman_phase4_hardening
check 'README, operations guide, and evidence index document Phase 4 hardening' assert_phase4_docs_updated
check 'Phase 4 ticket files and index consistently mark completed work done' assert_phase4_ticket_statuses_done

if ((failures > 0)); then
  exit 1
fi
