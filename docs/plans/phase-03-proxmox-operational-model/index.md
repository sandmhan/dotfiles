---
title: Phase 03 - Proxmox Operational Model
status: accepted
---

# Phase 03: Proxmox Operational Model

## Objective

Replace fragile provisioning notes with tested Proxmox workflows.

## Non-goals

- Full Proxmox API automation
- Destructive migration without backups

## Scope

- Define VLANs and DHCP reservations
- Create tested VM and LXC template procedures
- Move builder deployments through nixos-builder
- Add backup schedule matrix

## Dependencies

- Phase 1 inventory
- Phase 2 base clarity preferred

## Tickets

- [HOMELAB-013](../../tickets/HOMELAB-013.md)
- [HOMELAB-014](../../tickets/HOMELAB-014.md)
- [HOMELAB-015](../../tickets/HOMELAB-015.md)
- [HOMELAB-016](../../tickets/HOMELAB-016.md)

## Validation

- Template build and import tested
- Node exporter appears after provisioning
- Backup job documented

## Traceability

- Source: [Architecture assessment migration plan](../../audits/homelab-architecture-assessment-2026-05-23.md#migration-plan)
