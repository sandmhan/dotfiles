---
title: Documentation Agent Guide
status: accepted
---

# Documentation Agent Guide

Use this guide when creating or updating repository documentation. It adapts the shared documentation template to this dotfiles repository.

## Layer model

1. Architecture — repository structure, host classes, runtime topology, and inventories.
2. ADRs — important decisions with rationale and consequences.
3. Concepts — plain-language explanations for recurring homelab ideas.
4. Design — details for NixOS modules, Home Manager modules, and service composition.
5. Requirements — measurable infrastructure, security, and operational needs.
6. Features — service capability descriptions and setup references.
7. Plans/tickets — phase plans, execution tasks, validation, and evidence.
8. Operations — setup guides, runbooks, and historical deployment notes.

## Frontmatter

New Markdown files under `docs/` should start with YAML frontmatter:

```yaml
---
title: Short Title
status: draft|accepted|deprecated|template
---
```

Existing historical documents may lack frontmatter. Preserve useful content first; normalize frontmatter when touching the file for substantive updates.

## Naming rules

- ADRs: `ADRNNN-short-slug.md`, zero-padded and monotonic.
- Plans: `phase-NN-short-slug/` directories with an `index.md`.
- Tickets: `HOMELAB-NNN.md` for repository-local tickets until another tracker is adopted; include a short descriptive title in the file frontmatter and H1.
- Deprecated or historical content should be moved to the closest `audits/`, `operations/runbooks/`, or `test/evidence/` location with a status note rather than deleted.

## Source of truth rules

- Deployment status, VM IDs, CT IDs, and IPs: [architecture/infrastructure-registry.md](architecture/infrastructure-registry.md).
- Target architecture recommendations: [audits/homelab-architecture-assessment-2026-05-23.md](audits/homelab-architecture-assessment-2026-05-23.md).
- Service module pattern: [architecture/systemmodules-architecture.md](architecture/systemmodules-architecture.md).
- Secrets procedure: [operations/secrets/sops-secrets-setup.md](operations/secrets/sops-secrets-setup.md).
