---
name: changelog
description: >
  Maintain CHANGELOG.md files following the [Keep a Changelog format](https://keepachangelog.com/en/1.1.0/)
  with structured Unreleased entries, typed changes, and semver release workflow. Use when
  the agent needs to add entries, cut a release, fix formatting violations, or guide a
  project to adopt the standard.
---

# Changelog Skill

Maintain CHANGELOG.md files in a consistent, user-friendly format that tracks
project evolution without relying on git logs. Helps add entries under the correct
type, run release workflows, and avoid common anti-patterns.

---

## Intent Router

Load the relevant reference file when you need depth on a specific domain.

| Topic | File | Load when... |
| --- | --- | --- |
| Format spec & entry types | `references/cheatsheet.md` | Unsure about entry types, section headers, or version format |
| Tools (git-cliff install) | `references/install-and-setup.md` | User wants optional tooling or help installing git-cliff |
| Release automation | `references/advanced-usage.md` | Integrating changelog into CI/CD, automating generation, mono-repos |
| Common mistakes & fixes | `references/troubleshooting.md` | Entries are vague, git log is being used as a changelog, validation issues |

---

## Quick Start

1. **Locate the CHANGELOG.md** in the project root. If it doesn't exist, note that one needs creating.
2. **Check the preamble** — it should cite [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
3. **Confirm the `[Unreleased]` section exists** at the top after the preamble — this is where new entries go.
4. **Add or update entries** under the correct type (`Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`).
5. **When cutting a release**, rename `[Unreleased]` to `[x.y.z] - YYYY-MM-DD`, add a blank `[Unreleased]` section, and update compare links.

---

## Core Workflow

### Adding an Entry

All entries go under `[Unreleased]`, under the appropriate type heading:

```markdown
## [Unreleased]

### Added
- New feature description

### Fixed
- Bug fix description
```

**Entry types** (from most to least common):

- **Added** — new features, new dependencies
- **Changed** — behavior changes, improvements to existing features
- **Deprecated** — features marked for removal in a future version
- **Removed** — deleted features or dependencies
- **Fixed** — bug fixes and patches
- **Security** — security vulnerabilities and fixes

Write entries **from a user perspective**. Not "rewrote the parser" but "improved parsing speed by 40% for large files."

### Cutting a Release

When releasing version `x.y.z`:

1. Rename `## [Unreleased]` to `## [x.y.z] - YYYY-MM-DD` (use ISO 8601 date).
2. Add a blank `## [Unreleased]` section at the top.
3. Update or add the compare link at the bottom:

   ```markdown
   [x.y.z]: https://github.com/user/repo/compare/v[old-version]...v[x.y.z]
   [Unreleased]: https://github.com/user/repo/compare/v[x.y.z]...HEAD
   ```

4. Create a git commit with the new version.
5. Tag the commit: `git tag v[x.y.z]`.

---

## Quick Command Reference

```bash
# ── Inspect the changelog ───────────────────────────────────────────────────
cat CHANGELOG.md | head -30          # view preamble and Unreleased section
grep "^##" CHANGELOG.md             # list all version headers
grep "###" CHANGELOG.md             # list all entry types

# ── Write a good entry ──────────────────────────────────────────────────────
# Bad:  "fixed bug"
# Good: "fixed null pointer crash in session handler when user logs out"
# Rule: Complete sentence, user-facing wording, specific not vague

# ── Optional: Generate changelog from git log ───────────────────────────────
git log --oneline --no-decorate v1.0.0..HEAD
# Then manually categorize into Added/Changed/Fixed/etc. and rewrite for users

# ── Optional: Use git-cliff to generate or update entries ────────────────────
git-cliff --config cliff.toml             # generate based on commit messages
git-cliff --tag v1.2.3 --output CHANGELOG.md  # cut a release

# ── Validate the file ────────────────────────────────────────────────────────
# Verify [Unreleased] section exists, all versions have dates, compare links work
head -20 CHANGELOG.md && tail -10 CHANGELOG.md
```

---

## Safety Notes

| Rule | Why | How to avoid |
| --- | --- | --- |
| **Don't use git log as a changelog** | Git logs are for developers; changelogs are for users | Manually curate entries; rewrite git messages for end users |
| **Always keep `[Unreleased]` at top** | New entries have nowhere to go without it | Add blank `[Unreleased]` after every release |
| **Use ISO 8601 dates** | Version `1.0.0 - March 9, 2026` is ambiguous; `1.0.0 - 2026-03-09` is not | Enforce YYYY-MM-DD format |
| **Never delete old versions** | History matters; users need context | Keep all versions; use `## [x.y.z] - YYYY-MM-DD (YANKED)` for broken releases |
| **Ensure compare links point to real diffs** | Broken links confuse users | Double-check GitHub/GitLab compare URLs before committing |
| **Categorize correctly** | A vague "Fixed: stuff" wastes reader time | Load the cheatsheet and check entry-type definitions |

---

## Source Policy

The canonical references are:

- [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) — format, entry types, versioning
- [Semantic Versioning](https://semver.org/) — version semantics (MAJOR.MINOR.PATCH rules)
- **git-cliff** (optional) — automated changelog generation from commit messages

---

## Resource Index

### Scripts

| File | Purpose | Platform |
| --- | --- | --- |
| `scripts/install.sh` | Check or install git-cliff (optional) | Bash (macOS, Linux) |
| `scripts/install.ps1` | Check or install git-cliff (optional) | PowerShell (Windows, macOS, Linux) |

Both scripts are optional helpers. The skill works without any tools installed.
