---
title: Deployment Tool Strategy
status: accepted
---

# ADR002: Deployment Tool Strategy

## Status

Accepted

## Context

The repository can deploy from local workstations and has a planned `nixos-builder`. Full automation too early would add credentials and failure modes.

## Decision

Use Nix flakes and `nixos-rebuild --target-host` as the primary deployment mechanism. Move build/deploy orchestration toward `nixos-builder` once SSH and storage are stable. Defer Proxmox API automation until inventory and backups are reliable.

## Consequences

- Positive: Keeps deployment inspectable and aligned with NixOS.
- Negative: Some Proxmox lifecycle actions remain manual.
- Follow-up: Phase 3 documents builder-driven deployment and validation.

## Links

- Source assessment: [Homelab Architecture Assessment](../audits/homelab-architecture-assessment-2026-05-23.md)
- Related plans: [Phase execution](../plans/phase-execution.md)
- Traceability: Assessment recommendations: Phase 3 builder deployments; Long-term action 2.
