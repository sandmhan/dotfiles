---
title: Phase 01 - Safety Assertions and Inventory
status: accepted
---

# Phase 01: Safety Assertions and Inventory

## Objective

Make inventory and unsafe placeholders explicit.

## Non-goals

- Generating flake outputs from inventory
- Provisioning new machines

## Scope

- Create metadata-only host inventory
- Add placeholder assertions in service modules
- Add service secret requirement tables
- Normalize state version policy for new hosts

## Dependencies

- Phase 0 baseline

## Tickets

- [HOMELAB-005](../../tickets/HOMELAB-005.md)
- [HOMELAB-006](../../tickets/HOMELAB-006.md)
- [HOMELAB-007](../../tickets/HOMELAB-007.md)
- [HOMELAB-008](../../tickets/HOMELAB-008.md)

## Validation

- Inventory reviewed against registry
- Enabled services fail evaluation for blocking placeholders

## Traceability

- Source: [Architecture assessment migration plan](../../audits/homelab-architecture-assessment-2026-05-23.md#migration-plan)
