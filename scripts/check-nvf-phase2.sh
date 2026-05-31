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

assert_phase2_module_files_exist() {
  local module
  for module in \
    home/modules/nvf/languages-python.nix \
    home/modules/nvf/languages-web.nix \
    home/modules/nvf/languages-infra.nix
  do
    [[ -f "$module" ]] || return 1
  done
}

assert_phase2_import_order() {
  local default_nix="home/modules/nvf/default.nix"
  local languages_line python_line web_line infra_line completion_line

  languages_line="$(grep -n '^[[:space:]]*./languages\.nix$' "$default_nix" | cut -d: -f1)"
  python_line="$(grep -n '^[[:space:]]*./languages-python\.nix$' "$default_nix" | cut -d: -f1)"
  web_line="$(grep -n '^[[:space:]]*./languages-web\.nix$' "$default_nix" | cut -d: -f1)"
  infra_line="$(grep -n '^[[:space:]]*./languages-infra\.nix$' "$default_nix" | cut -d: -f1)"
  completion_line="$(grep -n '^[[:space:]]*./completion\.nix$' "$default_nix" | cut -d: -f1)"

  [[ -n "$languages_line" && -n "$python_line" && -n "$web_line" && -n "$infra_line" && -n "$completion_line" ]] || return 1
  (( languages_line < python_line && python_line < web_line && web_line < infra_line && infra_line < completion_line ))
}

assert_terminalman_phase2_languages() {
  local expr result
  expr=$(cat <<'NIX'
let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  vim = flake.homeConfigurations.terminalman.config.programs.nvf.settings.vim;
  languages = vim.languages;
  lintersByFt = vim.diagnostics.nvim-lint.linters_by_ft or {};
  linters = vim.diagnostics.nvim-lint.linters or {};
  dapSources = vim.debugger.nvim-dap.sources or {};
  has = name: set: builtins.hasAttr name set;
  isEnabled = path: path.enable or false;
in
if
  languages.python.enable
  && languages.python.lsp.servers == [ "basedpyright" "ruff" ]
  && languages.python.format.type == [ "ruff" ]
  && languages.python.dap.enable
  && languages.python.dap.debugger == "debugpy"
  && (lintersByFt.python or []) == [ "ruff" ]
  && has "ruff" linters
  && languages.ts.enable
  && languages.ts.lsp.servers == [ "ts_ls" ]
  && languages.ts.format.type == [ "prettierd" ]
  && languages.ts.extraDiagnostics.types == [ "eslint_d" ]
  && languages.json.enable
  && languages.json.lsp.servers == [ "jsonls" ]
  && languages.json.format.type == [ "jsonfmt" ]
  && has "js-debugger" dapSources
  && languages.terraform.enable
  && languages.terraform.lsp.servers == [ "tofuls-tf" ]
  && languages.terraform.format.type == [ "tofu-fmt" ]
  && languages.hcl.enable
  && languages.hcl.lsp.servers == [ "tofuls-hcl" ]
  && languages.yaml.enable
  && languages.yaml.lsp.servers == [ "yaml-language-server" ]
  && languages.bash.enable
  && languages.bash.lsp.servers == [ "bash-ls" ]
  && languages.bash.format.type == [ "shfmt" ]
  && languages.bash.extraDiagnostics.types == [ "shellcheck" ]
  && languages.toml.enable
  && languages.toml.lsp.servers == [ "taplo" ]
  && languages.toml.format.type == [ "taplo" ]
  && isEnabled vim.lsp.servers.dockerls
  && (lintersByFt.dockerfile or []) == [ "hadolint" ]
  && has "hadolint" linters
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

assert_phase2_docs_updated() {
  grep -q '`languages-python.nix`' README.md \
    && grep -q '`languages-web.nix`' README.md \
    && grep -q '`languages-infra.nix`' README.md \
    && grep -q 'Python with basedpyright' docs/neovim-ide.md \
    && grep -q 'JavaScript/TypeScript with `ts_ls`' docs/neovim-ide.md \
    && grep -q 'Terraform/OpenTofu' docs/neovim-ide.md \
    && grep -q 'NVF Phase 2 Enterprise Language Evidence' docs/test/evidence/README.md
}

check 'Phase 2 NVF module files exist' assert_phase2_module_files_exist
check 'Phase 2 NVF modules are imported immediately after languages.nix' assert_phase2_import_order
check 'terminalman enables Python, web, and infrastructure Phase 2 language ownership' assert_terminalman_phase2_languages
check 'README, operations guide, and evidence index document Phase 2 modules' assert_phase2_docs_updated

if ((failures > 0)); then
  exit 1
fi
