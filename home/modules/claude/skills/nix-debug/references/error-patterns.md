# Nix Error Patterns

## "infinite recursion encountered"

**Error:**
```
error: infinite recursion encountered
       at /nix/store/...-source/module.nix:12:5
```

**Root cause:** An attribute references itself during evaluation. Common triggers:
- Using `config.foo` inside the definition of `options.foo`
- A `rec { }` attrset where attributes form a cycle
- Two modules that mutually depend on each other's `config` values without `lib.mkIf` guards

**Fix:**
- Move the value into a `let` binding instead of referencing `config` directly in option defaults
- Replace `rec { x = ...; y = x; }` with `let x = ...; in { inherit x; y = x; }`
- Add `--show-trace` to find the exact cycle location

---

## "attribute 'foo' missing"

**Error:**
```
error: attribute 'foo' missing
       at /nix/store/...-source/flake.nix:23:15
```

**Root cause:** The attribute does not exist in the set being accessed. Causes:
- Package was renamed or removed in the nixpkgs channel you are tracking
- A module is not imported, so its options are absent
- Simple typo in the attribute name

**Fix:**
```bash
# Verify the attribute exists
nix eval nixpkgs#foo --impure 2>/dev/null || echo "not in nixpkgs"
# Search for the correct name
manix "foo"
# Check your nixpkgs input revision
nix flake metadata --json | jq '.locks.nodes.nixpkgs.locked.rev'
```

---

## "hash mismatch"

**Error:**
```
error: hash mismatch in fixed-output derivation '/nix/store/...':
         specified: sha256-AAAA...
         got:       sha256-BBBB...
```

**Root cause:** The fetcher downloaded content whose hash does not match the one declared in the derivation. The upstream source changed (new release, force-pushed tag, or archive regeneration).

**Fix:**
```bash
# For flake inputs — update the lock file
nix flake update

# For fetchFromGitHub / fetchurl — use the fakeHash trick:
# 1. Set hash = lib.fakeHash; (or hash = "";)
# 2. Build — the error prints the correct hash
# 3. Replace with the correct hash
```

---

## "collision between ... and ..."

**Error:**
```
error: collision between '/nix/store/...-foo-1.0/bin/app' and '/nix/store/...-bar-2.0/bin/app'
```

**Root cause:** Two packages in `environment.systemPackages` (or `home.packages`) install a file to the same path.

**Fix:**
```nix
# Option 1: Prioritize one package
environment.systemPackages = [
  (lib.hiPrio pkgs.foo)
  pkgs.bar
];

# Option 2: Remove the less-needed package

# Option 3: Use environment.pathsToLink to control what gets linked
```

---

## "is not allowed to refer to the following paths"

**Error:**
```
error: builder for '/nix/store/...' is not allowed to refer to the following paths:
         /nix/store/...-source
```

**Root cause:** The build sandbox prevents the output from containing references to disallowed store paths. Usually happens when a build script embeds a path to its own source or to a development-only dependency.

**Fix:**
- Use `removeReferencesTo` in `postInstall`
- Ensure build inputs use `fetchurl` / `fetchFromGitHub` instead of raw local paths
- As a last resort, add paths to `allowedReferences` or `disallowedReferences = []`

---

## "error: cannot build on '...'"

**Error:**
```
error: a]'x86_64-darwin' cannot build derivation for 'aarch64-linux'
```

**Root cause:** You are trying to build a derivation for a platform your machine does not support and no remote builder is configured.

**Fix:**
- Check `meta.platforms` on the package
- Use `pkgsCross` for intentional cross-compilation
- Configure a remote builder in `nix.buildMachines`
- On macOS, use a Linux builder VM (`nix.linux-builder.enable = true`)

---

## "while evaluating the attribute '...'"

**Error:**
```
error: while evaluating the attribute 'config.services.foo.enable'
       ... (long trace)
       error: value is a string while a boolean was expected
```

**Root cause:** This is a wrapper around a deeper error. The real cause is at the bottom of the trace.

**Fix:**
```bash
# Always use --show-trace to get the full picture
nix build .#nixosConfigurations.host.config.system.build.toplevel --show-trace 2>&1 | tail -40

# Look at the LAST error in the trace — that is the actual problem
```

---

## "value is a function while a set was expected"

**Error:**
```
error: value is a function while a set was expected
       at /nix/store/...-source/modules/foo.nix:1:1
```

**Root cause:** A Nix module file is a function (as it should be), but it was used in a context expecting an attribute set — typically because the `imports` list contains the module's return value rather than its path, or the function's arguments were not supplied.

**Fix:**
```nix
# Wrong — calling the module and passing the result
imports = [ (import ./foo.nix) ];

# Right — passing the path; the module system calls it
imports = [ ./foo.nix ];

# Also check that the module file starts with the standard pattern:
{ config, lib, pkgs, ... }:
{
  # module body
}
```

---

## "The option '...' does not exist"

**Error:**
```
error: The option 'services.foo.bar' does not exist. Definition values:
       - In '/nix/store/...-source/configuration.nix'
```

**Root cause:** You are setting an option that no imported module declares. The module defining that option is either not imported or the option path is wrong.

**Fix:**
```bash
# Search for the correct option path
manix "services.foo"

# Verify the module is imported
grep -r "foo" flake.nix configuration.nix

# Check if the option exists in your nixpkgs version
nix eval nixpkgs#nixosModules --impure 2>/dev/null
```

---

## Build timeout / hangs

**Symptom:** `nix build` appears stuck with no output for a long time.

**Root cause:** Large build with no binary cache hit, or a derivation is doing expensive work (e.g., compiling a kernel or Chromium).

**Fix:**
```bash
# Use nom to see real-time progress
nom build .#package

# Check if a binary cache has it
nix path-info --store https://cache.nixos.org .#package 2>/dev/null

# Check cachix caches
nix path-info --store https://mycache.cachix.org .#package 2>/dev/null

# For very long builds, consider:
# - Adding a cachix cache and pushing builds from CI
# - Using nix.settings.max-jobs to parallelize
```
