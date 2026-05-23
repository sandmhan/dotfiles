---
title: Phase 02 - Base Profile Consolidation
status: accepted
---

# Phase 02: Base Profile Consolidation

## Objective

Reduce duplicated VM/LXC base logic while preserving host-class differences.

## Non-goals

- Moving every service host at once
- Changing service state locations

## Scope

- Extract common VM options
- Keep compatibility imports for old paths
- Standardize SSH/sudo/firewall defaults by host class
- Add monitoring-client profile

## Dependencies

- Phase 1 inventory and assertions

## Tickets

- [HOMELAB-009](../../tickets/HOMELAB-009.md)
- [HOMELAB-010](../../tickets/HOMELAB-010.md)
- [HOMELAB-011](../../tickets/HOMELAB-011.md)
- [HOMELAB-012](../../tickets/HOMELAB-012.md)

## Validation

- Affected hosts evaluate
- Compatibility imports documented

## Traceability

- Source: [Architecture assessment migration plan](../../audits/homelab-architecture-assessment-2026-05-23.md#migration-plan)
