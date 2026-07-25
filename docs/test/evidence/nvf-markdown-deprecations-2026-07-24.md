---
title: NVF Markdown Deprecation Cleanup Evidence
status: accepted
updated: 2026-07-24
---

# NVF Markdown Deprecation Cleanup Evidence

## Scope

Remove the obsolete Obsidian `completion.nvim_cmp` setting and prevent NVF's
Dart integration from passing the deprecated `lsp.color` field to
flutter-tools.nvim. Flutter tooling remains enabled, and its previously
disabled document-color behavior remains unchanged. Resolve the resulting
single-buffer breadcrumb conflict by keeping markdown-oxide as nvim-navic's
Markdown owner while leaving obsidian-ls attached for note-aware LSP features.

The shared Sandvim module affects `sandmhan`, `terminalman`, `wslman`, and
`macman`.

## Validation

| Command | Result | Notes |
|---|---|---|
| `nixfmt home/modules/nvf/notes.nix home/modules/nvf/languages-data-mobile.nix home/modules/nvf/ui.nix` | passed | Changed Nix modules are formatted. |
| `git diff --check` | passed | No whitespace errors. |
| `bash -n scripts/check-nvf-*.sh` | passed | All NVF validation scripts parse. |
| `bash scripts/check-nvf-baseline.sh` through `bash scripts/check-nvf-phase7.sh` | passed | Existing NVF behavior and documentation checks pass. |
| `NVF_PHASE8_REQUIRE_RUNTIME=1 bash scripts/check-nvf-phase8.sh` | passed | Includes regression assertions that Obsidian has no legacy completion table, flutter-tools receives no color field, and markdown-oxide exclusively owns nvim-navic breadcrumbs. The runtime check confirms both Markdown LSPs remain attached without a navic conflict. |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.sandmhan.activationPackage --show-trace` | passed | Main Linux profile evaluates without activation. |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.terminalman.activationPackage --show-trace` | passed | Terminal profile evaluates without activation. |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.wslman.activationPackage --show-trace` | passed | WSL profile evaluates without activation. |
| `nix build --dry-run --no-write-lock-file .#homeConfigurations.macman.activationPackage --show-trace` | passed | Darwin profile evaluates without activation. |
| Packaged `nvim --headless warning-check.md -c 'sleep 1600m' -c 'messages' -c 'qa!'` | passed | A Markdown buffer remained free of the targeted deferred deprecation notifications. |
| Packaged `nvim --headless warning-check.md '+checkhealth' '+qa!'` | passed | Full health checks completed without either targeted deprecation warning. |

The validation harness also contained two stale checks: Phase 6 expected an
older wording for the repository's Home Manager evidence rule, and Phase 8
queried NVF's removed SQL `dialect` option. Both checks now match the current
repository and pinned NVF interfaces.

## Skipped checks

No required no-activation validation was skipped. Home Manager activation was
intentionally not run.
