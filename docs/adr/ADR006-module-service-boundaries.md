---
title: Module and Service Boundaries
status: accepted
---

# ADR006: Module and Service Boundaries

## Status

Accepted

## Context

The `systemModules/` option model is a repository strength. Host files should be thin and deployment-specific, while reusable service logic should live in modules.

## Decision

Invest in option-driven service modules under `systemModules/`; keep host files focused on deployment-specific values. Home Manager profiles remain separate from homelab service roles except for operator/agent user environments.

## Consequences

- Positive: Reduces duplication and improves typed validation.
- Negative: More upfront module design is required.
- Follow-up: Phase 2 and Phase 4 migrate services without large rename-only churn.

## Links

- Source assessment: [Homelab Architecture Assessment](../audits/homelab-architecture-assessment-2026-05-23.md)
- Related plans: [Phase execution](../plans/phase-execution.md)
- Traceability: Assessment recommendations: Determination 2; Suggested module quality gates.
