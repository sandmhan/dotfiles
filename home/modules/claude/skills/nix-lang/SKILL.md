---
name: nix-lang
description: >
  Use when writing, reading, or debugging Nix expressions; when asking about
  Nix syntax, builtins, lib functions, types, or evaluation semantics.
---

# Nix Language Skill

## Intent Router

| Intent | Reference |
|---|---|
| Builtins lookup (string/list/attrset/path/type-check/fetch/eval) | `references/builtins-cheatsheet.md` |
| Lib function patterns (attrsets, lists, strings, trivial, debug, types, generators) | `references/lib-functions.md` |

## Quick Reference

```nix
let x = 1; in x + 2          # let/in bindings
with pkgs; [ git vim ]        # bring attrs into scope
rec { a = 1; b = a + 1; }    # self-referencing attrset
inherit (src) pname version;  # shorthand for pname = src.pname;
a // b                        # shallow merge (b wins)
a ? key                       # true if a has "key"
```

## Type System

`string` `path` `int` `float` `bool` `null` `list` `attrset` `function` `derivation`

## Function Patterns

```nix
x: x + 1                              # single arg
{ a, b }: a + b                        # destructured
{ a, b, ... }: a + b                   # with extra attrs allowed
args@{ a, b, ... }: a + b + args.c    # @ pattern
{ a, b ? 0 }: a + b                    # default value
```

## Common Gotchas

- **Path vs string**: `./foo.nix` is a path (copied to /nix/store); `"./foo.nix"` is a string.
- **Lazy evaluation**: Errors hide in unevaluated branches; use `builtins.deepSeq` to force.
- **`rec` pitfalls**: Infinite recursion if attrs reference each other cyclically; prefer `let` when possible.
- **String interpolation**: `"${x}"` requires `x` to be a string or coercible (path, derivation); use `toString` for ints/bools.
- **`with` shadowing**: `with` does NOT shadow existing bindings in scope; inner `let` always wins.

## Derivation Anatomy

`mkDerivation` wraps `builtins.derivation` — it produces a store path by running a builder (typically bash) with `src`, `buildInputs`, and `phases` (unpack, patch, configure, build, install). The result is a fixed output path in `/nix/store/<hash>-<name>`.
