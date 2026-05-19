# Planning and Scoping

Use this reference when the request is vague, broad, or likely to affect multiple files.

## Goal

Turn the request into a bounded edit plan before changing anything.

Define:

- the exact problem to solve
- the intended behavior after the change
- the smallest relevant file set
- constraints and invariants to preserve
- the checks that will prove success

## Standard Planning Sequence

1. Inspect the repo and local guidance first.
2. Find the likely implementation files, callers, tests, and config.
3. Restate the requested change in concrete terms.
4. Identify non-goals and unrelated areas to avoid.
5. Choose validation before editing.
6. Break medium or large work into checkpoints.

## Questions the Plan Should Answer

- Which files are likely sources of truth?
- Which invariants must not change?
- What existing utilities or patterns should be reused?
- What tests or checks are required?
- What could break if the edit is wrong?

## Scope Rules

- Prefer the smallest possible change that solves the actual request.
- Avoid mixing refactors, formatting sweeps, and behavior changes unless the task requires it.
- Do not invent conventions when the repo already has them documented or encoded in nearby code.

## Choosing Structured vs Generic Editing

Prefer a structured editor when the format supports it:

- Use `jq` first for JSON files.
- Use `yq` for YAML, XML, and TOML files.
- Use generic patch editing for source code, prose, or formats without a safer structured path.

If a structured edit would be harder to review or would obscure intent, keep the change small and use a normal patch.

## Checkpoint Pattern for Larger Work

Use explicit checkpoints such as:

1. Update interface or schema.
2. Update implementation.
3. Update callers or docs.
4. Update tests.
5. Run validation and review diff.

Each checkpoint should be independently understandable and verifiable.
