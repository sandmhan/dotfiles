# Repository Cleanup Analysis — Historical Note

> **Status: historical / superseded.** This file replaced an April 2026 cleanup audit that described repository state before the current `hosts/`, `home/modules/`, and flake helper layout. It is retained only as a pointer for future cleanup work and is **not** an authoritative description of the current architecture.

## Current authoritative sources

- `flake.nix` — exported NixOS and Home Manager configurations.
- `hosts/` — machine-specific NixOS configuration, including `hosts/gaia/default.nix` for the desktop host.
- `hosts/server/` — shared Proxmox VM base imported by VM hosts.
- `home/options.nix`, `home/modules/`, and `home/profiles/` — current option-based Home Manager configuration.
- `systemModules/` — reusable service modules.
- `docs/infrastructure-registry.md` — canonical homelab deployment status, VM IDs, IPs, and service inventory.

## Current-state observations

- `gaia` now imports `./hosts/gaia` from `flake.nix`; it no longer uses the legacy root-level desktop entry point.
- The current Home Manager module tree lives under `home/modules/`, with profiles under `home/profiles/`.
- `.gitignore` exists and should remain the source of truth for ignored build outputs.
- Home Manager configurations currently import `nvf.homeManagerModules.default`; nixvim is not loaded in the exported Home Manager profiles.
- `hosts/server/default.nix` uses `system.stateVersion = "25.05"`.
- `flake.nix` exports a `formatter`.
- Local theme files under `themes/` are used by the current theming setup and should not be treated as dead content without re-verification.

## Cleanup process for future audits

When doing another cleanup pass:

1. Cross-check every claim against `flake.nix`, `hosts/`, `home/`, and `systemModules/` before editing.
2. Prefer marking legacy documents historical rather than deleting useful context.
3. Update `docs/infrastructure-registry.md` in the same change as any host or deployment-status change.
4. Run targeted grep checks for stale paths and a lightweight flake evaluation when documentation depends on current outputs.
