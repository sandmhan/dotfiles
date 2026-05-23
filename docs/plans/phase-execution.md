---
title: Phase Execution
status: accepted
---

# Phase Execution

These phases are traceable to [Homelab Architecture Assessment 2026-05-23](../audits/homelab-architecture-assessment-2026-05-23.md).

| Phase | Objective | Tickets |
| --- | --- | --- |
| [00: Stabilize Current State](phase-00-stabilize-current-state/index.md) | Establish a trustworthy baseline before structural code changes. | [HOMELAB-001](../tickets/HOMELAB-001.md), [HOMELAB-002](../tickets/HOMELAB-002.md), [HOMELAB-003](../tickets/HOMELAB-003.md), [HOMELAB-004](../tickets/HOMELAB-004.md) |
| [01: Safety Assertions and Inventory](phase-01-safety-assertions-and-inventory/index.md) | Make inventory and unsafe placeholders explicit. | [HOMELAB-005](../tickets/HOMELAB-005.md), [HOMELAB-006](../tickets/HOMELAB-006.md), [HOMELAB-007](../tickets/HOMELAB-007.md), [HOMELAB-008](../tickets/HOMELAB-008.md) |
| [02: Base Profile Consolidation](phase-02-base-profile-consolidation/index.md) | Reduce duplicated VM/LXC base logic while preserving host-class differences. | [HOMELAB-009](../tickets/HOMELAB-009.md), [HOMELAB-010](../tickets/HOMELAB-010.md), [HOMELAB-011](../tickets/HOMELAB-011.md), [HOMELAB-012](../tickets/HOMELAB-012.md) |
| [03: Proxmox Operational Model](phase-03-proxmox-operational-model/index.md) | Replace fragile provisioning notes with tested Proxmox workflows. | [HOMELAB-013](../tickets/HOMELAB-013.md), [HOMELAB-014](../tickets/HOMELAB-014.md), [HOMELAB-015](../tickets/HOMELAB-015.md), [HOMELAB-016](../tickets/HOMELAB-016.md) |
| [04: Service Migrations](phase-04-service-migrations/index.md) | Place services on VM or LXC hosts according to resource and isolation needs. | [HOMELAB-017](../tickets/HOMELAB-017.md), [HOMELAB-018](../tickets/HOMELAB-018.md), [HOMELAB-019](../tickets/HOMELAB-019.md), [HOMELAB-020](../tickets/HOMELAB-020.md) |
| [05: Optional Automation](phase-05-optional-automation/index.md) | Automate only after inventory, backup, and restore practices are reliable. | [HOMELAB-021](../tickets/HOMELAB-021.md), [HOMELAB-022](../tickets/HOMELAB-022.md), [HOMELAB-023](../tickets/HOMELAB-023.md), [HOMELAB-024](../tickets/HOMELAB-024.md) |
