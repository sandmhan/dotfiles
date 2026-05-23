---
title: Secrets Management
status: accepted
---

# ADR005: Secrets Management

## Status

Accepted

## Context

The repository already uses `sops-nix`, and the assessment finds it is the right upstream fit. Secrets rollout is partial and should be explicit in modules and docs.

## Decision

Use `sops-nix` as the canonical secrets mechanism. Keep encrypted material under `secrets/`, declare service secret requirements close to the module that consumes them, and document rollout in service guides. Never commit decrypted secrets.

## Consequences

- Positive: Secrets are declarative and encrypted at rest.
- Negative: Service modules need explicit secret option surfaces and rollout tables.
- Follow-up: Phase 1 adds service secret requirement tables and Phase 4 validates restore/runbooks.

## Links

- Source assessment: [Homelab Architecture Assessment](../audits/homelab-architecture-assessment-2026-05-23.md)
- Related plans: [Phase execution](../plans/phase-execution.md)
- Traceability: Assessment recommendations: sops-nix fit; Immediate/Near-term secret documentation actions.
