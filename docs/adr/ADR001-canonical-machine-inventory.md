---
title: Canonical Machine Inventory
status: accepted
---

# ADR001: Canonical Machine Inventory

## Status

Accepted

## Context

Inventory state is currently split across comments, roadmap tables, host files, and the infrastructure registry. The assessment identifies this as a risk for VMID reuse, incorrect sizing, and Proxmox drift.

## Decision

Treat `docs/architecture/infrastructure-registry.md` as the current human-readable authority and introduce a future `hosts/inventory.nix` as structured metadata before any generated host outputs. Inventory changes must update docs and host config together.

## Consequences

- Positive: VM/CT IDs, network roles, resources, and backup policy have one review target.
- Negative: Requires maintenance discipline until generation exists.
- Follow-up: Phase 1 creates metadata-only inventory and synchronizes registry entries.

## Links

- Source assessment: [Homelab Architecture Assessment](../audits/homelab-architecture-assessment-2026-05-23.md)
- Related plans: [Phase execution](../plans/phase-execution.md)
- Traceability: Assessment recommendations: Immediate action 1; Determination 4.
