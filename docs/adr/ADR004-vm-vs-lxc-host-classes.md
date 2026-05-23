---
title: Separation of VM and LXC Host Classes
status: accepted
---

# ADR004: Separation of VM and LXC Host Classes

## Status

Accepted

## Context

VMs and LXCs have different isolation, kernel, device passthrough, backup, and resource characteristics. The repository already has VM and LXC bases but they overlap.

## Decision

Keep distinct VM and LXC host classes. Use VMs for GPU passthrough, agents, gaming, AI, and untrusted or kernel-sensitive workloads. Use LXCs for trusted lightweight services where the shared-kernel model is acceptable. Consolidate duplicated base logic only through explicit profiles.

## Consequences

- Positive: Workloads are placed according to risk and capability.
- Negative: Maintains two provisioning paths.
- Follow-up: Phase 2 extracts shared profiles without erasing host-class differences.

## Links

- Source assessment: [Homelab Architecture Assessment](../audits/homelab-architecture-assessment-2026-05-23.md)
- Related plans: [Phase execution](../plans/phase-execution.md)
- Traceability: Assessment recommendations: Determination 3; VM vs LXC tradeoff table.
