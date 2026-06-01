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

assert_phase6_operations_guide_published() {
  local guide="docs/neovim-ide.md"

  grep -q '^status: accepted$' "$guide" \
    && grep -q '^## Required tools and ownership$' "$guide" \
    && grep -q '^## Keymap namespaces$' "$guide" \
    && grep -q '^## Troubleshooting$' "$guide" \
    && grep -q '^## Adding or changing a language$' "$guide" \
    && grep -q '^## Validation evidence expectations$' "$guide" \
    && grep -q '^## Pinned source and tool review cadence$' "$guide" \
    && grep -q 'Behavior not listed above is optional, project-local, or planned' "$guide" \
    && grep -q 'Later phases will fill in Rust, Go, Lua, and SQL workflows' "$guide" \
    && grep -q 'bash scripts/check-nvf-phase6.sh' "$guide" \
    && grep -q 'docs/test/evidence/' "$guide"
}

assert_phase6_readme_import_inventory_sync() {
  local default_nix="home/modules/nvf/default.nix"
  local expected actual missing extra

  expected="$(mktemp)"
  actual="$(mktemp)"

  {
    printf 'default.nix\n'
    awk '
      /^[[:space:]]*imports = \[/ { in_imports = 1; next }
      in_imports && /^[[:space:]]*\];/ { in_imports = 0 }
      in_imports && match($0, /\.\/[-A-Za-z0-9_]+\.nix/) {
        value = substr($0, RSTART + 2, RLENGTH - 2)
        print value
      }
    ' "$default_nix"
  } | sort -u >"$expected"

  awk '
    /^## Neovim Configuration \(nvf\)$/ { in_section = 1; next }
    in_section && /^---$/ { exit }
    in_section && match($0, /\| `[-A-Za-z0-9_]+\.nix` \|/) {
      value = substr($0, RSTART + 3, RLENGTH - 6)
      print value
    }
  ' README.md | sort -u >"$actual"

  missing="$(comm -23 "$expected" "$actual")"
  extra="$(comm -13 "$expected" "$actual")"

  if [[ -n "$missing" || -n "$extra" ]]; then
    printf 'README NVF inventory mismatch\n' >&2
    [[ -z "$missing" ]] || printf 'missing from README:\n%s\n' "$missing" >&2
    [[ -z "$extra" ]] || printf 'extra in README:\n%s\n' "$extra" >&2
    rm -f "$expected" "$actual"
    return 1
  fi

  rm -f "$expected" "$actual"

  grep -q "When \`home/modules/nvf/default.nix\` imports change" README.md \
    && grep -q 'README drift' README.md
}

assert_phase6_validation_evidence_expectations() {
  grep -q 'Editor/NVF behavior changes must include validation evidence' AGENTS.md \
    && grep -q 'Home Manager dry-runs for affected profiles' AGENTS.md \
    && grep -q 'nvim --headless' AGENTS.md \
    && grep -q 'If validation is skipped, state the reason and list the affected profiles explicitly' AGENTS.md \
    && grep -q 'For editor/NVF behavior changes, evidence should list the exact commands run' docs/test/evidence/README.md \
    && grep -q 'Skipped validation must include an explicit reason and affected profile list' docs/test/evidence/README.md \
    && grep -q 'Skipped: macman dry-run' docs/neovim-ide.md
}

assert_phase6_pinned_review_cadence() {
  grep -q 'Review NVF-related pinned sources and language tools monthly' docs/neovim-ide.md \
    && grep -q 'github:NotAShelf/nvf' docs/neovim-ide.md \
    && grep -q 'grddavies/tidal.nvim' docs/neovim-ide.md \
    && grep -q 'supply-chain risk' docs/neovim-ide.md \
    && grep -q 'Open follow-up tickets for risky updates' docs/neovim-ide.md \
    && grep -q 'Pinned source review now covers' docs/test/evidence/nvf-phase6-onboarding-maintenance-2026-06-01.md
}

assert_phase6_evidence_documented() {
  grep -q 'NVF Phase 6 Onboarding and Maintenance Evidence' docs/test/evidence/README.md \
    && [[ -f docs/test/evidence/nvf-phase6-onboarding-maintenance-2026-06-01.md ]]
}

assert_phase6_ticket_statuses_done() {
  local ticket
  for ticket in NVF-025 NVF-026 NVF-027 NVF-028; do
    grep -q '^status: done$' "docs/tickets/${ticket}.md" || return 1
    grep -F "| [${ticket}](${ticket}.md) " docs/tickets/index.md \
      | grep -F '| done | NVF Phase 6 |' >/dev/null || return 1
  done
}

check 'Phase 6 operations guide is published and complete' assert_phase6_operations_guide_published
check 'README NVF module inventory matches default.nix imports' assert_phase6_readme_import_inventory_sync
check 'editor validation evidence expectations are documented' assert_phase6_validation_evidence_expectations
check 'pinned NVF/plugin/tool review cadence is documented' assert_phase6_pinned_review_cadence
check 'Phase 6 evidence file is indexed' assert_phase6_evidence_documented
check 'Phase 6 ticket files and index consistently mark completed work done' assert_phase6_ticket_statuses_done

if ((failures > 0)); then
  exit 1
fi
