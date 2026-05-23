# Homelab Safety and Mutation Model

## Goal

Allow pi to operate the homelab when asked, while preventing accidental or runaway infrastructure changes.

## Mutation toggle

Infrastructure mutation should be disabled by default.

Escalation path:

```text
/mode homelab-readonly
/mode homelab
```

Entering `homelab` mode should show a confirmation explaining what becomes possible:

- `nixos-rebuild switch --target-host ...`
- Proxmox VM/CT lifecycle operations.
- Proxmox config changes.
- SOPS secret edits.
- Registry status changes.
- Firewall/network changes.

The user should be able to return to safe mode with:

```text
/mode coding
```

or:

```text
/homelab lock
```

## Safety levels

### Level 0: Context only

Allowed:

- Read files.
- Parse registry.
- Summarize topology.
- Generate plans.

Blocked:

- Network checks.
- Remote commands.
- Deployments.

### Level 1: Read-only diagnostics

Allowed:

- Ping/curl health endpoints.
- SSH read-only status commands.
- Proxmox read-only API queries.
- `nix flake show`.
- `nix eval`.
- dry builds.

Blocked:

- VM lifecycle operations.
- `nixos-rebuild switch`.
- SOPS writes.
- Proxmox config mutation.

### Level 2: Guarded mutation

Allowed only after explicit mode escalation and per-action confirmation:

- `nixos-rebuild switch --target-host`.
- `qm set`, `qm start`, `qm stop`, `qm reboot`.
- `pct` lifecycle operations.
- registry updates.
- SOPS edits.

## Proxmox-specific rules

These rules encode prior incident lessons for the Dell node and should be enforced by a tool-call guard, not just documented in prompts.

- Never run VM lifecycle commands in a loop.
- Wait at least 60 seconds between lifecycle operations.
- Maximum 3 lifecycle attempts per VM/CT per session.
- Never spam `qm guest exec` or QMP guest-ping commands.
- No more than one QMP query per 30 seconds.
- If a guest agent is not responding, stop and diagnose VM config instead of polling.
- Never run `nixos-rebuild switch --target-host` against the Proxmox host itself.
- Require user confirmation before commands targeting the Dell node.
- Stop and ask after repeated failure.

## Deployment gate

A safe deployment tool should require this sequence:

1. Confirm host exists in `flake.nix`.
2. Confirm target host/IP/user match `docs/architecture/infrastructure-registry.md` or ask for override.
3. Run eval or dry-build.
4. Show deployment command.
5. Ask for confirmation.
6. Run deployment.
7. Run health checks.
8. Summarize result and suggest registry updates if needed.

## Commands that require escalation

Patterns requiring `homelab` mode:

```text
nixos-rebuild switch --target-host
qm start
qm stop
qm reboot
qm reset
qm destroy
qmrestore
qm set
pct start
pct stop
pct reboot
pct destroy
pvesh set
pvesh create
sops --set
sops -e -i
```

Patterns allowed in read-only mode, with rate limits where applicable:

```text
qm status
qm config
qm list
pct status
pct config
pct list
pvesh get
curl http://.../health
ssh <host> systemctl status ...
nix flake show
nix eval
nixos-rebuild dry-build
```

## Session audit trail

Mutation tools should append structured session entries with:

- mode at time of action
- target host/VM/CT
- command or API action
- confirmation result
- start/end timestamp
- exit code
- stdout/stderr summary
- follow-up health check status

This lets compaction preserve operational state and makes later review easier.

## Open questions

- Should mutation mode expire after a timeout?
- Should mutation mode apply per-session, per-repo, or per-target host?
- Should Proxmox lifecycle operations require a stronger confirmation than Nix deployments?
- Should the extension support emergency lockout if the Dell node starts failing health checks?
