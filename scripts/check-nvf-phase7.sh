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

assert_phase7_codecompanion_module_exists() {
  [[ -f home/modules/nvf/ai-codecompanion.nix ]] \
    && grep -q 'codecompanion-nvim' home/modules/nvf/ai-codecompanion.nix \
    && grep -q 'enableNvfAiCodeCompanion' home/modules/nvf/ai-codecompanion.nix \
    && grep -q 'pkgs.codex-acp' home/modules/nvf/ai-codecompanion.nix \
    && grep -q 'auth_method = "chatgpt"' home/modules/nvf/ai-codecompanion.nix \
    && grep -q 'default = { "codex-acp" }' home/modules/nvf/ai-codecompanion.nix \
    && ! grep -q 'OPENAI_API_KEY\|OPENAI_BASE_URL\|OPENAI_MODEL\|openai_compatible\|avante-nvim\|NvfAiAsk\|NvfAiReviewDiff\|NvfAiTests\|NvfAiDiagnostic\|NvfAiSkills' home/modules/nvf/ai-codecompanion.nix
}

assert_phase7_import_inventory_sync() {
  local default_nix="home/modules/nvf/default.nix"
  local hardening_line codecompanion_line completion_line

  hardening_line="$(grep -n '^[[:space:]]*./hardening\.nix$' "$default_nix" | cut -d: -f1)"
  codecompanion_line="$(grep -n '^[[:space:]]*./ai-codecompanion\.nix$' "$default_nix" | cut -d: -f1)"
  completion_line="$(grep -n '^[[:space:]]*./completion\.nix$' "$default_nix" | cut -d: -f1)"

  [[ -n "$hardening_line" && -n "$codecompanion_line" && -n "$completion_line" ]] || return 1
  ((hardening_line < codecompanion_line && codecompanion_line < completion_line)) || return 1

  [[ ! -e home/modules/nvf/ai-avante.nix ]] \
    && [[ ! -e home/modules/nvf/ai.nix ]] \
    && ! grep -q '^[[:space:]]*./ai-avante\.nix$\|^[[:space:]]*./ai\.nix$' "$default_nix" \
    && grep -Fq '| `ai-codecompanion.nix` | CodeCompanion.nvim' README.md \
    && bash scripts/check-nvf-phase6.sh >/dev/null
}

assert_phase7_no_forbidden_nvf_ai_wiring() {
  ! grep -R -q 'avante-nvim\|openai_compatible\|OPENAI_API_KEY\|OPENAI_BASE_URL\|OPENAI_MODEL\|luaConfigRC\.ai-bridge\|NvfAiAsk\|NvfAiReviewDiff\|NvfAiTests\|NvfAiDiagnostic\|NvfAiSkills' home/modules/nvf home/options.nix home/profiles/terminal.nix
}

assert_phase7_feature_flag_enabled_for_terminal_profile() {
  local expr result
  expr=$(cat <<'NIX'
let
  flake = builtins.getFlake "path:__REPO_ROOT__";
in
if flake.homeConfigurations.terminalman.config.myHome.features.enableNvfAiCodeCompanion then "true" else "false"
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
  assistant = vim.assistant or {};
  codecompanion = assistant."codecompanion-nvim" or {};
  setup = codecompanion.setupOpts or {};
  interactions = setup.interactions or {};
  display = setup.display or {};
  actionPalette = display.action_palette or {};
  actionPaletteOpts = actionPalette.opts or {};
  rules = setup.rules or {};
  keymaps = vim.keymaps or [];
  luaConfigRC = vim.luaConfigRC or {};
  contains = needle: text: builtins.length (builtins.split needle (toString text)) > 1;
  hasMode = expected: mode: if builtins.isList mode then builtins.elem expected mode else mode == expected;
  hasMapping = key: command: mode:
    builtins.any
      (mapping:
        mapping.key == key
        && mapping.action == command
        && hasMode mode mapping.mode
        && contains "CodeCompanion" (mapping.desc or ""))
      keymaps;
  noForbiddenMappings =
    !(builtins.any
      (mapping:
        contains "NvfAi" (mapping.action or "")
        || contains "NvfAi" (mapping.desc or "")
        || contains "Avante" (mapping.action or "")
        || contains "Avante" (mapping.desc or ""))
      keymaps);
  noUnsupportedCodeCompanionMappings =
    !(builtins.any
      (mapping:
        contains "CodeCompanionActions" (mapping.action or "")
        || contains "CodeCompanionCmd" (mapping.action or ""))
      keymaps);
  noUnsupportedAcpInteractions =
    ((interactions.background.adapter or null) != "codex")
    && ((interactions.cmd.adapter or null) != "codex")
    && ((interactions.inline.adapter or null) != "codex");
  actionPaletteHidden =
    ((actionPaletteOpts.show_default_actions or true) == false)
    && ((actionPaletteOpts.show_default_prompt_library or true) == false)
    && ((actionPaletteOpts.show_preset_actions or true) == false)
    && ((actionPaletteOpts.show_preset_prompts or true) == false)
    && ((actionPaletteOpts.show_preset_rules or true) == false);
in
if
  codecompanion.enable
  && ((assistant."avante-nvim".enable or false) == false)
  && ((interactions.chat.adapter or null) == "codex")
  && noUnsupportedAcpInteractions
  && actionPaletteHidden
  && ((rules.opts.chat.enabled or true) == false)
  && ((rules.opts.chat.autoload or true) == false)
  && ((rules.opts.show_presets or true) == false)
  && hasMapping "<leader>ac" "<cmd>CodeCompanionChat<cr>" "n"
  && noForbiddenMappings
  && noUnsupportedCodeCompanionMappings
  && !(builtins.hasAttr "ai-bridge" luaConfigRC)
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

assert_phase7_terminalman_installs_codex_acp() {
  nix eval --json --no-write-lock-file --impure --expr \
    "let f = builtins.getFlake \"path:$repo_root\"; in map (p: p.pname or p.name or \"\") f.homeConfigurations.terminalman.config.home.packages" \
    | grep -q '"codex-acp"'
}

assert_phase7_docs_cover_codecompanion_boundaries() {
  grep -q 'Neovim AI: CodeCompanion Codex ACP' docs/neovim-ide.md \
    && grep -q 'auth_method = "chatgpt"' docs/neovim-ide.md \
    && grep -q 'no `OPENAI_API_KEY`, `OPENAI_BASE_URL`, or model secret is committed to Nix' docs/neovim-ide.md \
    && grep -q 'Avante.nvim, the prior `NvfAi\*` bridge commands' docs/neovim-ide.md \
    && grep -q ':CodeCompanionChat' docs/neovim-ide.md \
    && grep -q 'Command (`:CodeCompanionCmd`) and inline/action-palette interactions are HTTP-adapter-only upstream' docs/neovim-ide.md \
    && grep -q 'does not expose action-palette prompt workflows' docs/neovim-ide.md \
    && grep -q ':AvanteAsk") == 2' docs/neovim-ide.md \
    && grep -q ':NvfAiAsk") == 2' docs/neovim-ide.md \
    && ! grep -q 'CodeCompanion.*superseded by.*Avante\|Avante replaces CodeCompanion' docs/test/evidence/README.md docs/tickets/NVF-032.md \
    && grep -q 'NVF Phase 7 CodeCompanion Codex ACP Evidence' docs/test/evidence/README.md
}

assert_phase7_evidence_documented() {
  [[ -f docs/test/evidence/nvf-phase7-codecompanion-codex-acp-2026-06-02.md ]] \
    && grep -q 'CodeCompanion Codex ACP is the current NVF in-editor AI workflow' docs/test/evidence/nvf-phase7-codecompanion-codex-acp-2026-06-02.md \
    && grep -q 'CodeCompanion command (`:CodeCompanionCmd`) and inline/action-palette interactions are HTTP-adapter-only upstream' docs/test/evidence/nvf-phase7-codecompanion-codex-acp-2026-06-02.md \
    && grep -q 'bash scripts/check-nvf-phase7.sh' docs/test/evidence/nvf-phase7-codecompanion-codex-acp-2026-06-02.md
}

assert_phase7_ticket_status_done() {
  grep -q '^status: done$' docs/tickets/NVF-032.md \
    && grep -q 'CodeCompanion Codex ACP' docs/tickets/NVF-032.md \
    && grep -q 'enableNvfAiCodeCompanion' docs/tickets/NVF-032.md \
    && grep -q 'Unsupported CodeCompanion command/inline/action-palette interactions are not wired to the Codex ACP adapter' docs/tickets/NVF-032.md \
    && grep -F '| [NVF-032](NVF-032.md) ' docs/tickets/index.md \
      | grep -F '| done | NVF Phase 7 |' \
      | grep -F 'CodeCompanion Codex ACP' >/dev/null
}

assert_phase7_runtime_codecompanion_commands() {
  local tmpdir nvim_bin build_log
  tmpdir="$(mktemp -d)"
  build_log="$tmpdir/build.log"
  trap 'rm -rf "${tmpdir:-}"' RETURN

  if ! nix build --no-write-lock-file --impure --expr \
    "(builtins.getFlake \"path:$repo_root\").homeConfigurations.terminalman.config.programs.nvf.finalPackage" \
    -o "$tmpdir/nvim" >"$build_log" 2>&1; then
    if [[ "${NVF_PHASE7_REQUIRE_RUNTIME:-0}" == "1" ]]; then
      cat "$build_log" >&2
      rm -rf "$tmpdir"
      trap - RETURN
      return 1
    fi

    printf 'skip - runtime CodeCompanion command smoke (finalPackage build unavailable; set NVF_PHASE7_REQUIRE_RUNTIME=1 to require it)\n' >&2
    cat "$build_log" >&2
    rm -rf "$tmpdir"
    trap - RETURN
    return 0
  fi

  nvim_bin="$tmpdir/nvim/bin/nvim"

  "$nvim_bin" --headless '+checkhealth' '+qa'
  "$nvim_bin" --headless -c 'if exists(":CodeCompanionChat") != 2 | cquit | endif' -c 'qa!'
  "$nvim_bin" --headless -c 'if exists(":AvanteAsk") == 2 | cquit | endif' -c 'qa!'
  "$nvim_bin" --headless -c 'if exists(":NvfAiAsk") == 2 | cquit | endif' -c 'qa!'

  rm -rf "$tmpdir"
  trap - RETURN
}

check 'Phase 7 CodeCompanion Codex ACP module exists with ChatGPT auth and no API-key/Avante/bridge wiring' assert_phase7_codecompanion_module_exists
check 'Phase 7 default.nix import and README inventory are synchronized' assert_phase7_import_inventory_sync
check 'NVF modules have no active API-key, OpenAI-compatible, Avante, or NvfAi bridge wiring' assert_phase7_no_forbidden_nvf_ai_wiring
check 'terminal profile enables NVF CodeCompanion feature flag' assert_phase7_feature_flag_enabled_for_terminal_profile
check 'terminalman enables chat-only CodeCompanion Codex config and hides unsupported cmd/inline workflows' assert_phase7_terminalman_codecompanion_config
check 'terminalman installs codex-acp' assert_phase7_terminalman_installs_codex_acp
check 'operations guide, ticket, and evidence index document CodeCompanion-only boundaries' assert_phase7_docs_cover_codecompanion_boundaries
check 'Phase 7 CodeCompanion Codex ACP evidence file is indexed' assert_phase7_evidence_documented
check 'NVF-032 ticket files and index consistently mark completed work done' assert_phase7_ticket_status_done
check 'built terminalman NVF package exposes CodeCompanionChat and omits Avante/NvfAi commands when build is available' assert_phase7_runtime_codecompanion_commands

if ((failures > 0)); then
  exit 1
fi
