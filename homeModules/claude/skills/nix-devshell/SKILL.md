---
name: nix-devshell
description: "Use when creating, modifying, or debugging Nix development shells (mkShell, devShells, nix develop, direnv integration)."
---

# Nix Dev Shell Skill

## Intent Router

| Intent | Reference |
|---|---|
| Language-specific dev shell recipe | [devshell-recipes.md](references/devshell-recipes.md) |

## mkShell Quick Reference

- **`packages`** — packages available in the shell `$PATH`. Use for simple dev shells.
- **`nativeBuildInputs`** — build-time tools (compilers, pkg-config). Correct for cross-compilation.
- **`buildInputs`** — libraries the build links against. Matters for cross-compilation; for simple shells, `packages` suffices.
- **`shellHook`** — bash commands executed on shell entry.
- **`inputsFrom`** — inherit all build inputs from other derivations (e.g., `inputsFrom = [ self'.packages.myApp ];`).
- **`env`** — attribute set of environment variables (e.g., `env.LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.openssl ];`).

## mkShellNoCC

Use `mkShellNoCC` when no C compiler is needed (scripts, interpreted languages). Avoids pulling in gcc/stdenv.

## Direnv Integration

`.envrc`: `use flake`. Run `direnv allow`. Install `nix-direnv` for eval caching.

## Multi-Shell Pattern

```nix
devShells = {
  default = mkShell { };
  ci = mkShell { };
};
```

## nix develop Commands

- `nix develop` — enter default shell
- `nix develop .#ci` — enter named shell
- `nix develop --command cmd` — run single command
