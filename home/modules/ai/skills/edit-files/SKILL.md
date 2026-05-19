---
name: edit-files
description: >
  Plan and execute reliable file edits across code, config, docs, and other repository
  content. Use when the user wants to patch files, update implementation details,
  refactor carefully, make targeted multi-file changes, preserve repo conventions,
  follow a safe inspect-plan-edit-verify loop, or avoid risky broad rewrites. Prefer
  structured editors when the file format supports them, especially `jq` for JSON and
  `yq` for YAML, XML, and TOML.
---

# Edit Files

Use this skill as the generic operating model for changing files safely and efficiently.
Favor understanding before editing, minimal patches over rewrites, and deterministic
verification after each meaningful change.

## Intent Router

| Request | Reference | Load When |
| --- | --- | --- |
| Planning, scoping, defining success | `references/planning-and-scoping.md` | The task is vague, medium-sized, or likely to touch multiple files |
| Edit loop, checkpoints, validation | `references/edit-and-verify-loop.md` | The agent is ready to modify files or needs a repeatable editing workflow |
| Context hygiene, concurrency, secrets, protected files | `references/context-safety-and-isolation.md` | The repo is unfamiliar, sensitive, busy, or likely to drift without guardrails |

## Quick Workflow

1. Inspect first.

- Read relevant files, repo guidance, and nearby tests before editing.
- Identify the smallest set of files that can satisfy the request.

1. Define the change.

- State the goal, constraints, invariants, and validation plan.
- Prefer explicit checkpoints for medium or large work.

1. Choose the safest edit path.

- Prefer structured, format-aware editors when possible.
- Use `jq` as the default option for JSON edits.
- Use `yq` for YAML, XML, and TOML edits.
- Fall back to generic patch-style editing when no safer structured path exists.

1. Make the smallest viable patch.

- Preserve surrounding code, comments, and formatting unless the task requires broader cleanup.
- Avoid speculative rewrites and unrelated churn.

1. Verify immediately.

- Run repo-native formatters, linters, tests, and targeted checks after each meaningful change.
- If Git commands fail with "detected dubious ownership", treat that as a repository trust issue that requires `safe.directory`, not as evidence that the edit or patch approach is wrong.
- Review the diff before considering the task complete.

1. Summarize clearly.

- Report files changed, why those files were touched, validation completed, and remaining risks or assumptions.

## Editing Rules

| Area | Rule | Why |
| --- | --- | --- |
| **Scoping** | Keep edits tightly bounded to the request and the files that implement it. | Small changes are easier to verify and review. |
| **Planning** | Analyze before editing for any non-trivial task. | Reduces wrong-file edits and architectural drift. |
| **Patch shape** | Prefer targeted patches over full-file rewrites. | Preserves intent and reduces accidental deletion. |
| **Structured data** | Prefer `jq` or `yq` over raw text edits when the file format allows it. | Format-aware changes are safer than freeform substitutions. |
| **Repo rules** | Follow `AGENTS.md`, repo docs, and existing validation commands. | Repo-local conventions outrank invented ones. |
| **Validation** | Re-run focused checks after each meaningful change. | Deterministic tools catch errors faster than review alone. |
| **Git trust failures** | Separate Git `safe.directory` / "dubious ownership" failures from editing failures and unblock them before relying on Git-based verification. | Prevents misdiagnosing repo trust policy as a bad patch or bad content change. |
| **Diff review** | Inspect the resulting diff before finishing. | Prevents unnoticed collateral edits. |

## Safety Matrix

| Situation | Guardrail | Why |
| --- | --- | --- |
| **Generated files** | Edit source-of-truth inputs first; only touch generated output when explicitly requested. | Avoid losing changes on regeneration. |
| **Migrations / schema changes** | Treat companion files, backward compatibility, and validation as mandatory. | Structural edits can break downstream consumers. |
| **Secrets / credentials** | Do not expose, duplicate, or broadly move sensitive values. | Limits accidental leakage. |
| **Protected config / deploy files** | Prefer minimal edits plus targeted validation. | High-impact files deserve extra certainty. |
| **Concurrent work** | Use isolated branches, worktrees, or task-scoped sessions when parallel edits may collide. | Reduces merge conflicts and context bleed. |
| **Large refactors** | Break into checkpoints and verify after each checkpoint. | Lowers regression risk and review burden. |

## Output Expectations

- Explain the intended scope before editing when the task is not trivial.
- Report the exact files changed and why each file mattered.
- State which validation steps ran and what they proved.
- Call out any remaining uncertainty, skipped checks, or follow-up risk.

## Assets

- `assets/templates/edit-request-template.md` - Reusable task-shaping template for precise edit requests
- `assets/templates/verification-checklist.md` - Post-edit checklist for validation and diff review

## References

- Load `references/planning-and-scoping.md` for turning vague change requests into bounded edit plans.
- Load `references/edit-and-verify-loop.md` for the standard inspect-to-verify workflow and checkpoint guidance.
- Load `references/context-safety-and-isolation.md` for context hygiene, concurrency, and sensitive-repo guardrails.
