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

assert_phase5_bridge_retired_from_active_nvf() {
  [[ ! -e home/modules/nvf/ai.nix ]] \
    && ! grep -q '^[[:space:]]*./ai\.nix$' home/modules/nvf/default.nix \
    && ! grep -R -q 'luaConfigRC\.ai-bridge\|NvfAiAsk\|NvfAiReviewDiff\|NvfAiTests\|NvfAiDiagnostic\|NvfAiSkills' home/modules/nvf
}

assert_phase5_terminalman_has_no_bridge_runtime_config() {
  local expr result
  expr=$(cat <<'NIX'
let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  vim = flake.homeConfigurations.terminalman.config.programs.nvf.settings.vim;
  keymaps = vim.keymaps or [];
  luaConfigRC = vim.luaConfigRC or {};
  contains = needle: text: builtins.length (builtins.split needle (toString text)) > 1;
in
if
  !(builtins.hasAttr "ai-bridge" luaConfigRC)
  && !(builtins.any
    (mapping:
      contains "NvfAi" (mapping.action or "")
      || contains "NvfAi" (mapping.desc or ""))
    keymaps)
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

assert_phase5_docs_mark_bridge_historical() {
  grep -q 'NVF Phase 5 AI Bridge Evidence' docs/test/evidence/README.md \
    && [[ -f docs/test/evidence/nvf-phase5-ai-bridge-2026-05-31.md ]] \
    && grep -q 'Avante.nvim, the prior `NvfAi\*` bridge commands' docs/neovim-ide.md \
    && grep -q 'Claude, Codex, and Pi remain standalone Home Manager tools outside Neovim' docs/neovim-ide.md
}

assert_phase5_ticket_statuses_done() {
  local ticket
  for ticket in NVF-021 NVF-022 NVF-023 NVF-024; do
    grep -q '^status: done$' "docs/tickets/${ticket}.md" || return 1
    grep -F "| [${ticket}](${ticket}.md) " docs/tickets/index.md \
      | grep -F '| done | NVF Phase 5 |' >/dev/null || return 1
  done
}

check 'Phase 5 guarded bridge module and NvfAi commands are retired from active NVF' assert_phase5_bridge_retired_from_active_nvf
check 'terminalman has no active ai-bridge luaConfigRC or NvfAi keymaps' assert_phase5_terminalman_has_no_bridge_runtime_config
check 'Phase 5 bridge evidence remains historical while current docs describe CodeCompanion-only AI' assert_phase5_docs_mark_bridge_historical
check 'Phase 5 ticket files and index consistently mark completed work done' assert_phase5_ticket_statuses_done

if ((failures > 0)); then
  exit 1
fi
