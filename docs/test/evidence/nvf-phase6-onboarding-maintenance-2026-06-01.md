---
title: NVF Phase 6 Onboarding and Maintenance Evidence
status: accepted
updated: 2026-06-01
---

# NVF Phase 6 Onboarding and Maintenance Evidence

## Scope

Phase 6 validation for `NVF-025`, `NVF-026`, `NVF-027`, and `NVF-028`: the published Neovim IDE operations guide, README/module import synchronization, editor validation evidence expectations, and pinned NVF/plugin/tool review cadence.

## Documentation assertions

- `docs/neovim-ide.md` is accepted and documents implemented language coverage, required tools, keymaps, troubleshooting, validation, runtime health checks, how to add a language, README synchronization, validation evidence expectations, planned-vs-implemented boundaries, and pinned source/tool review cadence.
- `README.md` remains the discoverable NVF module inventory and must stay synchronized with `home/modules/nvf/default.nix` imports.
- `AGENTS.md` and `docs/test/evidence/README.md` require editor behavior changes to include phase checks, affected Home Manager dry-runs, runtime health evidence when relevant, and explicit skipped-validation reasons with affected profile lists.
- Pinned source review now covers the upstream `nvf` flake input, custom `tidal.nvim` source, Nixpkgs/NVF language tooling, and project-local runner expectations.

## GREEN validation

Commands:

```bash
bash scripts/check-nvf-phase6.sh
bash -n scripts/check-nvf-phase6.sh
nix run --no-write-lock-file nixpkgs#shellcheck -- scripts/check-nvf-phase6.sh
git diff --check
```

Result: `bash scripts/check-nvf-phase6.sh`, `bash -n scripts/check-nvf-phase6.sh`, `nix run --no-write-lock-file nixpkgs#shellcheck -- scripts/check-nvf-phase6.sh`, and `git diff --check` passed on 2026-06-01.

```text
ok - Phase 6 operations guide is published and complete
ok - README NVF module inventory matches default.nix imports
ok - editor validation evidence expectations are documented
ok - pinned NVF/plugin/tool review cadence is documented
ok - Phase 6 evidence file is indexed
ok - Phase 6 ticket files and index consistently mark completed work done
```

## Maintenance cadence

Review pinned NVF-related sources monthly and before broad flake updates. Document findings in this evidence directory or ticket workflow logs, and open follow-up tickets for risky or breaking updates, inactive external plugin sources, supply-chain concerns, or profile-specific validation gaps.
