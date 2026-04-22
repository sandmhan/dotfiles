---
name: nix-debug
description: >
  Use when a Nix build fails, evaluation errors appear (infinite recursion,
  attribute not found, hash mismatch, collision, sandbox violation), you need
  to lint or audit Nix code, inspect the dependency graph, compare derivations,
  or search Nix documentation. Also use proactively before committing Nix changes.
---

# nix-debug

## Intent Router

| Intent | Reference |
|---|---|
| Error diagnosis, build failure, evaluation error | [error-patterns.md](references/error-patterns.md) |
| Tool usage (deadnix, statix, manix, nix-tree, nix-diff, nom, flake-checker, nil) | [tool-usage.md](references/tool-usage.md) |

## Diagnostic Workflow

Follow these steps in order — do not skip ahead:

1. **Read the error message.** Most Nix errors state the cause directly. Look for the file path, line number, and the specific complaint.
2. **Add `--show-trace`** if the error location is unclear. Append it to any `nix build`, `nix eval`, or `nixos-rebuild` command.
3. **Use `nix repl`** to interactively inspect the expression that failed. Load the flake and poke at the attribute path.
4. **Use targeted tools** — `nix-tree` for dependency questions, `nix-diff` for "what changed", `manix` for option/function lookup.
5. **Run linters proactively**, not just after failures: `deadnix . && statix check . && nixfmt --check .`

## nix repl Quick Reference

| Command | Purpose |
|---|---|
| `:lf .` | Load current flake into scope |
| `:p expr` | Print value (forces full evaluation) |
| `:t expr` | Show type of expression |
| `Tab` | Complete attribute names in sets |
| `nixosConfigurations.host.config.services.<tab>` | Explore NixOS service config |

## Linting Pipeline

```bash
deadnix . && statix check . && nixfmt --check .
```

Run this before every commit touching `.nix` files.

## Quick Diagnosis

| Error symptom | Likely cause | Fix |
|---|---|---|
| infinite recursion | `config.x` ref inside own option def, or `rec {}` cycle | Use `let` bindings; avoid self-reference in option defs |
| attribute 'foo' missing | Wrong channel, missing import, typo | `nix eval`, verify attr exists, check imports |
| hash mismatch | Upstream content changed | `nix flake update` or use `lib.fakeHash` to get correct hash |
| collision between ... and ... | Two packages provide same file | `lib.hiPrio`, remove duplicate, or `pathsToLink` |
| is not allowed to refer to | Sandbox violation | Use fetchers instead of local paths |
| value is a function while set expected | Module missing arg pattern | Ensure `{ config, lib, pkgs, ... }:` header |
| option does not exist | Wrong option path or missing import | Search with `manix`, verify module is imported |
