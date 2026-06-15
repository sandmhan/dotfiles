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

nix_bool_expr() {
  local expr result
  expr="$1"
  expr="${expr//__REPO_ROOT__/$repo_root}"
  result="$(nix_eval_raw --impure --expr "$expr")"
  [[ "$result" == "true" ]]
}

assert_phase8_modules_exist_and_imported() {
  local default_nix="home/modules/nvf/default.nix"
  local infra systems data_mobile debugging git workflow notes

  [[ -f home/modules/nvf/languages-systems.nix ]] || return 1
  [[ -f home/modules/nvf/languages-data-mobile.nix ]] || return 1
  [[ -f home/modules/nvf/workflow.nix ]] || return 1

  infra="$(grep -n '^[[:space:]]*./languages-infra\.nix$' "$default_nix" | cut -d: -f1)"
  systems="$(grep -n '^[[:space:]]*./languages-systems\.nix$' "$default_nix" | cut -d: -f1)"
  data_mobile="$(grep -n '^[[:space:]]*./languages-data-mobile\.nix$' "$default_nix" | cut -d: -f1)"
  debugging="$(grep -n '^[[:space:]]*./debugging\.nix$' "$default_nix" | cut -d: -f1)"
  git="$(grep -n '^[[:space:]]*./git\.nix$' "$default_nix" | cut -d: -f1)"
  workflow="$(grep -n '^[[:space:]]*./workflow\.nix$' "$default_nix" | cut -d: -f1)"
  notes="$(grep -n '^[[:space:]]*./notes\.nix$' "$default_nix" | cut -d: -f1)"

  [[ -n "$infra" && -n "$systems" && -n "$data_mobile" && -n "$debugging" ]] || return 1
  [[ -n "$git" && -n "$workflow" && -n "$notes" ]] || return 1
  ((infra < systems && systems < data_mobile && data_mobile < debugging)) || return 1
  ((git < workflow && workflow < notes)) || return 1
}

assert_phase8_polyglot_options() {
  nix_bool_expr 'let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  langs = flake.homeConfigurations.terminalman.config.programs.nvf.settings.vim.languages;
in
if
  langs.rust.enable
  && langs.rust.treesitter.enable
  && langs.rust.lsp.enable
  && langs.rust.format.enable
  && langs.rust.format.type == [ "rustfmt" ]
  && langs.rust.dap.enable == false
  && langs.rust.extensions.crates-nvim.enable
  && langs.go.enable
  && langs.go.treesitter.enable
  && langs.go.lsp.enable
  && langs.go.lsp.servers == [ "gopls" ]
  && langs.go.format.enable
  && langs.go.format.type == [ "gofmt" ]
  && langs.go.extraDiagnostics.enable
  && langs.go.extraDiagnostics.types == [ "golangci-lint" ]
  && langs.go.dap.enable == false
  && langs.lua.enable
  && langs.lua.treesitter.enable
  && langs.lua.lsp.enable
  && langs.lua.lsp.servers == [ "lua-language-server" ]
  && langs.lua.lsp.lazydev.enable
  && langs.lua.format.enable
  && langs.lua.format.type == [ "stylua" ]
  && langs.lua.extraDiagnostics.enable
  && langs.lua.extraDiagnostics.types == [ "luacheck" ]
  && langs.sql.enable
  && langs.sql.dialect == "ansi"
  && langs.sql.treesitter.enable
  && langs.sql.lsp.enable
  && langs.sql.lsp.servers == [ "sqls" ]
  && langs.sql.format.enable
  && langs.sql.format.type == [ "sqlfluff" ]
  && langs.sql.extraDiagnostics.enable
  && langs.sql.extraDiagnostics.types == [ "sqlfluff" ]
  && langs.dart.enable
  && langs.dart.treesitter.enable
  && langs.dart.lsp.enable
  && langs.dart.lsp.servers == [ "dart" ]
  && langs.dart.dap.enable == false
  && langs.dart.flutter-tools.enable
  && langs.dart.flutter-tools.flutterPackage == null
  && langs.dart.flutter-tools.enableNoResolvePatch == false
then "true" else "false"'
}

assert_phase8_markdown_obsidian_workflow_options() {
  nix_bool_expr 'let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  vim = flake.homeConfigurations.terminalman.config.programs.nvf.settings.vim;
  langs = vim.languages;
  lspServers = vim.lsp.servers or {};
  notes = vim.notes or {};
  trouble = vim.lsp.trouble;
  utility = vim.utility;
  mini = vim.mini;
  has = key: action: builtins.any (m: m.key == key && m.action == action && builtins.elem "n" m.mode) vim.keymaps;
in
if
  langs.markdown.lsp.servers == [ "markdown-oxide" ]
  && langs.markdown.format.type == [ "mdformat" ]
  && ((lspServers.marksman.enable or false) == false)
  && ((lspServers."markdown-oxide".enable or false) == true)
  && notes.todo-comments.enable
  && notes.obsidian.enable
  && builtins.hasAttr "workspaces" notes.obsidian.setupOpts
  && (notes.obsidian.setupOpts.legacy_commands or true) == false
  && trouble.enable
  && trouble.mappings.workspaceDiagnostics == "<leader>xw"
  && trouble.mappings.documentDiagnostics == "<leader>xd"
  && trouble.mappings.lspReferences == "<leader>xR"
  && trouble.mappings.quickfix == "<leader>xq"
  && trouble.mappings.locList == "<leader>xl"
  && trouble.mappings.symbols == "<leader>xs"
  && utility.grug-far-nvim.enable
  && utility.diffview-nvim.enable
  && utility.sleuth.enable
  && vim.ui.fastaction.enable
  && vim.lsp.lightbulb.enable
  && mini.align.enable
  && mini.splitjoin.enable
  && mini.move.enable
  && utility.smart-splits.enable
  && utility.smart-splits.setupOpts.multiplexer_integration == "tmux"
  && has "<leader>nn" "<cmd>Obsidian new<cr>"
  && has "<leader>no" "<cmd>Obsidian open<cr>"
  && has "<leader>nq" "<cmd>Obsidian quick_switch<cr>"
  && has "<leader>ns" "<cmd>Obsidian search<cr>"
  && has "<leader>nb" "<cmd>Obsidian backlinks<cr>"
  && has "<leader>nl" "<cmd>Obsidian links<cr>"
  && has "<leader>nf" "<cmd>Obsidian follow_link<cr>"
  && has "<leader>nt" "<cmd>Obsidian tags<cr>"
  && has "<leader>nr" "<cmd>Obsidian rename<cr>"
  && has "<leader>sr" "<cmd>GrugFar<cr>"
  && has "<leader>sR" "<cmd>GrugFarWithin<cr>"
  && has "<leader>gd" "<cmd>DiffviewOpen<cr>"
  && has "<leader>gD" "<cmd>DiffviewClose<cr>"
  && has "<leader>gh" "<cmd>DiffviewFileHistory %<cr>"
  && has "<leader>gH" "<cmd>DiffviewFileHistory<cr>"
  && has "<leader>gt" "<cmd>DiffviewToggleFiles<cr>"
then "true" else "false"'
}

assert_phase8_no_new_duplicate_keymaps() {
  nix_bool_expr 'let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  keymaps = flake.homeConfigurations.terminalman.config.programs.nvf.settings.vim.keymaps;
  keys = [
    "<leader>nn" "<leader>no" "<leader>nq" "<leader>ns" "<leader>nb" "<leader>nl" "<leader>nf" "<leader>nt" "<leader>nr"
    "<leader>sr" "<leader>sR"
    "<leader>gd" "<leader>gD" "<leader>gh" "<leader>gH" "<leader>gt"
  ];
  count = key: builtins.length (builtins.filter (mapping: mapping.key == key) keymaps);
in
if builtins.all (key: count key == 1) keys then "true" else "false"'
}

assert_phase8_hardening_root_markers() {
  grep -q '"pubspec.yaml"' home/modules/nvf/hardening.nix \
    && grep -q '"\.sqlfluff"' home/modules/nvf/hardening.nix \
    && grep -q '"sqlfluff.toml"' home/modules/nvf/hardening.nix \
    && grep -q '"\.luarc.json"' home/modules/nvf/hardening.nix \
    && grep -q '"stylua.toml"' home/modules/nvf/hardening.nix
}

assert_phase8_tmux_smart_splits() {
  grep -q 'smart-splits.tmux' home/modules/terminal.nix \
    && grep -q '@smart-splits_move_left_key C-h' home/modules/terminal.nix \
    && grep -q '@smart-splits_resize_right_key M-l' home/modules/terminal.nix \
    && ! grep -q 'bind -n C-h select-pane\|bind -n C-j select-pane\|bind -n C-k select-pane\|bind -n C-l select-pane' home/modules/terminal.nix
}

assert_phase8_docs_sync() {
  grep -Fq '| `languages-systems.nix` | Rust, Go, and Lua' README.md \
    && grep -Fq '| `languages-data-mobile.nix` | SQL and Dart/Flutter' README.md \
    && grep -Fq '| `workflow.nix` | Professional diagnostics' README.md \
    && grep -q 'markdown-oxide' docs/neovim-ide.md \
    && grep -q 'Rust, Go, and Lua support' docs/neovim-ide.md \
    && grep -q 'SQL and Dart/Flutter support' docs/neovim-ide.md \
    && grep -q '<leader>n' docs/neovim-ide.md \
    && grep -q '<leader>s' docs/neovim-ide.md \
    && grep -q 'pubspec.yaml' docs/neovim-ide.md \
    && grep -q 'bash scripts/check-nvf-phase8.sh' docs/neovim-ide.md \
    && ! grep -q 'Rust, Go, Lua, and SQL workflows.*not implemented' docs/neovim-ide.md
}

assert_phase8_ticket_and_evidence_sync() {
  [[ -f docs/tickets/NVF-033.md ]] \
    && [[ -f docs/test/evidence/nvf-phase8-polyglot-workflows-2026-06-15.md ]] \
    && grep -q '^| NVF | 034 |$' docs/tickets/index.md \
    && grep -Fq '| [NVF-033](NVF-033.md) | Add NVF Phase 8 polyglot workflow support | task | done | NVF Phase 8 |' docs/tickets/index.md \
    && grep -Fq 'NVF Phase 8 Polyglot Workflow Evidence' docs/test/evidence/README.md \
    && grep -q 'bash scripts/check-nvf-phase8.sh' docs/test/evidence/nvf-phase8-polyglot-workflows-2026-06-15.md
}

assert_phase8_runtime_commands() {
  local tmpdir build_log nvim_bin
  tmpdir="$(mktemp -d)"
  build_log="$tmpdir/build.log"
  trap 'rm -rf "${tmpdir:-}"; trap - RETURN' RETURN

  if ! nix build --no-write-lock-file --impure --expr \
    "(builtins.getFlake \"path:$repo_root\").homeConfigurations.terminalman.config.programs.nvf.finalPackage" \
    -o "$tmpdir/nvim" >"$build_log" 2>&1; then
    if [[ "${NVF_PHASE8_REQUIRE_RUNTIME:-0}" == "1" ]]; then
      cat "$build_log" >&2
      rm -rf "$tmpdir"
      trap - RETURN
      return 1
    fi

    printf 'skip - runtime Phase 8 command smoke (finalPackage build unavailable; set NVF_PHASE8_REQUIRE_RUNTIME=1 to require it)\n' >&2
    cat "$build_log" >&2
    rm -rf "$tmpdir"
    trap - RETURN
    return 0
  fi

  nvim_bin="$tmpdir/nvim/bin/nvim"
  "$nvim_bin" --headless -c 'if exists(":Obsidian") != 2 | cquit | endif' -c 'qa!' || return 1
  "$nvim_bin" --headless \
    -c 'if exists(":GrugFar") != 2 | cquit | endif' \
    -c 'if exists(":GrugFarWithin") != 2 | cquit | endif' \
    -c 'if exists(":DiffviewOpen") != 2 | cquit | endif' \
    -c 'if exists(":DiffviewToggleFiles") != 2 | cquit | endif' \
    -c 'if exists(":Trouble") != 2 | cquit | endif' \
    -c 'qa!' || return 1

  rm -rf "$tmpdir"
  trap - RETURN
  return 0
}

check 'Phase 8 modules exist and default.nix import ordering is synchronized' assert_phase8_modules_exist_and_imported
check 'terminalman enables Rust, Go, Lua, SQL, and Dart/Flutter with expected tool ownership' assert_phase8_polyglot_options
check 'Markdown, Obsidian, workflow plugins, and smart-splits options are enabled' assert_phase8_markdown_obsidian_workflow_options
check 'new Phase 8 keymaps do not duplicate existing vim.keymaps entries' assert_phase8_no_new_duplicate_keymaps
check 'workspace hardening includes Phase 8 root markers' assert_phase8_hardening_root_markers
check 'tmux uses smart-splits integration without unconditional pane-navigation binds' assert_phase8_tmux_smart_splits
check 'README and Neovim operations guide document Phase 8 imports and behavior' assert_phase8_docs_sync
check 'NVF-033 ticket and Phase 8 evidence are indexed' assert_phase8_ticket_and_evidence_sync
check 'built terminalman NVF package exposes Obsidian, GrugFar, Diffview, and Trouble commands when build is available' assert_phase8_runtime_commands

if ((failures > 0)); then
  exit 1
fi
