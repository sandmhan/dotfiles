---
title: Proxmox Provisioning Strategy
status: accepted
---

# ADR003: Proxmox Provisioning Strategy

## Status

Accepted

## Context

Historical VMA and ad hoc LXC flows are fragile and are documented as lessons rather than canonical procedures. The assessment recommends tested VM and LXC templates.

## Decision

Replace fragile VMA/LXC command flows with two documented paths: a minimal Proxmox VM template built from the flake and a NixOS LXC tarball built from `initialLXC`. Provisioning must reserve an ID, attach network, boot, rebuild from the flake, confirm monitoring, and add backups.

## Consequences

- Positive: New guests become reproducible and reviewable.
- Negative: Requires initial template testing and maintenance.
- Follow-up: Phase 3 creates the runbook and archives old VMA notes as historical.

## Links

- Source assessment: [Homelab Architecture Assessment](../audits/homelab-architecture-assessment-2026-05-23.md)
- Related plans: [Phase execution](../plans/phase-execution.md)
- Traceability: Assessment recommendations: Concrete Proxmox Improvement 4; Near-term action 1.
