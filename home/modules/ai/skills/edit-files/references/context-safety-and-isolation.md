# Context Safety and Isolation

Use this reference when repo complexity, sensitivity, or concurrency makes file editing riskier.

## Keep Context Focused

- Prefer one task per session when possible.
- Load only the files needed for the current task.
- Reset or narrow context when the task changes materially.
- Keep active attention on current invariants, not on stale earlier guesses.

## Follow Repo Truth

- Treat `AGENTS.md`, repo scripts, nearby tests, and established code patterns as the source of truth.
- Prefer existing shared utilities over adding near-duplicate helpers.
- Match local architecture and naming unless the request explicitly changes them.

## Isolation for Parallel Work

When multiple edits may happen concurrently:

- use a dedicated branch or worktree per task
- avoid overlapping edits in the same workspace
- validate each task independently before merging

Isolation reduces collisions, hidden context bleed, and review confusion.

## Sensitive Areas

Use extra caution around:

- secrets and credential-bearing files
- infra and deployment definitions
- generated artifacts
- migrations and schema files
- lockfiles and machine-maintained metadata

For these areas, prefer minimal changes, explicit review, and the narrowest validation that proves correctness.

## Guarding Against Drift

Repeated low-quality edits can gradually damage consistency. Counter this by:

- reusing shared abstractions instead of copying logic
- preserving type-safe or schema-validated boundaries
- preferring small patches over speculative cleanups
- reviewing diffs for style drift and accidental architectural changes

## Approval and Destructive Boundaries

- Keep destructive or high-impact actions behind explicit approval when the environment requires it.
- Do not assume broad permissions or secret access are safe just because they are available.
- Human review remains important for merge boundaries and sensitive changes.
