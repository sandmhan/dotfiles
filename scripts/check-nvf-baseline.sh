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

nix_eval_json() {
  nix eval --json --no-write-lock-file "$@"
}

nix_eval_raw() {
  nix eval --raw --no-write-lock-file "$@"
}

assert_nix_lsp_owner() {
  local nixd nil
  nixd="$(nix_eval_json .#homeConfigurations.terminalman.config.programs.nvf.settings.vim.lsp.servers.nixd.enable)"
  nil="$(nix_eval_json .#homeConfigurations.terminalman.config.programs.nvf.settings.vim.lsp.servers.nil_ls.enable)"

  [[ "$nixd" == "true" && "$nil" == "false" ]]
}

assert_lsp_keymaps() {
  local expr result
  expr=$(cat <<'NIX'
let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  keymaps = flake.homeConfigurations.terminalman.config.programs.nvf.settings.vim.keymaps;
  hasMapping = key: action: desc:
    builtins.any
      (mapping:
        mapping.key == key
        && mapping.action == action
        && mapping.desc == desc
        && builtins.elem "n" mapping.mode)
      keymaps;
in
if
  hasMapping "<leader>lh" "<cmd>lua vim.lsp.buf.hover()<cr>" "LSP hover"
  && hasMapping "<leader>lR" "<cmd>lua vim.lsp.buf.rename()<cr>" "LSP rename"
  && hasMapping "<leader>li" "<cmd>lua vim.lsp.buf.implementation()<cr>" "LSP implementation"
  && hasMapping "<leader>lt" "<cmd>lua vim.lsp.buf.type_definition()<cr>" "LSP type definition"
  && hasMapping "<leader>lk" "<cmd>lua vim.lsp.buf.signature_help()<cr>" "LSP signature help"
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

assert_neovim_guide_stub() {
  [[ -f docs/neovim-ide.md ]] \
    && grep -q 'nvf-enterprise-polyglot-ide-improvement-report.md' docs/neovim-ide.md \
    && grep -q 'Planned, not yet implemented' docs/neovim-ide.md
}

assert_readme_inventory() {
  local module
  for module in \
    default options keymaps visuals lsp languages testing completion treesitter utility \
    finder editing git notes tidal toggles ui
  do
    grep -q "\`${module}.nix\`" README.md || return 1
  done

  grep -q 'docs/neovim-ide.md' README.md
}

check 'Nix LSP uses nixd without nil_ls by default' assert_nix_lsp_owner
check 'LSP ergonomics keymaps use exact NVF Lua command actions' assert_lsp_keymaps
check 'Neovim IDE guide stub records Phase 0 decisions without overclaiming' assert_neovim_guide_stub
check 'README NVF inventory mirrors imported modules and links the IDE guide' assert_readme_inventory

if ((failures > 0)); then
  exit 1
fi
