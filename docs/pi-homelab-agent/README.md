# Pi Homelab Agent Ideation

Whiteboarding notes for evolving pi into a general coding agent that can also operate as a Nix/Proxmox homelab assistant when explicitly enabled.

## Goals

- Keep pi useful as the default coding agent across all repositories.
- Add homelab-specific awareness for this dotfiles repo without polluting unrelated projects.
- Make read-only diagnostic tooling broadly available.
- Require explicit escalation before infrastructure mutation.
- Cater tooling to this repo's Nix flake, host layout, Proxmox workflow, registry docs, and safety constraints.
- Improve pi's ability to discover Nix, Home Manager, and flake-input module options before proposing config changes.

## Proposed extension layers

| Layer | Scope | Default availability | Purpose |
|---|---|---:|---|
| Generic coding | Global | Enabled | Normal coding, git safety, test/check helpers |
| Nix diagnostics | Global | Enabled or opt-in | Query Nix options, flake outputs, package metadata, docs |
| Homelab diagnostics | Global or dotfiles-local | Read-only | Health checks, inventory lookup, registry checks |
| Homelab context | Dotfiles-local | Enabled in `~/dotfiles` | Understand this repo's host/service topology |
| Homelab mutation | Dotfiles-local | Disabled until escalated | Deployments, VM lifecycle operations, registry updates |

## Initial mode model

| Mode | Intended use | Homelab context | Diagnostics | Mutations |
|---|---|---:|---:|---:|
| `coding` | Default software work | Off/minimal | Generic only | No infra mutations |
| `nix` | Nix development in any repo | Optional | Nix docs/options | No infra mutations |
| `homelab-readonly` | Investigate infrastructure | Enabled | Nix + homelab | No mutations |
| `homelab` | Operate infrastructure | Enabled | Nix + homelab | Guarded, explicit |

## Key design rule

Separate knowledge from capability:

1. Context can be loaded automatically.
2. Read-only checks can be broadly available.
3. Mutation must require explicit mode escalation and command-specific confirmation.

## Candidate folder layout

Global pi extensions:

```text
~/.pi/agent/extensions/
  coding-presets/
  nix-diagnostics/
  homelab-diagnostics-readonly/
```

Dotfiles-local extensions:

```text
~/dotfiles/.pi/extensions/
  homelab/
    index.ts
    inventory.ts
    modes.ts
    registry.ts
    proxmox-guard.ts
    deploy.ts
    health.ts
    sops.ts
```

## Whiteboard docs

- [Architecture and compartmentalization](./architecture.md)
- [Nix option and documentation tooling](./nix-option-tooling.md)
- [Homelab safety and mutation model](./mutation-safety.md)
- [System prompt considerations](./system-prompt-considerations.md)
