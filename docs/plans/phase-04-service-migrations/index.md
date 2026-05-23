---
title: Phase 04 - Service Migrations
status: accepted
---

# Phase 04: Service Migrations

## Objective

Place services on VM or LXC hosts according to resource and isolation needs.

## Non-goals

- Universal LXC migration
- GPU passthrough without tested rollback

## Scope

- Move monitoring/Git/Matrix to LXCs if resource pressure remains
- Keep agent/gaming/AI/GPU media as VMs
- Migrate GPU workloads to gaming node when available
- Run restore tests for stateful services

## Dependencies

- Phase 3 provisioning and backup model

## Tickets

- [HOMELAB-017](../../tickets/HOMELAB-017.md)
- [HOMELAB-018](../../tickets/HOMELAB-018.md)
- [HOMELAB-019](../../tickets/HOMELAB-019.md)
- [HOMELAB-020](../../tickets/HOMELAB-020.md)

## Validation

- Service checks pass
- Restore drills have evidence
- Registry updated with actual IDs/IPs

## Traceability

- Source: [Architecture assessment migration plan](../../audits/homelab-architecture-assessment-2026-05-23.md#migration-plan)
