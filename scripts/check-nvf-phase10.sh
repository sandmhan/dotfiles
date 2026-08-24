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

assert_phase10_pack_schema_defaults_and_notes_gate() {
  nix_bool_expr 'let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  hm = flake.inputs.home-manager.lib;
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  mkCfg = sandvim: (hm.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      flake.homeManagerModules.sandvim
      {
        home = {
          username = "sandvim-phase10";
          homeDirectory = "/home/sandvim-phase10";
          stateVersion = "24.11";
        };
        news.display = "silent";
        programs.sandvim = { enable = true; } // sandvim;
      }
    ];
  }).config.programs.sandvim;
  minimal = (mkCfg { preset = "minimal"; }).packs;
  standard = (mkCfg { preset = "standard"; }).packs;
  full = (mkCfg { preset = "full"; }).packs;
  legacy = (mkCfg { preset = "minimal"; packs.languages.general = true; }).packs;
  legacyOverrides = (mkCfg {
    preset = "minimal";
    packs.languages.general = true;
    packs.languages.documentation = false;
    packs.languages.nix = false;
  }).packs;
  notes = mkCfg {
    preset = "minimal";
    packs.notes = true;
    packs.languages.documentation = true;
  };
in
if
  minimal.languages.general == false
  && minimal.languages.documentation == false
  && minimal.languages.nix == false
  && standard.languages.general == false
  && standard.languages.documentation == true
  && standard.languages.nix == true
  && standard.languages.systems == true
  && full.languages.general == false
  && full.languages.documentation == true
  && full.languages.nix == true
  && full.languages.systems == true
  && legacy.languages.general == true
  && legacy.languages.documentation == true
  && legacy.languages.nix == true
  && legacyOverrides.languages.general == true
  && legacyOverrides.languages.documentation == false
  && legacyOverrides.languages.nix == false
  && notes.notes.attachmentsFolder == "attachments"
  && notes.notes.templatesFolder == "templates"
then "true" else "false"' || return 1

  local invalid_expr
  invalid_expr='let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  hm = flake.inputs.home-manager.lib;
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
in
(hm.homeManagerConfiguration {
  inherit pkgs;
  modules = [
    flake.homeManagerModules.sandvim
    {
      home = {
        username = "sandvim-invalid-notes-doc";
        homeDirectory = "/home/sandvim-invalid-notes-doc";
        stateVersion = "24.11";
      };
      news.display = "silent";
      programs.sandvim = {
        enable = true;
        preset = "minimal";
        packs.notes = true;
      };
    }
  ];
}).config.programs.sandvim.packs.notes'
  invalid_expr="${invalid_expr//__REPO_ROOT__/$repo_root}"
  ! nix_eval_raw --impure --expr "$invalid_expr" >/dev/null 2>&1
}

assert_phase10_module_ownership_boundaries() {
  local default_nix="home/modules/nvf/default.nix"
  local documentation nix_pack python systems

  [[ -f home/modules/nvf/documentation.nix ]] || return 1
  [[ -f home/modules/nvf/languages-nix.nix ]] || return 1
  [[ ! -e home/modules/nvf/languages.nix ]] || return 1

  documentation="$(grep -n '^[[:space:]]*./documentation\.nix$' "$default_nix" | cut -d: -f1)"
  nix_pack="$(grep -n '^[[:space:]]*./languages-nix\.nix$' "$default_nix" | cut -d: -f1)"
  python="$(grep -n '^[[:space:]]*./languages-python\.nix$' "$default_nix" | cut -d: -f1)"
  systems="$(grep -n '^[[:space:]]*./languages-systems\.nix$' "$default_nix" | cut -d: -f1)"
  [[ -n "$documentation" && -n "$nix_pack" && -n "$python" && -n "$systems" ]] || return 1
  ((documentation < nix_pack && nix_pack < python && python < systems)) || return 1

  nix_bool_expr 'let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  hm = flake.inputs.home-manager.lib;
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  mkVim = sandvim: (hm.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      flake.homeManagerModules.sandvim
      {
        home = {
          username = "sandvim-ownership";
          homeDirectory = "/home/sandvim-ownership";
          stateVersion = "24.11";
        };
        news.display = "silent";
        programs.sandvim = { enable = true; } // sandvim;
      }
    ];
  }).config.programs.nvf.settings.vim;
  doc = mkVim { preset = "minimal"; packs.languages.documentation = true; };
  nixOnly = mkVim { preset = "minimal"; packs.languages.nix = true; };
  systemsOnly = mkVim { preset = "minimal"; packs.languages.systems = true; };
  legacy = mkVim { preset = "minimal"; packs.languages.general = true; };
in
if
  doc.languages.markdown.enable
  && doc.languages.typst.enable
  && ((doc.languages.nix.enable or false) == false)
  && ((doc.languages.clang.enable or false) == false)
  && nixOnly.languages.nix.enable
  && ((nixOnly.languages.markdown.enable or false) == false)
  && ((nixOnly.languages.typst.enable or false) == false)
  && ((nixOnly.languages.clang.enable or false) == false)
  && systemsOnly.languages.clang.enable
  && systemsOnly.languages.clang.format.enable
  && systemsOnly.languages.rust.enable
  && systemsOnly.languages.go.enable
  && systemsOnly.languages.lua.enable
  && legacy.languages.markdown.enable
  && legacy.languages.nix.enable
  && legacy.languages.typst.enable
  && legacy.languages.clang.enable
  && ((legacy.languages.rust.enable or false) == false)
  && ((legacy.languages.go.enable or false) == false)
  && ((legacy.languages.lua.enable or false) == false)
then "true" else "false"'
}

assert_phase10_markdown_and_lsp_semantics() {
  nix_bool_expr 'let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  vim = flake.homeConfigurations.terminalman.config.programs.nvf.settings.vim;
  langs = vim.languages;
  lspServers = vim.lsp.servers or {};
  markdownlint = vim.diagnostics.nvim-lint.linters."markdownlint-cli2";
in
if
  langs.markdown.enable
  && langs.markdown.treesitter.enable
  && langs.markdown.format.enable
  && langs.markdown.format.type == [ "mdformat" ]
  && langs.markdown.extraDiagnostics.enable
  && langs.markdown.extraDiagnostics.types == [ "markdownlint-cli2" ]
  && builtins.elem "--config" markdownlint.args
  && builtins.any (arg: builtins.match ".*sandvim-markdownlint-cli2\\.yaml" arg != null) markdownlint.args
  && builtins.elem "-" markdownlint.args
  && langs.markdown.lsp.enable
  && langs.markdown.lsp.servers == [ "markdown-oxide" ]
  && ((lspServers.marksman.enable or false) == false)
  && ((lspServers."markdown-oxide".enable or false) == true)
  && vim.lsp.presets.harper.enable
  && langs.markdown.extensions.render-markdown-nvim.enable
  && langs.markdown.extensions.render-markdown-nvim.setupOpts.completions.blink.enabled == true
  && langs.typst.enable
  && langs.typst.lsp.servers == [ "tinymist" ]
  && builtins.any (mapping: mapping.key == "<leader>cp" && mapping.action == "<cmd>MarkdownPreview<cr>") vim.keymaps
then "true" else "false"' || return 1

  grep -q 'markdownlint-cli2 owns structural lint' home/modules/nvf/documentation.nix \
    && grep -q 'Harper owns prose' home/modules/nvf/documentation.nix \
    && grep -q 'markdown-oxide owns document/link LSP' home/modules/nvf/documentation.nix \
    && grep -q 'front_matter_title: ""' home/modules/nvf/documentation.nix \
    && grep -q 'obsidian-ls owns note-aware completion/navigation' home/modules/nvf/notes.nix \
    && ! grep -Eq 'prettier|remark|vale|marksman|markview' home/modules/nvf/documentation.nix
}

assert_phase10_notes_paths_keymaps_and_paste_packages() {
  nix_bool_expr 'let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  lib = flake.inputs.nixpkgs.lib;
  linux = flake.homeConfigurations.terminalman.config;
  mkDarwin = (flake.inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = flake.inputs.nixpkgs.legacyPackages.aarch64-darwin;
    modules = [
      flake.homeManagerModules.sandvim
      {
        home = {
          username = "sandvim-darwin-notes";
          homeDirectory = "/Users/sandvim-darwin-notes";
          stateVersion = "24.11";
        };
        news.display = "silent";
        programs.sandvim = {
          enable = true;
          preset = "minimal";
          packs.notes = true;
          packs.languages.documentation = true;
        };
      }
    ];
  }).config;
  vim = linux.programs.nvf.settings.vim;
  obsidian = vim.notes.obsidian.setupOpts;
  has = key: action: builtins.any (m: m.key == key && m.action == action && builtins.elem "n" m.mode) vim.keymaps;
  extraPackageNames = config: map (package: package.pname or package.name or "") (config.programs.nvf.settings.vim.extraPackages or []);
  linuxPackages = extraPackageNames linux;
  darwinPackages = extraPackageNames mkDarwin;
in
if
  vim.notes.obsidian.enable
  && obsidian.legacy_commands == false
  && obsidian.attachments.folder == linux.programs.sandvim.notes.attachmentsFolder
  && obsidian.templates.folder == linux.programs.sandvim.notes.templatesFolder
  && has "<leader>np" "<cmd>Obsidian paste_img<cr>"
  && has "<leader>nx" "<cmd>Obsidian toggle_checkbox<cr>"
  && has "<leader>nT" "<cmd>Obsidian template<cr>"
  && builtins.any (name: lib.hasInfix "xclip" name) linuxPackages
  && builtins.any (name: lib.hasInfix "pngpaste" name) darwinPackages
then "true" else "false"'
}

assert_phase10_flake_runtime_assets() {
  [[ -f tests/fixtures/markdown-obsidian-runtime.md ]] || return 1
  [[ -f scripts/check-nvf-markdown-runtime.lua ]] || return 1
  grep -q 'NVF_MARKDOWN_RUNTIME_OK' scripts/check-nvf-markdown-runtime.lua || return 1
  grep -q 'lint\.linters\["markdownlint-cli2"\]' scripts/check-nvf-markdown-runtime.lua || return 1
  grep -q 'lint\.try_lint("markdownlint-cli2")' scripts/check-nvf-markdown-runtime.lua || return 1
  grep -q 'require_executable("xclip")' scripts/check-nvf-markdown-runtime.lua || return 1
  grep -q 'require_executable("wl-paste")' scripts/check-nvf-markdown-runtime.lua || return 1
  grep -q 'harper = false' scripts/check-nvf-markdown-runtime.lua || return 1
  grep -q '"markdown-oxide"' scripts/check-nvf-markdown-runtime.lua || return 1
  grep -q '"obsidian-ls"' scripts/check-nvf-markdown-runtime.lua || return 1
  ! grep -q 'vim\.lsp\.start' scripts/check-nvf-markdown-runtime.lua || return 1
  grep -q 'workspace="/tmp/sandvim-markdown-runtime-workspace"' flake.nix || return 1
  grep -q '"$workspace/\.obsidian"' flake.nix || return 1
  grep -q "grep -Fq 'nvim-navic: Failed to attach'" flake.nix || return 1
  ! grep -q 'extraPackages' home/modules/nvf/documentation.nix || return 1
  grep -q 'sandvim-phase10-sentinel' tests/fixtures/markdown-obsidian-runtime.md || return 1
  grep -q '\[\[Second Brain\]\]' tests/fixtures/markdown-obsidian-runtime.md || return 1
  grep -q '!\[\[diagram.png\]\]' tests/fixtures/markdown-obsidian-runtime.md || return 1
  grep -q '^```mermaid' tests/fixtures/markdown-obsidian-runtime.md || return 1

  nix_bool_expr 'let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  checks = flake.checks.x86_64-linux;
in
if builtins.hasAttr "sandvimMarkdownRuntime" checks && checks.sandvimMarkdownRuntime.drvPath != "" then "true" else "false"'
}

assert_phase10_docs_and_evidence_sync() {
  grep -Fq '| `documentation.nix` | Markdown, Typst, prose diagnostics, markdown preview/rendering, and documentation language tooling |' README.md \
    && grep -Fq '| `languages-nix.nix` | Nix IDE ownership with nixd, nixfmt, Treesitter, and extra diagnostics |' README.md \
    && ! grep -Fq '| `languages.nix` |' README.md \
    && grep -q 'programs.sandvim.packs.languages.documentation' docs/neovim-ide.md \
    && grep -q 'programs.sandvim.notes.attachmentsFolder' docs/neovim-ide.md \
    && grep -q 'sandvimMarkdownRuntime' docs/neovim-ide.md \
    && grep -q 'bash scripts/check-nvf-phase10.sh' docs/neovim-ide.md \
    && grep -q 'frontmatter `title` and one Markdown H1' docs/neovim-ide.md \
    && [[ -f docs/test/evidence/nvf-markdown-obsidian-runtime-2026-08-09.md ]] \
    && grep -q 'NVF Markdown and Obsidian Runtime Evidence' docs/test/evidence/README.md \
    && grep -q 'No activation, deployment, or push was performed' docs/test/evidence/nvf-markdown-obsidian-runtime-2026-08-09.md
}

check 'Phase 10 pack schema adds documentation/nix leaves, keeps general compatibility, and gates notes on documentation' assert_phase10_pack_schema_defaults_and_notes_gate
check 'Phase 10 documentation, nix, systems, and legacy general ownership boundaries are explicit' assert_phase10_module_ownership_boundaries
check 'Phase 10 Markdown diagnostics, LSP, render-markdown Blink completion, and Typst semantics are explicit' assert_phase10_markdown_and_lsp_semantics
check 'Phase 10 Obsidian paths, keymaps, and platform paste dependencies are configured' assert_phase10_notes_paths_keymaps_and_paste_packages
check 'Phase 10 flake-native Markdown runtime check assets are tracked and exported' assert_phase10_flake_runtime_assets
check 'Phase 10 README, operations guide, and evidence index document Markdown/Obsidian refinements' assert_phase10_docs_and_evidence_sync

if ((failures > 0)); then
  exit 1
fi
