---
name: skill-linting
description: >
  Lint skill directories for structural correctness and rule compliance. Use when
  the user wants to check if a skill is valid, find structural errors, or fix lint
  violations. Covers frontmatter validation, file structure, YAML syntax, markdown
  linting, and platform-compatibility checks. Specify the skill directory to lint
  or run batch linting on all skills.
---

# Skill Linting

Validate skill structure against 12 automated rules. Catches structural errors,
missing files, YAML field violations, and platform-specific language before skills
are merged or shipped.

## Intent Router

- `linting/rules.md` — Full rule specifications, examples, and override mechanism;
  load when understanding a specific violation or designing overrides

## Quick Start

Lint a single skill:

```bash
bash linting/lint-skill.sh skills/git
```

Output shows pass/fail status for all 12 rules. Exit code 0 = no failures.

Lint all skills:

```bash
bash linting/lint-all.sh
```

Exits 0 if all skills pass; 1 if any skill has failures.

## Rules at a Glance

| ID | Rule | Severity | What It Checks |
|---|---|---|---|
| L01 | Frontmatter fields | FAIL | Exactly `name` + `description`, no extras |
| L02 | name format | FAIL | kebab-case, ≤64 chars, matches folder |
| L03 | Required files | FAIL | SKILL.md, agents/openai.yaml, agents/claude.yaml |
| L04 | Agent YAML fields | FAIL | Both agents have `display_name`, `short_description`, `default_prompt` |
| L05 | short_description length | FAIL/>64, WARN/<25 | 25–64 characters |
| L06 | Body line count | WARN/≥450, FAIL/≥500 | Under 500 lines |
| L07 | No dangling references | FAIL | All mentioned `references/*.md` exist |
| L08 | Script syntax | FAIL | All `scripts/*.sh` pass `bash -n` |
| L09 | No platform language | FAIL | No platform-specific agent names in prose |
| L10 | No forbidden files | FAIL | No README.md, CHANGELOG.md, etc. |
| L11 | No second-person | WARN | No "You should", "You can", etc. |
| L12 | Markdownlint | FAIL | Pass markdownlint-cli2 checks |

## Fixing Violations

**Workflow:** Fix all FAIL items first, re-run, then address WARN items.

### FAIL Items (must fix before committing)

Fix in this order:

1. **L01 (Frontmatter fields)** — Remove extra YAML fields; keep only `name` and `description`
2. **L02 (name format)** — Rename skill or folder to kebab-case; ensure <64 chars
3. **L03 (Required files)** — Create missing `SKILL.md`, `agents/openai.yaml`, `agents/claude.yaml`
4. **L04 (Agent YAML fields)** — Add missing fields to both agent YAML files
5. **L05 (short_description)** — Truncate descriptions >64 chars; expand <25 chars
6. **L07 (Dangling references)** — Create missing reference files or remove mentions
7. **L08 (Script syntax)** — Fix bash syntax errors in `scripts/*.sh`
8. **L09 (Platform language)** — Replace platform-specific agent names with "the agent"
9. **L10 (Forbidden files)** — Delete README.md, CHANGELOG.md, etc.
10. **L12 (Markdownlint)** — Run `markdownlint-cli2 --fix "skills/<name>/**/*.md"`

### WARN Items (address where practical)

- **L06 (Body line count)** — If ≥450 lines, move details to `references/`
- **L11 (Second-person)** — Rewrite "You should" → imperative form

## Common Fixes

### short_description Too Long (L05)

```yaml
# Before (75 chars):
short_description: "Git workflows and branching strategies for collaborative development"

# After (64 chars, fits):
short_description: "Git workflows, branching, rebasing, and conflict resolution"
```

Use `wc -m` to count characters precisely.

### Platform Language (L09)

```markdown
# Before:
In Claude Code, use the following syntax. Codex works differently.

# After:
Use the following syntax. For alternative approaches, see references/X.md.
```

### Second-Person Language (L11)

```markdown
# Before:
You should run this command. You can configure it like this.

# After:
Run this command. Configure it like this.
```

Use grep to find violations:

```bash
grep -n "\\bYou (should|can|need|must|will|are)\\b" skills/SKILL.md
```

## Override Mechanism

A skill can suppress specific rule IDs in `.lintignore`:

```text
# skills/skill-creator/.lintignore
L09
L11
```

This tells the linter to skip L09 (platform language) and L11 (second-person) because
`skill-creator` legitimately documents cross-platform differences.

Use `.lintignore` sparingly. Each suppression should be justified in a comment.

## Pre-Commit Integration

Add to your `.git/hooks/pre-commit`:

```bash
#!/bin/bash
bash linting/lint-all.sh  # exits 1 if any skill has failures
```

All FAIL items must be resolved before committing; WARN items are suggestions.
