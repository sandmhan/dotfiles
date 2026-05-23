---
title: Phase 05 - Optional Automation
status: accepted
---

# Phase 05: Optional Automation

## Objective

Automate only after inventory, backup, and restore practices are reliable.

## Non-goals

- Introducing credentials before operational safety
- Opaque generated service logic

## Scope

- Generate nixosConfigurations from inventory
- Generate docs tables from inventory
- Add Proxmox API provisioning scripts
- Add CI-style flake checks

## Dependencies

- Phases 1-4 stable

## Tickets

- [HOMELAB-021](../../tickets/HOMELAB-021.md)
- [HOMELAB-022](../../tickets/HOMELAB-022.md)
- [HOMELAB-023](../../tickets/HOMELAB-023.md)
- [HOMELAB-024](../../tickets/HOMELAB-024.md)

## Validation

- Generated output diff is reviewable
- Automation has dry-run and rollback documentation

## Traceability

- Source: [Architecture assessment migration plan](../../audits/homelab-architecture-assessment-2026-05-23.md#migration-plan)
