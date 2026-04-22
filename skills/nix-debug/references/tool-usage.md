# Diagnostic Tool Usage

## deadnix -- Find unused Nix code

```bash
# Check all .nix files in the current tree
deadnix .

# Auto-remove dead code (edits files in place)
deadnix --edit .

# Keep unused lambda arguments (useful for module interfaces where
# { config, lib, pkgs, ... }: must stay stable even if not all are used)
deadnix --no-lambda-arg .

# Check a single file
deadnix path/to/file.nix
```

Dead code includes: unused `let` bindings, unused function arguments, unused `inherit` items. Removing them reduces confusion and evaluation cost.

---

## statix -- Lint Nix antipatterns

```bash
# Report all issues
statix check .

# Auto-fix what can be fixed safely
statix fix .

# Check a single file
statix check path/to/file.nix
```

**Key lints detected:**

| Lint | Description |
|---|---|
| `empty_let_in` | `let in { ... }` with no bindings |
| `manual_inherit` | `x = x;` should be `inherit x;` |
| `useless_parens` | Unnecessary parentheses around expressions |
| `bool_comparison` | `x == true` should be `x` |
| `eta_reduction` | `x: f x` should be `f` |
| `legacy_let_syntax` | Old `let { body = ...; }` form |
| `empty_pattern` | `{ }: expr` with no bindings used |
| `redundant_pattern_bind` | `args@{ ... }` where `args` is unused |
| `unquoted_uri` | Bare URIs that should be quoted strings |

---

## manix -- Search Nix documentation

```bash
# Search NixOS / Home Manager options
manix "programs.git"
manix "services.nginx.virtualHosts"

# Search lib functions
manix "lib.mkIf"
manix "lib.mkMerge"
manix "lib.strings.concatStringsSep"

# Search builtins and pkgs functions
manix "fetchFromGitHub"
manix "builtins.map"
manix "mkDerivation"
```

`manix` searches across NixOS options, Home Manager options, `lib`, and `builtins`. It prints the option type, default value, description, and declaration location.

---

## nix-tree -- Browse dependency graph

```bash
# Interactive TUI for a flake package
nix-tree .#package

# Show build-time (derivation) dependencies instead of runtime
nix-tree --derivation .#package

# Inspect a NixOS system closure
nix-tree .#nixosConfigurations.host.config.system.build.toplevel

# Inspect a store path directly
nix-tree /nix/store/...-some-package
```

**TUI controls:**
- Arrow keys to navigate the dependency tree
- `w` to toggle showing the full path
- `s` to sort by size
- `i` to show package info
- `q` to quit

Use this to answer: "Why is my closure so large?" or "Why does package X pull in dependency Y?"

---

## nix-diff -- Compare derivations

```bash
# Compare two derivations to see what changed
nix-diff /nix/store/old-hash.drv /nix/store/new-hash.drv

# Typical workflow: compare before and after a change
# 1. Build (or eval) before the change
nix eval .#nixosConfigurations.host.config.system.build.toplevel.drvPath
# note the .drv path

# 2. Make changes, then eval again and diff
nix-diff /nix/store/before.drv /nix/store/after.drv
```

`nix-diff` shows exactly which inputs, build commands, or environment variables differ between two derivations. Essential for understanding why a rebuild is triggered.

---

## nom (nix-output-monitor) -- Better build output

```bash
# Drop-in replacement for nix build
nom build .#package

# Drop-in replacement for nix develop
nom develop

# Drop-in for nix flake check
nom flake check

# Pipe mode for any nix command
nix build .#package --log-format internal-json -v 2>&1 | nom --json

# Works with nixos-rebuild too
nixos-rebuild switch --flake . --log-format internal-json -v 2>&1 | nom --json
```

`nom` provides a live dashboard showing: which derivations are building, download progress, build logs, and a summary of completed/pending builds. Far more informative than raw `nix build` output.

---

## flake-checker -- Flake health

```bash
# Check the flake.lock in the current directory
flake-checker

# Check a specific flake.lock
flake-checker --flake-lock-path /path/to/flake.lock
```

**What it validates:**
- nixpkgs input is not too old (staleness check)
- nixpkgs tracks a supported branch (nixos-unstable, nixos-24.11, etc.)
- No git dependencies pointing at `master`/`main` without a `rev` pin
- Flake inputs use consistent nixpkgs versions (no conflicting copies)

Run periodically or in CI to keep your flake.lock healthy.

---

## nil -- Nix LSP

`nil` runs as a language server in your editor, not as a CLI tool. It provides:

- **Diagnostics:** undefined variables, unused bindings, type mismatches, syntax errors
- **Completions:** attribute names, option paths, lib functions
- **Hover info:** types and documentation
- **Go to definition / references**

**Configuration (in flake or editor settings):**
```nix
nil.settings.nix.flake.autoArchive = true;
```

When investigating an error that nil flagged, the diagnostic message maps directly to the same patterns covered in [error-patterns.md](error-patterns.md). Use `nil` for real-time feedback and the CLI tools for batch checks and CI.
