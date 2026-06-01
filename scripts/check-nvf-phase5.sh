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

assert_phase5_ai_module_exists() {
  [[ -f home/modules/nvf/ai.nix ]]
}

assert_phase5_import_order() {
  local default_nix="home/modules/nvf/default.nix"
  local hardening_line ai_line completion_line

  hardening_line="$(grep -n '^[[:space:]]*./hardening\.nix$' "$default_nix" | cut -d: -f1)"
  ai_line="$(grep -n '^[[:space:]]*./ai\.nix$' "$default_nix" | cut -d: -f1)"
  completion_line="$(grep -n '^[[:space:]]*./completion\.nix$' "$default_nix" | cut -d: -f1)"

  [[ -n "$hardening_line" && -n "$ai_line" && -n "$completion_line" ]] || return 1
  (( hardening_line < ai_line && ai_line < completion_line ))
}

assert_terminalman_phase5_ai_bridge() {
  local expr result
  expr=$(cat <<'NIX'
let
  flake = builtins.getFlake "path:__REPO_ROOT__";
  vim = flake.homeConfigurations.terminalman.config.programs.nvf.settings.vim;
  keymaps = vim.keymaps or [];
  bridge = vim.luaConfigRC.ai-bridge or {};
  lua = bridge.data or "";
  hasNormalMode = mode: if builtins.isList mode then builtins.elem "n" mode else mode == "n";
  hasVisualMode = mode: if builtins.isList mode then builtins.elem "x" mode else mode == "x";
  hasNormalMapping = key: command:
    builtins.any
      (mapping:
        mapping.key == key
        && mapping.action == command
        && hasNormalMode mapping.mode
        && builtins.length (builtins.split "AI" mapping.desc) > 1)
      keymaps;
  hasVisualMapping = key: command:
    builtins.any
      (mapping:
        mapping.key == key
        && mapping.action == command
        && hasVisualMode mapping.mode
        && builtins.length (builtins.split "guarded provider" mapping.desc) > 1)
      keymaps;
  hasText = needle: builtins.length (builtins.split needle lua) > 1;
in
if
  builtins.elem "workspace-hardening" (bridge.after or [])
  && hasNormalMapping "<leader>aa" "<cmd>NvfAiAsk<cr>"
  && hasVisualMapping "<leader>aa" ":'<,'>NvfAiAsk<cr>"
  && hasNormalMapping "<leader>ar" "<cmd>NvfAiReviewDiff<cr>"
  && hasNormalMapping "<leader>at" "<cmd>NvfAiTests<cr>"
  && hasVisualMapping "<leader>at" ":'<,'>NvfAiTests<cr>"
  && hasNormalMapping "<leader>ad" "<cmd>NvfAiDiagnostic<cr>"
  && hasNormalMapping "<leader>as" "<cmd>NvfAiSkills<cr>"
  && hasText "Claude Code"
  && hasText "Codex CLI"
  && hasText "Pi coding agent"
  && hasText "vim.fn.exepath"
  && hasText "vim.system"
  && hasText "vim.fn.confirm"
  && hasText "blocked_path_patterns"
  && hasText "redact_line"
  && hasText "Full-buffer selection is blocked"
  && hasText "AI_SKILLS_DIR"
  && hasText "NvfAiReviewDiff"
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

assert_phase5_guardrails_headless() {
  local tmpdir lua_file test_file output
  tmpdir="$(mktemp -d)"
  lua_file="$tmpdir/nvf-ai.lua"
  test_file="$tmpdir/nvf-ai-guardrails-test.lua"

  nix_eval_raw .#homeConfigurations.terminalman.config.programs.nvf.settings.vim.luaConfigRC.ai-bridge.data >"$lua_file"

  cat >"$test_file" <<'LUA'
local bridge = _G.NvfAiBridgeTest
assert(type(bridge) == "table", "NVF AI bridge test hooks were not exported")

local function assert_contains(text, needle, name)
  assert(text:find(needle, 1, true), name .. " missing expected text: " .. needle .. "\n" .. text)
end

local function assert_not_contains(text, needle, name)
  assert(not text:find(needle, 1, true), name .. " leaked blocked text: " .. needle .. "\n" .. text)
end

local function expect_sanitized(name, context, forbidden)
  local sanitized, reason, meta = bridge.sanitize_context({
    context = context,
    path = "src/example.txt",
    max_chars = 12000,
  })
  assert(sanitized, name .. " was unexpectedly blocked: " .. tostring(reason))
  assert((meta.redactions or 0) > 0, name .. " did not report a redaction")
  assert_contains(sanitized, "[REDACTED]", name)
  for _, needle in ipairs(forbidden) do
    assert_not_contains(sanitized, needle, name)
  end
end

expect_sanitized("double-quoted password", [[password = "hunter2-quoted-secret"]], { "hunter2-quoted-secret" })
expect_sanitized("double-quoted json token", [["token": "json-token-secret"]], { "json-token-secret" })
expect_sanitized("single-quoted api key", [[api_key: 'single-quoted-api-secret']], { "single-quoted-api-secret" })
expect_sanitized("unquoted secret", [[password = unquoted-password-secret]], { "unquoted-password-secret" })
expect_sanitized("secret key after earlier yaml field", [[metadata: safe token: late-token-secret]], { "late-token-secret" })
expect_sanitized("same-line json secrets", [[{"password":"first","token":"second"}]], { "first", "second" })
expect_sanitized("escaped-quote json secrets", [[{"password":"first\"second","token":"thirdvalue"}]], { "first", "second", "thirdvalue" })
expect_sanitized("same-line env secrets", [[password=first token=second]], { "first", "second" })
expect_sanitized("same-line quoted env secrets", [[password = "hunter2" token = "abc123"]], { "hunter2", "abc123" })
expect_sanitized("same-line yaml secrets", [[api_key: 'xyz' token: "abc"]], { "xyz", "abc" })

local sops_context = table.concat({
  "apiVersion: v1",
  "kind: Secret",
  "metadata:",
  "  name: demo",
  "sops:",
  "  age: encrypted-payload",
}, "\n")
local sanitized, reason = bridge.sanitize_context({ context = sops_context, path = "safe.yaml", max_chars = 12000 })
assert(not sanitized and tostring(reason):find("sops", 1, true), "mid-file SOPS marker was not blocked")

for _, marker in ipairs({ "+sops:", "-sops:" }) do
  sanitized, reason = bridge.sanitize_context({
    context = table.concat({
      "diff --git a/config.yaml b/config.yaml",
      "@@ -1,3 +1,4 @@",
      marker,
      "  age: encrypted-payload",
    }, "\n"),
    path = "safe.yaml",
    max_chars = 12000,
  })
  assert(not sanitized and tostring(reason):find("sops", 1, true), marker .. " diff SOPS marker was not blocked")
end

sanitized, reason = bridge.sanitize_context({
  context = "-----BEGIN OPENSSH PRIVATE KEY-----\nredacted-fixture\n-----END OPENSSH PRIVATE KEY-----",
  path = "safe.txt",
  max_chars = 12000,
})
assert(not sanitized and tostring(reason):find("PRIVATE KEY", 1, true), "private key marker was not blocked")

sanitized, reason = bridge.sanitize_context({ context = "safe text", path = "secrets/example.yaml", max_chars = 12000 })
assert(not sanitized and tostring(reason):find("sensitive path", 1, true), "sensitive path was not blocked")

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "one", "two" })
local selected, range_reason = bridge.get_range_context(1, 2)
assert(not selected and tostring(range_reason):find("Full-buffer selection is blocked", 1, true), "full-buffer visual range was not blocked")
selected, range_reason = bridge.get_range_context(1, 1)
assert(selected == "one", "partial range should remain available: " .. tostring(range_reason))

local pi = bridge.provider_by_id("pi")
pi.exe = "/usr/bin/pi"
local command, opts = bridge.build_provider_invocation(pi, "guarded prompt", "/tmp")
assert(command[1] == "/usr/bin/pi" and command[2] == "-p" and command[3] == "guarded prompt", "pi prompt was not passed as a non-interactive argv message")
assert(opts.stdin == nil, "pi provider should not rely on stdin-only prompting")

local claude = bridge.provider_by_id("claude")
claude.exe = "/usr/bin/claude"
command, opts = bridge.build_provider_invocation(claude, "guarded prompt", "/tmp")
assert(command[1] == "/usr/bin/claude" and command[2] == "-p", "claude argv changed unexpectedly")
assert(opts.stdin == "guarded prompt", "claude provider should continue to receive stdin")
LUA

  if ! output="$(nvim --headless -u NORC -c "luafile $lua_file" -c "luafile $test_file" -c 'if v:errmsg != "" | cquit | endif' -c 'qa!' 2>&1)"; then
    printf '%s\n' "$output" >&2
    rm -rf "$tmpdir"
    return 1
  fi

  rm -rf "$tmpdir"
}

assert_phase5_docs_updated() {
  grep -q "\`ai.nix\`" README.md \
    && grep -q 'AI bridge' docs/neovim-ide.md \
    && grep -q '<leader>aa' docs/neovim-ide.md \
    && grep -q ':NvfAiReviewDiff' docs/neovim-ide.md \
    && grep -q 'NVF Phase 5 AI Bridge Evidence' docs/test/evidence/README.md \
    && [[ -f docs/test/evidence/nvf-phase5-ai-bridge-2026-05-31.md ]]
}

assert_phase5_ticket_statuses_done() {
  local ticket
  for ticket in NVF-021 NVF-022 NVF-023 NVF-024; do
    grep -q '^status: done$' "docs/tickets/${ticket}.md" || return 1
    grep -F "| [${ticket}](${ticket}.md) " docs/tickets/index.md \
      | grep -F '| done | NVF Phase 5 |' >/dev/null || return 1
  done
}

check 'Phase 5 AI bridge module exists' assert_phase5_ai_module_exists
check 'Phase 5 AI bridge module is imported after hardening and before completion' assert_phase5_import_order
check 'terminalman enables guarded AI bridge, providers, commands, and keymaps' assert_terminalman_phase5_ai_bridge
check 'AI bridge guardrails redact and block representative unsafe contexts' assert_phase5_guardrails_headless
check 'README, operations guide, and evidence index document Phase 5 AI bridge' assert_phase5_docs_updated
check 'Phase 5 ticket files and index consistently mark completed work done' assert_phase5_ticket_statuses_done

if ((failures > 0)); then
  exit 1
fi
