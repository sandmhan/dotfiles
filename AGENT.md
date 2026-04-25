# AGENT.md

Directives for autonomous AI agents operating in this repository. These rules are non-negotiable and override default behaviors.

## Core Principles

1. **No guesswork.** Every claim must be backed by data — a file you read, a command you ran, a log you inspected, or documentation you referenced. If you are uncertain, say so and explain what you would need to verify.
2. **Concise responses.** Lead with the answer or action. Skip preamble, filler, and restating what was asked. One sentence is better than three. Do not use emojis in responses.
3. **Ask before assuming.** If a task is ambiguous after reviewing existing docs, code, and git history, ask a clarifying question. Do your own research first — check `docs/`, `CLAUDE.md`, `flake.nix`, and relevant host/module files before asking.

## Domain Expertise

You are expected to operate with deep working knowledge of the following domains. Do not hedge or disclaim expertise in these areas — apply it directly.

### Nix & NixOS
- Nix language (builtins, lib functions, module system, overlays, flake schema)
- NixOS module authoring (`lib.mkEnableOption`, `lib.mkIf`, `lib.mkMerge`, `lib.mkDefault`)
- Home Manager module structure and option system
- `nixos-rebuild` workflows: `switch`, `build`, `build-image`, `--target-host`, `--flake`
- Flake inputs, outputs, `follows`, lock file management
- Nix store, derivations, binary caches, substituters
- Debugging: `nix repl`, `nix eval`, `--show-trace`, `nix log`, `nix why-depends`
- Formatting with `nixfmt`

### Proxmox & Virtualization
- Proxmox VE administration: `qm`, `pct`, `qmrestore`, `pvesh`, storage backends (ZFS, LVM)
- VM lifecycle: VMA image creation, restoration, resource allocation, PCI/GPU passthrough
- LXC containers: privileged vs unprivileged, bind mounts, NixOS in LXC
- QEMU guest agent integration, virtio drivers, cloud-init

### Networking
- VLANs, subnetting, firewall rules (iptables/nftables)
- systemd-networkd configuration
- DNS (records, zones, split-horizon), ACME/Let's Encrypt
- VPN (Tailscale, WireGuard), reverse proxies (nginx)
- MQTT, HTTP APIs, webhook patterns

### Linux & Bash
- systemd services, timers, tmpfiles, journalctl
- Process management, filesystem layout, permissions
- Shell scripting (bash), coreutils, SSH, rsync
- Disk management (fdisk, lsblk, mount, ZFS basics)

### Homelab Patterns
- Service composition (databases, caches, reverse proxies, monitoring)
- Secrets management (sops-nix, age keys)
- Backup strategies (borgbackup, restic, snapshots)
- Monitoring stacks (Prometheus, Grafana, Loki, alertmanager)
- OCI/Docker containers in NixOS (`virtualisation.oci-containers`)

## Proxmox Safety Rules (MANDATORY)

These rules are non-negotiable. On 2026-04-24, an autonomous agent crashed the Dell Proxmox node by spamming `qm` commands without backoff, triggering an Intel NIC hardware hang that required a physical power cycle.

### VM Lifecycle Operations
- **Maximum 3 retry attempts** for any VM operation (`qm start`, `qm stop`, `qm reboot`), then stop and report failure
- **Minimum 60-second wait** between VM lifecycle operations on the same VM
- **Never loop on `qm guest exec` or QMP guest-ping.** If the guest agent is unresponsive after 3 checks (30 seconds apart), stop. The fix is in the VM's NixOS config (`services.qemuGuest.enable = true`), not repeated polling

### Forbidden Troubleshooting Patterns
- **Do not modify GRUB to fix guest agent issues.** The QEMU guest agent is a userspace service (`qemu-guest-agent.service`), not a bootloader concern
- **Do not modify keyboard, HID, USB, or peripheral configurations on Proxmox hosts.** These are physical hardware — never touch them from a VM
- **Do not run `nixos-rebuild switch` targeting the Proxmox host itself.** Only target NixOS VMs running on the host
- **Do not repeatedly stop/start VMs to test configuration changes.** Build and validate with `nix build --dry-run` first, deploy once, check logs once

### Resource Awareness
- The Dell Proxmox node has only 15GB RAM and a 2-core i7-3520M. Large Nix builds inside VMs can OOM the host
- The Dell node's Intel I217 NIC (`e1000e` driver) is known to hang under sustained high load
- Before starting a build, check host memory: `ssh root@10.0.0.4 "free -h"`. If available memory is under 2GB, do not proceed
- Never allocate more than 8GB RAM total across all running VMs on the Dell node

### When Troubleshooting Fails
If a VM is not responding as expected after applying a config change:
1. Check VM logs: `ssh root@10.0.0.4 "qm guest cmd <vmid> get-fsinfo"` (one attempt only)
2. Check systemd inside the VM: `ssh user@<vm-ip> "systemctl status qemu-guest-agent"`
3. If neither works, **stop and ask the user**. Do not escalate to VM restarts or host-level changes without explicit approval

## Documentation-First Development

**This is a hard requirement.** All infrastructure work — new hosts, new services, roadmap tasks — follows a documentation-first workflow.

### Before Writing Any Code

Create a working document in `docs/` with the following structure:

```markdown
# <Feature/Service Name>

## Design
What is being built, why, and how it fits into the existing infrastructure.

## Implementation Details
- Host configuration path and flake output name
- Module dependencies and integration points
- Network requirements (ports, VLANs, DNS records)
- Resource allocation (cores, RAM, disk, GPU)
- Secrets required (list each, note sops-nix path)

## Constraints & Considerations
- Hardware limitations
- Dependency ordering (what must exist first)
- Security boundaries
- Migration or rollback concerns

## Testing & Validation Plan
- `nix build --dry-run` evaluation
- Local VM testing steps (if applicable)
- Post-deployment health checks (curl, systemctl, logs)
- Monitoring integration verification

## Implementation Checklist
- [ ] Working doc created and reviewed
- [ ] Host/module Nix files written
- [ ] `nix build --dry-run` passes
- [ ] Deployed to target
- [ ] Health checks pass
- [ ] Monitoring confirmed (node exporter, service metrics)
- [ ] docs/infrastructure-registry.md updated
- [ ] Committed with descriptive message
```

Update this document as implementation progresses. Check off milestones as they are completed. If the design changes during implementation, update the design section — the doc must reflect reality, not the original plan.

### Infrastructure Registry

Maintain `docs/infrastructure-registry.md` as the single source of truth for deployed infrastructure. **Every time a host is created, modified, or decommissioned, this file must be updated in the same commit.**

The registry must contain for each host:

| Field | Description |
|-------|-------------|
| Hostname | systemd hostname |
| Flake output | `nixosConfigurations.<name>` key |
| VM/CT ID | Proxmox ID |
| Type | VM or LXC |
| Node | Which Proxmox node it runs on |
| IP address | Static IP or DHCP reservation |
| Cores / RAM / Disk | Resource allocation |
| GPU | Passthrough device, if any |
| Services | What runs on this host |
| SSH access | User and key requirements |
| Status | `deployed`, `planned`, `decommissioned` |
| Notes | Anything non-obvious |

### Keeping docs/ Current

The `docs/` directory is the operational knowledge base. It is not optional or aspirational — it must reflect the actual state of the infrastructure at all times.

Rules:
- **New host deployed** → update `docs/infrastructure-registry.md` in the same commit
- **Service configuration changed** → update the relevant working doc
- **Lessons learned during deployment** → append to `docs/vm-deployment-lessons.md`
- **Roadmap item completed** → update `docs/homelab-roadmap.md` status table and check off in the relevant working doc
- **Design decision made** → record the decision and rationale in the working doc, not in a comment or commit message alone

## Git & Source Control

### Commit Discipline
- **Commit working states frequently.** A commit should represent a coherent, functional change — not a day's worth of mixed work. Prefer many small commits over one large one.
- **Commit messages describe intent**, not mechanics. "Add Forgejo host with PostgreSQL backend" not "create default.nix and update flake".
- **Never commit broken configurations.** Run `nix build --dry-run` or `nix flake check` before committing Nix changes. If evaluation fails, fix it first.
- **Include doc updates in the same commit** as the code change they describe. Documentation and implementation are not separate tasks.

### Branch Hygiene
- Feature work happens on branches, not main.
- Branch names follow `feat/<name>`, `fix/<name>`, or `docs/<name>`.
- Rebase onto nix before merging to keep history linear.
- Delete branches after merge.

### What Gets Committed
- All Nix configurations (hosts, modules, flake.nix)
- All documentation in `docs/`
- Scripts in `scripts/`
- CLAUDE.md, AGENT.md updates

### What Never Gets Committed
- Secrets, passwords, API keys, private keys (use sops-nix)
- `.vma.zst` images or other large binary artifacts
- Temporary files, editor swap files
- Anything in `.gitignore`

## Task Execution Standards

### Before Starting Work
1. Read the relevant existing docs in `docs/`
2. Read the relevant Nix files (`flake.nix`, host configs, module configs)
3. Check git log for recent changes to the affected area
4. Identify dependencies and ordering constraints

### During Work
1. Follow the documentation-first workflow above
2. Validate Nix expressions with `nix build --dry-run` before deployment
3. Commit at each meaningful milestone, not just at the end
4. Update docs as you go, not as an afterthought

### After Completing Work
1. Verify all checklist items in the working doc are checked
2. Confirm `docs/infrastructure-registry.md` is current
3. Confirm `docs/homelab-roadmap.md` status table reflects completed work
4. Run a final `nix flake check` if flake outputs changed
5. Ensure all changes are committed with clear messages

## Clarifying Questions

When something is unclear:
1. Check `docs/` for existing documentation on the topic
2. Check `CLAUDE.md` for repo conventions
3. Read the relevant source files
4. Check git history for context on past decisions
5. **Only then** ask the user — and when you do, state what you already found and what specifically remains ambiguous
