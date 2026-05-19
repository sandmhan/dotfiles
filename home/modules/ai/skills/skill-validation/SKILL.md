---
name: skill-validation
description: >
  Validate skill quality and effectiveness using an 8-criterion LLM scoring rubric.
  Use when reviewing a skill for usability, evaluating prompt engineering quality,
  scoring against prompt engineering best practices, or determining if a skill is
  ready for release. Includes qualitative assessment of description clarity, intent
  routing, example quality, safety coverage, and alignment with Anthropic/OpenAI
  standards. Always run skill-linting first to check structural correctness.
---

# Skill Validation

Quality assurance for LLM skills using 8 criteria: description effectiveness, intent
routing, quick-reference coverage, safety, example quality, reference depth, LLM
usability, and public documentation alignment.

## Intent Router

- `validation/rubric.md` — 8-criterion scoring guide with PASS/WARN/FAIL thresholds
  and report template; load this to score each criterion
- `validation/public-references.md` — Anthropic/OpenAI/academic standards; load when
  designing new skills or scoring criterion V08 (public docs alignment)

## Quick Start

### Phase 1: Automated Pre-Flight

Generate structured context for manual scoring:

```bash
bash validation/validate-skill.sh skills/git
```

Output includes: line counts, section presence, reference inventory, code example counts,
and coverage estimates. Does NOT score qualitative criteria.

### Phase 2: Manual Scoring

Load `validation/rubric.md`. For each of 8 criteria (V01–V08), assign PASS/WARN/FAIL based
on the conditions in the rubric. Document rationale for each.

## Linting vs Validation

- **Skill Linting** (`skill-linting`) — Structural checks: required files, YAML syntax,
  forbidden language, script validity. Must pass before validation.
- **Skill Validation** (this skill) — Quality assessment: description clarity, example
  diversity, safety coverage, prompt engineering standards. Qualitative, requires LLM judgment.

**Always lint first, then validate.** Fix all L01–L12 failures before validation.

## Scoring Guide

Use this workflow to score each criterion:

1. **Read the criterion definition** in `validation/rubric.md`
2. **Check the PASS condition** — does the skill satisfy all requirements?
3. **If not PASS, check WARN** — are there minor gaps or incomplete guidance?
4. **If not WARN, mark FAIL** — fundamental issue; needs rework
5. **Document rationale** — 1–2 sentences explaining the score

## Criterion Summary

| ID | Criterion | Focus |
|---|---|---|
| V01 | Description Effectiveness | Frontmatter includes what, triggers, scenarios |
| V02 | Intent Router Completeness | References are listed with load conditions |
| V03 | Quick Reference Coverage | ~80% of requests answerable inline |
| V04 | Safety Coverage | Destructive ops have guardrails + recovery |
| V05 | Example Quality | Concrete, runnable, cover happy path + edge cases |
| V06 | Reference File Depth | Self-contained; no back-references to SKILL.md |
| V07 | LLM Usability | Agent following skill reliably succeeds |
| V08 | Public Docs Alignment | Reflects Anthropic/OpenAI/academic standards |

## Common Failures

### V01: Vague Description

**FAIL example:** "Provides Git functionality"

**PASS example:** "Git workflows including branching, rebasing, squashing. Use when
the user wants to rebase onto main, create feature branches, or recover lost commits."

→ Fix: Add specific triggers (e.g., "rebase", "merge conflicts") and scenarios.

### V02: Missing Intent Router

**FAIL example:** No Intent Router section; references mentioned inline only.

**PASS example:**

```markdown
## Intent Router
- `refs/aws.md` — AWS deployment patterns
- `refs/gcp.md` — GCP deployment patterns
```

→ Fix: Add Intent Router section; list all reference files with load conditions.

### V03: Workflows Only in References

**FAIL example:** SKILL.md is mostly "see the workflows reference" with no examples.

**PASS example:** SKILL.md has quick examples inline; references provide depth for
advanced scenarios.

→ Fix: Move 80% of common workflows to SKILL.md; reserve references for edge cases.

### V04: Destructive Ops Undocumented

**FAIL example:** `git push --force` mentioned without warning or alternatives.

**PASS example:**

```markdown
Use `git push --force-with-lease` instead of `--force`.
This is safer because it aborts if someone pushed while you were rebasing.
```

→ Fix: Add safety section documenting all destructive ops with guards and recovery.

### V05: No Examples or Pseudocode

**FAIL example:** "To rebase, use the rebase command."

**PASS example:**

```bash
git rebase -i origin/main  # editor opens; reorder commits
# After editing, git push origin <branch> --force-with-lease
```

→ Fix: Add 2–3 concrete, runnable examples per major workflow.

## Thresholds

- **APPROVE:** ≥7 criteria PASS; ≤1 FAIL
- **REVISE:** 3–6 criteria PASS; 1–3 FAIL (fixable)
- **REJECT:** <3 criteria PASS; ≥3 FAIL (needs major rework)

## Report Template

After scoring, use this template:

```markdown
# Skill Validation Report: [skill-name]

## Automated Context
[Output from bash validation/validate-skill.sh]

## Qualitative Scores

| V01 | Description | PASS / WARN / FAIL | [rationale] |
| V02 | Intent Router | PASS / WARN / FAIL | [rationale] |
| ... | ... | ... | ... |

## Summary

**Overall:** APPROVE / REVISE / REJECT

**Strengths:** [Up to 3 things done well]

**Issues:** [FAIL items; how to fix]

**Recommendation:** [Next steps]
```

---

## Before Submission

Verify:

- [ ] Run `bash linting/lint-skill.sh skills/<name>` → zero FAILs
- [ ] Run `bash validation/validate-skill.sh skills/<name>` → review output
- [ ] Score all 8 criteria against `validation/rubric.md`
- [ ] Document rationale for each score
- [ ] All V01–V07 are PASS or WARN (not FAIL)
- [ ] V08 is PASS (aligns with prompt engineering standards)
