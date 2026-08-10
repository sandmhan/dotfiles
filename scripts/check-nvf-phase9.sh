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

assert_phase9_option_schema() {
  nix_bool_expr 'let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  hm = flake.inputs.home-manager.lib;
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  cfg = (hm.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      flake.homeManagerModules.sandvim
      {
        home = {
          username = "sandvim-phase9";
          homeDirectory = "/home/sandvim-phase9";
          stateVersion = "24.11";
        };
        news.display = "silent";
        programs.sandvim.enable = true;
      }
    ];
  }).config.programs.sandvim;
  leafValues = [
    cfg.packs.ai
    cfg.packs.debugging
    cfg.packs.notes
    cfg.packs.tidal
    cfg.packs.workflow
    cfg.packs.languages.general
    cfg.packs.languages.python
    cfg.packs.languages.web
    cfg.packs.languages.infrastructure
    cfg.packs.languages.systems
    cfg.packs.languages.dataMobile
    cfg.packs.languages.java
  ];
in
if cfg.preset == "standard" && builtins.all builtins.isBool leafValues then "true" else "false"' || return 1

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
        username = "sandvim-invalid";
        homeDirectory = "/home/sandvim-invalid";
        stateVersion = "24.11";
      };
      news.display = "silent";
      programs.sandvim = {
        enable = true;
        preset = "enterprise";
      };
    }
  ];
}).config.programs.sandvim.preset'
  invalid_expr="${invalid_expr//__REPO_ROOT__/$repo_root}"
  ! nix_eval_raw --impure --expr "$invalid_expr" >/dev/null 2>&1
}

assert_phase9_preset_truth_table() {
  nix_bool_expr 'let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  hm = flake.inputs.home-manager.lib;
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  mkCfg = preset: (hm.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      flake.homeManagerModules.sandvim
      {
        home = {
          username = "sandvim-${preset}";
          homeDirectory = "/home/sandvim-${preset}";
          stateVersion = "24.11";
        };
        news.display = "silent";
        programs.sandvim = {
          enable = true;
          inherit preset;
        };
      }
    ];
  }).config.programs.sandvim.packs;
  minimal = mkCfg "minimal";
  standard = mkCfg "standard";
  full = mkCfg "full";
  leaves = packs: [
    packs.ai
    packs.debugging
    packs.notes
    packs.tidal
    packs.workflow
    packs.languages.general
    packs.languages.python
    packs.languages.web
    packs.languages.infrastructure
    packs.languages.systems
    packs.languages.dataMobile
    packs.languages.java
  ];
in
if
  builtins.all (value: value == false) (leaves minimal)
  && builtins.all (value: value == true) [
    standard.ai
    standard.debugging
    standard.notes
    standard.tidal
    standard.workflow
    standard.languages.general
    standard.languages.python
    standard.languages.web
    standard.languages.infrastructure
    standard.languages.systems
    standard.languages.dataMobile
  ]
  && standard.languages.java == false
  && builtins.all (value: value == true) (leaves full)
then "true" else "false"'
}

assert_phase9_overrides_beat_presets() {
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
          username = "sandvim-override";
          homeDirectory = "/home/sandvim-override";
          stateVersion = "24.11";
        };
        news.display = "silent";
        programs.sandvim = { enable = true; } // sandvim;
      }
    ];
  }).config.programs.sandvim.packs;
  minimalWithPython = mkCfg {
    preset = "minimal";
    packs.languages.python = true;
  };
  fullWithoutAiOrJava = mkCfg {
    preset = "full";
    packs.ai = false;
    packs.languages.java = false;
  };
in
if
  minimalWithPython.languages.python == true
  && minimalWithPython.languages.web == false
  && minimalWithPython.debugging == false
  && fullWithoutAiOrJava.ai == false
  && fullWithoutAiOrJava.languages.java == false
  && fullWithoutAiOrJava.languages.python == true
then "true" else "false"'
}

assert_phase9_import_inventory() {
  local default_nix="home/modules/nvf/default.nix"
  local data_mobile java debugging

  [[ -f home/modules/nvf/languages-java.nix ]] || return 1
  grep -q '`languages-java.nix`' README.md || return 1

  data_mobile="$(grep -n '^[[:space:]]*./languages-data-mobile\.nix$' "$default_nix" | cut -d: -f1)"
  java="$(grep -n '^[[:space:]]*./languages-java\.nix$' "$default_nix" | cut -d: -f1)"
  debugging="$(grep -n '^[[:space:]]*./debugging\.nix$' "$default_nix" | cut -d: -f1)"

  [[ -n "$data_mobile" && -n "$java" && -n "$debugging" ]] || return 1
  ((data_mobile < java && java < debugging))
}

assert_phase9_java_configuration() {
  nix_bool_expr 'let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  hm = flake.inputs.home-manager.lib;
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  mkVim = preset: (hm.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      flake.homeManagerModules.sandvim
      {
        home = {
          username = "sandvim-java-${preset}";
          homeDirectory = "/home/sandvim-java-${preset}";
          stateVersion = "24.11";
        };
        news.display = "silent";
        programs.sandvim = {
          enable = true;
          inherit preset;
        };
      }
    ];
  }).config.programs.nvf.settings.vim;
  standard = mkVim "standard";
  full = mkVim "full";
in
if
  ((standard.languages.java.enable or false) == false)
  && full.languages.java.enable
  && full.languages.java.treesitter.enable
  && full.languages.java.lsp.enable
  && full.languages.java.lsp.servers == [ "jdt-language-server" ]
  && full.languages.java.format.enable
  && full.languages.java.format.type == [ "astyle" ]
  && full.languages.java.dap.enable == false
then "true" else "false"'
}

assert_phase9_pack_lsp_modularity() {
  nix_bool_expr 'let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  hm = flake.inputs.home-manager.lib;
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  lib = flake.inputs.nixpkgs.lib;
  mkConfig = sandvim: (hm.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      flake.homeManagerModules.sandvim
      {
        home = {
          username = "sandvim-modularity";
          homeDirectory = "/home/sandvim-modularity";
          stateVersion = "24.11";
        };
        news.display = "silent";
        programs.sandvim = { enable = true; } // sandvim;
      }
    ];
  }).config;
  pythonOnly = mkConfig {
    preset = "minimal";
    packs.languages.python = true;
  };
  javaOnly = mkConfig {
    preset = "minimal";
    packs.languages.java = true;
  };
  tidalOnly = mkConfig {
    preset = "minimal";
    packs.tidal = true;
  };
  pythonVim = pythonOnly.programs.nvf.settings.vim;
  javaVim = javaOnly.programs.nvf.settings.vim;
  tidalVim = tidalOnly.programs.nvf.settings.vim;
  pythonServers = pythonVim.lsp.servers or {};
  javaServers = javaVim.lsp.servers or {};
  packageNames = config:
    map (package: package.pname or package.name or "") ((config.programs.nvf.settings.vim.extraPackages or []) ++ (config.home.packages or []));
  lacksPackage = names: needle: !(builtins.any (name: lib.hasInfix needle name) names);
  hasKey = vim: key: builtins.any (mapping: mapping.key == key) (vim.keymaps or []);
in
if
  pythonVim.lsp.enable
  && pythonVim.languages.python.enable
  && ((pythonVim.languages.markdown.enable or false) == false)
  && ((pythonVim.languages.nix.enable or false) == false)
  && ((pythonVim.languages.typst.enable or false) == false)
  && ((pythonVim.languages.clang.enable or false) == false)
  && ((pythonServers.clangd.enable or false) == false)
  && ((pythonServers.nixd.enable or false) == false)
  && ((pythonServers.tinymist.enable or false) == false)
  && ((pythonServers.markdown-oxide.enable or false) == false)
  && ((pythonVim.lsp.presets.harper.enable or false) == false)
  && lacksPackage (packageNames pythonOnly) "clang"
  && lacksPackage (packageNames pythonOnly) "nixd"
  && lacksPackage (packageNames pythonOnly) "tinymist"
  && lacksPackage (packageNames pythonOnly) "markdown-oxide"
  && lacksPackage (packageNames pythonOnly) "harper"
  && javaVim.lsp.enable
  && javaVim.languages.java.enable
  && javaVim.languages.java.lsp.servers == [ "jdt-language-server" ]
  && builtins.any (name: lib.hasInfix "astyle" name) (packageNames javaOnly)
  && ((javaVim.languages.markdown.enable or false) == false)
  && ((javaVim.languages.nix.enable or false) == false)
  && ((javaVim.languages.typst.enable or false) == false)
  && ((javaVim.languages.clang.enable or false) == false)
  && ((javaServers.clangd.enable or false) == false)
  && ((javaServers.nixd.enable or false) == false)
  && ((javaServers.tinymist.enable or false) == false)
  && ((javaServers.markdown-oxide.enable or false) == false)
  && ((javaVim.lsp.presets.harper.enable or false) == false)
  && lacksPackage (packageNames javaOnly) "harper"
  && tidalVim.lsp.enable
  && tidalVim.languages.haskell.enable
  && tidalVim.languages.haskell.lsp.enable
  && hasKey tidalVim "<leader>lr"
then "true" else "false"'
}

assert_phase9_notes_require_general_language_pack() {
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
        username = "sandvim-invalid-notes";
        homeDirectory = "/home/sandvim-invalid-notes";
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
  if nix_eval_raw --impure --expr "$invalid_expr" >/dev/null 2>&1; then
    return 1
  fi

  nix_bool_expr 'let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  hm = flake.inputs.home-manager.lib;
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  cfg = (hm.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      flake.homeManagerModules.sandvim
      {
        home = {
          username = "sandvim-disabled-notes";
          homeDirectory = "/home/sandvim-disabled-notes";
          stateVersion = "24.11";
        };
        news.display = "silent";
        programs.sandvim = {
          enable = false;
          preset = "minimal";
          packs.notes = true;
        };
      }
    ];
  }).config.programs.sandvim;
in
if cfg.packs.notes && cfg.packs.languages.general == false then "true" else "false"'
}

assert_phase9_minimal_gates_optional_features() {
  nix_bool_expr 'let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  hm = flake.inputs.home-manager.lib;
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  vim = (hm.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      flake.homeManagerModules.sandvim
      {
        home = {
          username = "sandvim-minimal-gates";
          homeDirectory = "/home/sandvim-minimal-gates";
          stateVersion = "24.11";
        };
        news.display = "silent";
        programs.sandvim = {
          enable = true;
          preset = "minimal";
        };
      }
    ];
  }).config.programs.nvf.settings.vim;
  keymaps = vim.keymaps or [];
  hasKey = key: builtins.any (mapping: mapping.key == key) keymaps;
in
if
  vim.viAlias
  && vim.vimAlias
  && ((vim.lsp.enable or false) == false)
  && ((vim.languages.markdown.enable or false) == false)
  && ((vim.languages.python.enable or false) == false)
  && ((vim.languages.typescript.enable or false) == false)
  && ((vim.languages.terraform.enable or false) == false)
  && ((vim.languages.rust.enable or false) == false)
  && ((vim.languages.sql.enable or false) == false)
  && ((vim.languages.java.enable or false) == false)
  && ((vim.assistant.codecompanion-nvim.enable or false) == false)
  && ((vim.debugger.nvim-dap.enable or false) == false)
  && ((vim.notes.obsidian.enable or false) == false)
  && ((vim.lsp.trouble.enable or false) == false)
  && ((vim.utility.preview.markdownPreview.enable or false) == false)
  && ((vim.utility.nix-develop.enable or false) == false)
  && !(hasKey "<leader>cp")
  && !(hasKey "<leader>uc")
  && !(hasKey "<leader>uh")
  && !(hasKey "<leader>lr")
  && !(hasKey "<leader>ac")
  && !(hasKey "<leader>dp")
  && !(hasKey "<leader>nn")
then "true" else "false"'
}

assert_phase9_language_and_debugging_dap_gates() {
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
          username = "sandvim-dap-gates";
          homeDirectory = "/home/sandvim-dap-gates";
          stateVersion = "24.11";
        };
        news.display = "silent";
        programs.sandvim = { enable = true; } // sandvim;
      }
    ];
  }).config.programs.nvf.settings.vim;
  pythonOnly = mkVim {
    preset = "minimal";
    packs.languages.python = true;
  };
  pythonDebug = mkVim {
    preset = "minimal";
    packs.languages.python = true;
    packs.debugging = true;
  };
  generalOnly = mkVim {
    preset = "minimal";
    packs.languages.general = true;
  };
  webOnly = mkVim {
    preset = "minimal";
    packs.languages.web = true;
  };
in
if
  pythonOnly.languages.python.enable
  && pythonOnly.languages.python.dap.enable == false
  && pythonDebug.languages.python.dap.enable == true
  && generalOnly.languages.clang.enable
  && generalOnly.languages.clang.dap.enable == false
  && webOnly.languages.typescript.enable
  && ((webOnly.debugger.nvim-dap.enable or false) == false)
then "true" else "false"'
}

assert_phase9_local_adapter_full() {
  nix_bool_expr 'let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  terminal = flake.homeConfigurations.terminalman.config;
  smoke = (flake.inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = [
      flake.homeManagerModules.sandvim
      {
        home = {
          username = "sandvim-smoke-default";
          homeDirectory = "/home/sandvim-smoke-default";
          stateVersion = "24.11";
        };
        news.display = "silent";
        programs.sandvim.enable = true;
      }
    ];
  }).config;
in
if
  terminal.programs.sandvim.preset == "full"
  && terminal.programs.sandvim.packs.languages.java
  && terminal.programs.nvf.settings.vim.languages.java.enable
  && smoke.programs.sandvim.preset == "standard"
  && smoke.programs.sandvim.packs.languages.java == false
  && ((smoke.programs.nvf.settings.vim.languages.java.enable or false) == false)
then "true" else "false"'
}

assert_phase9_no_duplicate_keymaps() {
  nix_bool_expr 'let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  keymaps = flake.homeConfigurations.terminalman.config.programs.nvf.settings.vim.keymaps;
  modes = mode: if builtins.isList mode then mode else [ mode ];
  labels = builtins.concatMap (mapping: map (mode: builtins.toJSON [ mode mapping.key ]) (modes mapping.mode)) keymaps;
  count = label: builtins.length (builtins.filter (candidate: candidate == label) labels);
  checkedLabels = map (key: builtins.toJSON [ "n" key ]) [
    "<leader>cp"
    "<leader>lr"
    "<leader>ld"
    "<leader>ls"
    "<leader>lw"
    "<leader>lci"
    "<leader>lco"
    "<leader>la"
    "<leader>lh"
    "<leader>lR"
    "<leader>li"
    "<leader>lt"
    "<leader>xx"
    "<leader>uc"
    "<leader>uh"
    "<leader>ac"
    "<leader>dp"
    "<leader>dB"
    "<leader>dx"
    "<leader>ds"
    "<leader>nn"
    "<leader>no"
    "<leader>nq"
    "<leader>ns"
    "<leader>nb"
    "<leader>nl"
    "<leader>nf"
    "<leader>nt"
    "<leader>nr"
    "<leader>sr"
    "<leader>sR"
    "<leader>gd"
    "<leader>gD"
    "<leader>gh"
    "<leader>gH"
    "<leader>gt"
  ];
in
if builtins.all (label: count label <= 1) checkedLabels then "true" else "false"'
}

assert_phase9_flake_exports() {
  nix_bool_expr 'let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  checks = flake.checks.x86_64-linux;
  packages = flake.packages.x86_64-linux;
  darwinPackages = flake.packages.aarch64-darwin;
in
if
  builtins.hasAttr "sandvimExternalConsumer" checks
  && builtins.hasAttr "sandvimMinimalConsumer" checks
  && builtins.hasAttr "sandvimMinimalRuntime" checks
  && builtins.hasAttr "sandvimJavaRuntime" checks
  && builtins.hasAttr "sandvimStartupProfile" checks
  && builtins.hasAttr "sandvimMinimal" packages
  && builtins.hasAttr "sandvimStandard" packages
  && builtins.hasAttr "sandvimFull" packages
  && builtins.hasAttr "sandvimMinimal" darwinPackages
  && builtins.hasAttr "sandvimStandard" darwinPackages
  && builtins.hasAttr "sandvimFull" darwinPackages
  && darwinPackages.sandvimMinimal.drvPath != ""
  && darwinPackages.sandvimStandard.drvPath != ""
  && darwinPackages.sandvimFull.drvPath != ""
then "true" else "false"'
}

assert_phase9_no_nested_nix_in_runcommands() {
  awk "
    /runCommand/ { in_runcommand = 1 }
    in_runcommand && /(^|[^[:alnum:]_-])nix([[:space:]]|$)/ { bad = 1 }
    in_runcommand && /^[[:space:]]*'';[[:space:]]*$/ { in_runcommand = 0 }
    END { exit bad }
  " flake.nix
}

assert_phase9_runtime_harnesses_exist() {
  [[ -f scripts/check-nvf-minimal-runtime.lua ]] \
    && [[ -f scripts/check-nvf-java-runtime.lua ]] \
    && grep -q 'NVF_MINIMAL_RUNTIME_OK' scripts/check-nvf-minimal-runtime.lua \
    && grep -q 'NVF_JAVA_RUNTIME_OK' scripts/check-nvf-java-runtime.lua \
    && grep -q "grep -Fq 'NVF_MINIMAL_RUNTIME_OK'" flake.nix \
    && grep -q "grep -Fq 'NVF_JAVA_RUNTIME_OK'" flake.nix \
    && grep -q 'astyle' scripts/check-nvf-java-runtime.lua \
    && grep -q 'documentSymbol' scripts/check-nvf-java-runtime.lua
}

assert_phase9_profiler_script_static() {
  bash -n scripts/profile-nvf.sh \
    && scripts/profile-nvf.sh --help | grep -q 'minimal|standard|full|all' \
    && grep -q -- '--startuptime' scripts/profile-nvf.sh \
    && grep -q 'nix path-info -Sh' scripts/profile-nvf.sh \
    && grep -q 'nix build' scripts/profile-nvf.sh \
    && grep -q 'if (!seen) exit 1' scripts/profile-nvf.sh \
    && grep -q 'timeout 120s' flake.nix
}

assert_phase9_docs_sync() {
  ! grep -q 'public Sandvim API intentionally stays limited to that single option' README.md \
    && ! grep -q 'included whenever Sandvim is enabled' README.md \
    && grep -q 'programs.sandvim.preset = "standard"' README.md \
    && grep -q 'packages.<system>.sandvimMinimal' README.md \
    && grep -q 'scripts/profile-nvf.sh minimal|standard|full|all' README.md \
    && grep -q 'sandvimStartupProfile' README.md \
    && grep -q '| `minimal` | Off | Off | Off | Off | Off | Off | Off | Off | Off | Off | Off | Off |' docs/neovim-ide.md \
    && grep -q 'notes` requires `programs.sandvim.packs.languages.general' docs/neovim-ide.md \
    && grep -q 'Java DAP remains off' docs/neovim-ide.md \
    && grep -q 'jdt-language-server' docs/neovim-ide.md \
    && grep -q 'do not call nested `nix` commands' docs/neovim-ide.md \
    && grep -q '1000 ms for `minimal` and 2000 ms for `full`' docs/neovim-ide.md \
    && grep -q '304.9 MiB' docs/neovim-ide.md \
    && [[ -f docs/test/evidence/nvf-feature-packs-java-runtime-2026-08-09.md ]] \
    && grep -q 'NVF Feature Packs, Java Runtime, and Profiling Evidence' docs/test/evidence/README.md \
    && grep -q 'status: accepted' docs/test/evidence/nvf-feature-packs-java-runtime-2026-08-09.md \
    && grep -q 'No activation or deployment was performed' docs/test/evidence/nvf-feature-packs-java-runtime-2026-08-09.md
}

check 'Phase 9 Sandvim option schema exposes preset enum and pack leaves' assert_phase9_option_schema
check 'Phase 9 preset truth table matches minimal, standard, and full' assert_phase9_preset_truth_table
check 'Phase 9 explicit pack overrides beat preset defaults' assert_phase9_overrides_beat_presets
check 'Phase 9 Java module exists, is imported statically, and README inventory is synchronized' assert_phase9_import_inventory
check 'Phase 9 Java support uses jdt-language-server, AStyle formatting, Treesitter, and no DAP' assert_phase9_java_configuration
check 'Phase 9 Python-only and Java-only packs do not leak general LSP servers or packages' assert_phase9_pack_lsp_modularity
check 'Phase 9 notes pack asserts that the general language pack is enabled' assert_phase9_notes_require_general_language_pack
check 'Phase 9 minimal preset gates optional modules and dead commands' assert_phase9_minimal_gates_optional_features
check 'Phase 9 language DAP integrations require both language and debugging packs' assert_phase9_language_and_debugging_dap_gates
check 'Phase 9 dotfiles adapter defaults local Sandvim users to full while external consumers stay standard' assert_phase9_local_adapter_full
check 'Phase 9 terminalman keymaps have no duplicate key/mode pairs' assert_phase9_no_duplicate_keymaps
check 'Phase 9 flake exports reusable Sandvim packages and runtime checks' assert_phase9_flake_exports
check 'Phase 9 runCommand runtime/profile checks do not call nested nix' assert_phase9_no_nested_nix_in_runcommands
check 'Phase 9 runtime Lua harnesses are tracked and cover minimal and Java behavior' assert_phase9_runtime_harnesses_exist
check 'Phase 9 developer profiler has help, syntax, closure, and startuptime support' assert_phase9_profiler_script_static
check 'Phase 9 README, operations guide, and evidence index document feature packs and runtime checks' assert_phase9_docs_sync

if ((failures > 0)); then
  exit 1
fi
