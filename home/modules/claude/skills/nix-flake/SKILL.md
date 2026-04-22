---
name: nix-flake
description: "Use when working with flake.nix, flake.lock, nix flake commands, flake inputs/outputs, or multi-system Nix builds"
---

# Nix Flake

| Intent | Reference |
|---|---|
| Output types, build commands, input patterns | [flake-outputs-reference.md](references/flake-outputs-reference.md) |

## Documentation Lookup

Channel from `flake.lock`: `jq '.nodes.nixpkgs.locked.ref' flake.lock` (`nixos-unstable` → unstable, `nixos-24.11` → stable)

| Resource | URL |
|---|---|
| NixOS options | `https://search.nixos.org/options?channel=unstable` (or `24.11`) |
| HM options | `https://home-manager-options.extranix.com/?query=&release=master` (or `release-24.11`) |
| Packages | `https://search.nixos.org/packages` |

## CLI Quick Reference

| Command | Purpose |
|---|---|
| `nix flake show` | List outputs |
| `nix flake check` | Validate + run checks |
| `nix flake metadata` | Show inputs/revisions |
| `nix flake update` | Update all inputs |
| `nix flake update <input>` | Update one input |
| `nix flake lock` | Regenerate lock |
| `nix build .#output` | Build output |
| `nix build --dry-run .#output` | Dry-run build |
| `nix eval .#output --json` | Evaluate only |
| `nix run .#output` | Build and run |
| `nix develop .#shell` | Enter dev shell |

## Input Patterns

- **follows**: `inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";`
- **Non-flake**: `inputs.repo = { url = "github:user/repo"; flake = false; };`
- See [flake-outputs-reference.md](references/flake-outputs-reference.md) for full examples

## forAllSystems Helper

```nix
forAllSystems = nixpkgs.lib.genAttrs [
  "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"
];
# packages = forAllSystems (system: let pkgs = nixpkgs.legacyPackages.${system}; in { ... });
```

## Overlay Pattern

```nix
overlays.default = final: prev: { myPkg = final.callPackage ./pkgs/mypkg { }; };
# Apply: pkgs = import nixpkgs { inherit system; overlays = [ self.overlays.default ]; };
```

## Verification Checklist

```bash
nix flake check            # Validate outputs + checks
nixfmt --check .           # Format check
nix build --dry-run .#out  # Build check
```
