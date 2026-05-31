---
title: Tickets
status: accepted
updated: 2026-05-31
---

# Tickets

Tickets are grouped by project and phase. Existing Homelab tickets trace back to the 2026-05-23 architecture assessment. NVF tickets trace back to the approved NVF enterprise polyglot IDE improvement report.

## ID Counters

| Prefix | Next ID |
| --- | ---: |
| HOMELAB | 025 |
| NVF | 030 |

## Active Tickets

| Ticket | Title | Type | Status | Phase | Dependencies |
| --- | --- | --- | --- | --- | --- |
| [HOMELAB-001](HOMELAB-001.md) | Dry-run current NixOS outputs | task | draft | Homelab Phase 0 | None recorded |
| [HOMELAB-002](HOMELAB-002.md) | Sync infrastructure registry from live Proxmox | task | draft | Homelab Phase 0 | None recorded |
| [HOMELAB-003](HOMELAB-003.md) | Mark deployment placeholders | task | draft | Homelab Phase 0 | None recorded |
| [HOMELAB-004](HOMELAB-004.md) | Confirm deployed services and IDs | task | draft | Homelab Phase 0 | None recorded |
| [HOMELAB-005](HOMELAB-005.md) | Create metadata-only host inventory | task | draft | Homelab Phase 1 | None recorded |
| [HOMELAB-006](HOMELAB-006.md) | Add placeholder assertions | task | draft | Homelab Phase 1 | None recorded |
| [HOMELAB-007](HOMELAB-007.md) | Document service secret requirements | task | draft | Homelab Phase 1 | None recorded |
| [HOMELAB-008](HOMELAB-008.md) | Normalize state version policy | task | draft | Homelab Phase 1 | None recorded |
| [HOMELAB-009](HOMELAB-009.md) | Extract common VM base profile | task | draft | Homelab Phase 2 | None recorded |
| [HOMELAB-010](HOMELAB-010.md) | Keep compatibility imports | task | draft | Homelab Phase 2 | None recorded |
| [HOMELAB-011](HOMELAB-011.md) | Standardize SSH sudo and firewall defaults | task | draft | Homelab Phase 2 | None recorded |
| [HOMELAB-012](HOMELAB-012.md) | Add monitoring client profile | task | draft | Homelab Phase 2 | None recorded |
| [HOMELAB-013](HOMELAB-013.md) | Define VLAN and DHCP reservations | task | draft | Homelab Phase 3 | None recorded |
| [HOMELAB-014](HOMELAB-014.md) | Create tested VM and LXC template procedures | task | draft | Homelab Phase 3 | None recorded |
| [HOMELAB-015](HOMELAB-015.md) | Route deployments through nixos-builder | task | draft | Homelab Phase 3 | None recorded |
| [HOMELAB-016](HOMELAB-016.md) | Add Proxmox backup schedule matrix | task | draft | Homelab Phase 3 | None recorded |
| [HOMELAB-017](HOMELAB-017.md) | Evaluate lightweight LXC migrations | task | draft | Homelab Phase 4 | None recorded |
| [HOMELAB-018](HOMELAB-018.md) | Keep isolated workloads on VMs | task | draft | Homelab Phase 4 | None recorded |
| [HOMELAB-019](HOMELAB-019.md) | Plan GPU node migration | task | draft | Homelab Phase 4 | None recorded |
| [HOMELAB-020](HOMELAB-020.md) | Run restore tests for stateful services | task | draft | Homelab Phase 4 | None recorded |
| [HOMELAB-021](HOMELAB-021.md) | Generate NixOS configs from inventory | task | draft | Homelab Phase 5 | None recorded |
| [HOMELAB-022](HOMELAB-022.md) | Generate docs tables from inventory | task | draft | Homelab Phase 5 | None recorded |
| [HOMELAB-023](HOMELAB-023.md) | Add guarded Proxmox API provisioning | task | draft | Homelab Phase 5 | None recorded |
| [HOMELAB-024](HOMELAB-024.md) | Add CI-style flake validation | task | draft | Homelab Phase 5 | None recorded |
| [NVF-001](NVF-001.md) | Adopt NVF enterprise IDE report as canonical plan | chore | done | NVF Phase 0 | None |
| [NVF-002](NVF-002.md) | Decide default Nix LSP ownership | spike | done | NVF Phase 0 | [NVF-001](NVF-001.md) |
| [NVF-003](NVF-003.md) | Adopt NVF keymap taxonomy | task | done | NVF Phase 0 | [NVF-001](NVF-001.md) |
| [NVF-004](NVF-004.md) | Decide Tidal keymap ownership | spike | done | NVF Phase 0 | [NVF-003](NVF-003.md) |
| [NVF-005](NVF-005.md) | Open initial Neovim IDE operations guide | task | done | NVF Phase 0 | [NVF-001](NVF-001.md) |
| [NVF-006](NVF-006.md) | Fix duplicate Nix LSP ownership | bug | done | NVF Phase 1 | [NVF-002](NVF-002.md) |
| [NVF-007](NVF-007.md) | Keep languages.nix as shared core language module | task | done | NVF Phase 1 | [NVF-001](NVF-001.md), [NVF-006](NVF-006.md) |
| [NVF-008](NVF-008.md) | Add missing LSP ergonomics keymaps | task | done | NVF Phase 1 | [NVF-003](NVF-003.md), [NVF-004](NVF-004.md) |
| [NVF-009](NVF-009.md) | Update README NVF module inventory | chore | done | NVF Phase 1 | [NVF-001](NVF-001.md) |
| [NVF-010](NVF-010.md) | Add Python NVF language module | task | done | NVF Phase 2 | [NVF-006](NVF-006.md), [NVF-007](NVF-007.md) |
| [NVF-011](NVF-011.md) | Add JavaScript TypeScript and JSON NVF language module | task | done | NVF Phase 2 | [NVF-006](NVF-006.md), [NVF-007](NVF-007.md) |
| [NVF-012](NVF-012.md) | Add infrastructure NVF language module | task | done | NVF Phase 2 | [NVF-006](NVF-006.md), [NVF-007](NVF-007.md) |
| [NVF-013](NVF-013.md) | Import validated enterprise language modules | task | done | NVF Phase 2 | [NVF-010](NVF-010.md), [NVF-011](NVF-011.md), [NVF-012](NVF-012.md) |
| [NVF-014](NVF-014.md) | Validate NVF testing and DAP plugin options | spike | done | NVF Phase 3 | [NVF-013](NVF-013.md) |
| [NVF-029](NVF-029.md) | Add NVF testing module | task | done | NVF Phase 3 | [NVF-013](NVF-013.md), [NVF-014](NVF-014.md) |
| [NVF-015](NVF-015.md) | Add test keymaps under leader t | task | done | NVF Phase 3 | [NVF-004](NVF-004.md), [NVF-014](NVF-014.md), [NVF-029](NVF-029.md) |
| [NVF-016](NVF-016.md) | Add debug keymaps under leader d | task | done | NVF Phase 3 | [NVF-014](NVF-014.md), [NVF-029](NVF-029.md) |
| [NVF-017](NVF-017.md) | Enable initial Python and JavaScript TypeScript test debug adapters | task | done | NVF Phase 3 | [NVF-010](NVF-010.md), [NVF-011](NVF-011.md), [NVF-014](NVF-014.md), [NVF-029](NVF-029.md) |
| [NVF-018](NVF-018.md) | Add NVF workspace hardening module | task | open | NVF Phase 4 | [NVF-013](NVF-013.md) |
| [NVF-019](NVF-019.md) | Implement workspace safety controls | task | open | NVF Phase 4 | [NVF-018](NVF-018.md) |
| [NVF-020](NVF-020.md) | Document performance profiling and diagnostic throttling | chore | open | NVF Phase 4 | [NVF-018](NVF-018.md) |
| [NVF-021](NVF-021.md) | Add NVF AI bridge module | task | open | NVF Phase 5 | [NVF-019](NVF-019.md) |
| [NVF-022](NVF-022.md) | Bridge AI actions to Claude Codex and Pi | task | open | NVF Phase 5 | [NVF-021](NVF-021.md) |
| [NVF-023](NVF-023.md) | Add AI keymaps under leader a | task | open | NVF Phase 5 | [NVF-003](NVF-003.md), [NVF-021](NVF-021.md), [NVF-022](NVF-022.md) |
| [NVF-024](NVF-024.md) | Enforce AI confirmation and redaction guardrails | task | open | NVF Phase 5 | [NVF-019](NVF-019.md), [NVF-021](NVF-021.md) |
| [NVF-025](NVF-025.md) | Publish Neovim IDE operations guide | task | open | NVF Phase 6 | [NVF-005](NVF-005.md), [NVF-013](NVF-013.md), [NVF-017](NVF-017.md), [NVF-019](NVF-019.md), [NVF-024](NVF-024.md) |
| [NVF-026](NVF-026.md) | Keep README synchronized with NVF imports | chore | open | NVF Phase 6 | [NVF-009](NVF-009.md), [NVF-013](NVF-013.md) |
| [NVF-027](NVF-027.md) | Add editor validation evidence expectations | chore | open | NVF Phase 6 | [NVF-001](NVF-001.md) |
| [NVF-028](NVF-028.md) | Review pinned plugins and language tool versions periodically | chore | open | NVF Phase 6 | [NVF-013](NVF-013.md) |

## Homelab Phase 0
- [HOMELAB-001](HOMELAB-001.md) — Dry-run current NixOS outputs
- [HOMELAB-002](HOMELAB-002.md) — Sync infrastructure registry from live Proxmox
- [HOMELAB-003](HOMELAB-003.md) — Mark deployment placeholders
- [HOMELAB-004](HOMELAB-004.md) — Confirm deployed services and IDs

## Homelab Phase 1
- [HOMELAB-005](HOMELAB-005.md) — Create metadata-only host inventory
- [HOMELAB-006](HOMELAB-006.md) — Add placeholder assertions
- [HOMELAB-007](HOMELAB-007.md) — Document service secret requirements
- [HOMELAB-008](HOMELAB-008.md) — Normalize state version policy

## Homelab Phase 2
- [HOMELAB-009](HOMELAB-009.md) — Extract common VM base profile
- [HOMELAB-010](HOMELAB-010.md) — Keep compatibility imports
- [HOMELAB-011](HOMELAB-011.md) — Standardize SSH sudo and firewall defaults
- [HOMELAB-012](HOMELAB-012.md) — Add monitoring client profile

## Homelab Phase 3
- [HOMELAB-013](HOMELAB-013.md) — Define VLAN and DHCP reservations
- [HOMELAB-014](HOMELAB-014.md) — Create tested VM and LXC template procedures
- [HOMELAB-015](HOMELAB-015.md) — Route deployments through nixos-builder
- [HOMELAB-016](HOMELAB-016.md) — Add Proxmox backup schedule matrix

## Homelab Phase 4
- [HOMELAB-017](HOMELAB-017.md) — Evaluate lightweight LXC migrations
- [HOMELAB-018](HOMELAB-018.md) — Keep isolated workloads on VMs
- [HOMELAB-019](HOMELAB-019.md) — Plan GPU node migration
- [HOMELAB-020](HOMELAB-020.md) — Run restore tests for stateful services

## Homelab Phase 5
- [HOMELAB-021](HOMELAB-021.md) — Generate NixOS configs from inventory
- [HOMELAB-022](HOMELAB-022.md) — Generate docs tables from inventory
- [HOMELAB-023](HOMELAB-023.md) — Add guarded Proxmox API provisioning
- [HOMELAB-024](HOMELAB-024.md) — Add CI-style flake validation

## NVF Phase 0
- [NVF-001](NVF-001.md) — Adopt NVF enterprise IDE report as canonical plan
- [NVF-002](NVF-002.md) — Decide default Nix LSP ownership
- [NVF-003](NVF-003.md) — Adopt NVF keymap taxonomy
- [NVF-004](NVF-004.md) — Decide Tidal keymap ownership
- [NVF-005](NVF-005.md) — Open initial Neovim IDE operations guide

## NVF Phase 1
- [NVF-006](NVF-006.md) — Fix duplicate Nix LSP ownership
- [NVF-007](NVF-007.md) — Keep languages.nix as shared core language module
- [NVF-008](NVF-008.md) — Add missing LSP ergonomics keymaps
- [NVF-009](NVF-009.md) — Update README NVF module inventory

## NVF Phase 2
- [NVF-010](NVF-010.md) — Add Python NVF language module
- [NVF-011](NVF-011.md) — Add JavaScript TypeScript and JSON NVF language module
- [NVF-012](NVF-012.md) — Add infrastructure NVF language module
- [NVF-013](NVF-013.md) — Import validated enterprise language modules

## NVF Phase 3
- [NVF-014](NVF-014.md) — Validate NVF testing and DAP plugin options
- [NVF-029](NVF-029.md) — Add NVF testing module
- [NVF-015](NVF-015.md) — Add test keymaps under leader t
- [NVF-016](NVF-016.md) — Add debug keymaps under leader d
- [NVF-017](NVF-017.md) — Enable initial Python and JavaScript TypeScript test debug adapters

## NVF Phase 4
- [NVF-018](NVF-018.md) — Add NVF workspace hardening module
- [NVF-019](NVF-019.md) — Implement workspace safety controls
- [NVF-020](NVF-020.md) — Document performance profiling and diagnostic throttling

## NVF Phase 5
- [NVF-021](NVF-021.md) — Add NVF AI bridge module
- [NVF-022](NVF-022.md) — Bridge AI actions to Claude Codex and Pi
- [NVF-023](NVF-023.md) — Add AI keymaps under leader a
- [NVF-024](NVF-024.md) — Enforce AI confirmation and redaction guardrails

## NVF Phase 6
- [NVF-025](NVF-025.md) — Publish Neovim IDE operations guide
- [NVF-026](NVF-026.md) — Keep README synchronized with NVF imports
- [NVF-027](NVF-027.md) — Add editor validation evidence expectations
- [NVF-028](NVF-028.md) — Review pinned plugins and language tool versions periodically
