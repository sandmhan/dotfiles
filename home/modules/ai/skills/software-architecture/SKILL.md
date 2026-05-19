---
name: software-architecture
description: Use when evaluating or designing software architecture, choosing module boundaries, comparing architectural options, writing ADRs, identifying tradeoffs, reviewing coupling/cohesion, planning migrations, or aligning implementation with quality attributes.
---

# Software Architecture

Design around forces, constraints, and quality attributes rather than patterns first.

## Architecture workflow

1. Clarify goals, constraints, stakeholders, and non-goals.
2. Identify quality attributes: reliability, security, performance, maintainability, operability, portability, cost, and delivery speed.
3. Map current module, data, deployment, and integration boundaries.
4. Generate at least two viable options for significant decisions.
5. Compare tradeoffs, risks, reversibility, and migration cost.
6. Prefer the simplest architecture that satisfies known constraints.
7. Capture material decisions as ADRs when useful.

## Review checklist

- Cohesion: modules group behavior that changes together.
- Coupling: dependencies point inward toward stable domain/policy code.
- Boundaries: APIs, events, schemas, and persistence ownership are explicit.
- Data flow: reads, writes, consistency, and failure modes are understood.
- Operability: logs, metrics, tracing, deploy, rollback, and backup paths exist where needed.
- Security: trust boundaries, secrets, authz/authn, and input validation are explicit.
- Evolution: migration path avoids unnecessary big-bang rewrites.

## Output format

For architecture analysis, provide:

- context and constraints,
- current-state summary,
- options considered,
- recommendation,
- tradeoffs,
- migration steps,
- open questions.

Use `madr-adr` when the user asks to record a decision as an ADR.
