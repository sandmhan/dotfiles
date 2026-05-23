# Refactor Suggestions — Historical Agent Note

> **Status: historical / superseded.** This was an early agent audit captured before the current flake helper, `hosts/gaia/`, formatter output, and `home/modules/` layout. Do not treat the original findings as current without re-verifying against the repository.

For current sources of truth, use:

- `flake.nix` for exported NixOS and Home Manager configurations.
- `hosts/` for machine-specific NixOS hosts.
- `home/options.nix`, `home/modules/`, and `home/profiles/` for Home Manager configuration.
- `docs/architecture/infrastructure-registry.md` for homelab deployment status.

If a new cleanup pass is needed, re-run the checks against the current tree and create a fresh issue or document rather than applying this historical list directly.
