---
title: Validation Matrix
status: draft
---

# Validation Matrix

| Area | Validation | Evidence |
| --- | --- | --- |
| Documentation structure | File list and link/path sanity checks | Current refactor validation output |
| Markdown whitespace | `git diff --check` | Current refactor validation output |
| Nix host evaluation | `nix build --dry-run .#nixosConfigurations.<host>.config.system.build.toplevel` | To be captured per host when code changes occur |
