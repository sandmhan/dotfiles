# Architecture and Compartmentalization

## Problem

Pi should remain a general coding agent while also becoming useful for managing this Nix/Proxmox homelab. Homelab-specific behavior should not leak into unrelated repositories, but common diagnostic capabilities should still be accessible globally.

## Proposed separation

### Global capabilities

These should be safe and useful outside the dotfiles repo:

- Nix option discovery and docs lookup.
- Flake introspection.
- Nix evaluation/build diagnostics.
- Read-only host/service health checks when given explicit targets.
- Generic git and coding workflow helpers.

Global tools should avoid assuming this specific homelab layout unless the current working directory or user command identifies it.

### Dotfiles-local capabilities

These should be project-local because they depend on this repo's structure:

- Parsing `flake.nix` host definitions.
- Reading `docs/architecture/infrastructure-registry.md` as source-of-truth metadata.
- Understanding `hosts/*`, `systemModules/*`, and `home/modules/*` conventions.
- Mapping services to VM/CT IDs, IPs, SSH users, deployment status, ports, and docs.
- Proxmox-specific safety policy for the Dell node.
- Deployment commands using this repo's flake outputs.
- Registry consistency checks.

## Mode responsibilities

### `coding`

Default mode.

- Homelab tools inactive.
- No Proxmox/NixOS deployment permissions.
- Normal coding tools and repo guidance apply.
- Nix diagnostics can be used only if requested.

### `nix`

For Nix work in any repository.

- Enables Nix option/documentation tools.
- Can inspect flake outputs and evaluate options.
- Can run safe checks like `nix flake show`, `nix eval`, and dry builds.
- Does not enable homelab mutation.

### `homelab-readonly`

For investigation and planning.

- Loads dotfiles inventory context.
- Enables health checks and read-only Proxmox/status queries.
- Can generate deployment plans.
- Can check registry consistency.
- Cannot modify VMs, deploy systems, edit SOPS secrets, or update production state.

### `homelab`

For guarded operations.

- Requires explicit activation.
- Enables mutation tools after confirmation.
- Enforces rate limits and command sequencing.
- Requires dry-run/build checks before switch/deploy actions.
- Should record operational decisions and command results in the pi session.

## Startup behavior in `~/dotfiles`

Recommended startup message:

```text
Detected dotfiles homelab repo. Homelab context is available in read-only mode.
Use /mode homelab-readonly for diagnostics or /mode homelab for guarded mutations.
```

Defaulting to `coding` avoids surprising behavior when making normal dotfiles edits.

## Command surface

Prefer namespaced commands:

```text
/mode coding
/mode nix
/mode homelab-readonly
/mode homelab
/homelab status
/homelab registry-check
/homelab deploy-plan <host>
/nix options <query>
/nix flake-host <host>
```

Avoid generic commands like `/deploy`, `/status`, or `/check` because they overlap with coding workflows.

## Tool layering

A useful implementation can expose tools in three bands:

1. **Context tools**: read registry, list hosts, find modules.
2. **Diagnostic tools**: health checks, Nix eval, Proxmox status, option lookup.
3. **Mutation tools**: deployments, VM lifecycle operations, secret changes, registry status updates.

Only the first two bands should be available without escalation.
