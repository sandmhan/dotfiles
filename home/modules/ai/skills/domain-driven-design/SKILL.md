---
name: domain-driven-design
description: Use when modeling business domains, identifying bounded contexts, designing aggregates/entities/value objects/domain services, defining ubiquitous language, separating domain logic from infrastructure, or reviewing code for DDD alignment.
---

# Domain-Driven Design

Use domain language and boundaries to shape the design.

## Discovery workflow

1. Extract domain terms from requirements, code, tests, and user language.
2. Identify bounded contexts and where terms mean different things.
3. Find core business invariants that must always hold.
4. Choose tactical patterns only where they clarify invariants.
5. Keep persistence, transport, and framework concerns outside domain logic.

## Tactical patterns

- Entity: identity matters across state changes.
- Value object: equality by value, immutable when possible.
- Aggregate: consistency boundary that protects invariants.
- Repository: collection-like persistence boundary for aggregates.
- Domain service: domain operation that does not naturally belong to one entity or value object.
- Application service: orchestration of use cases, transactions, and external systems.
- Domain event: fact that happened in the domain and may trigger downstream behavior.

## Design checks

- Names should match the ubiquitous language.
- Aggregates should be small and protect real invariants.
- Domain objects should not depend on databases, HTTP, CLIs, UI, or framework APIs.
- Application services may coordinate but should not hide core business rules.
- Repositories should not leak query-builder or ORM details into domain code.
- Cross-context communication should happen through explicit contracts or events.

## Output expectations

When using this skill, provide:

- candidate bounded contexts,
- key domain concepts and relationships,
- invariants,
- recommended aggregate boundaries,
- tradeoffs and risks.
