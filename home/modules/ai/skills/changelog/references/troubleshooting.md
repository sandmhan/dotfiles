# Troubleshooting

Common mistakes and how to fix them.

---

## Validation Checklist

Before committing a CHANGELOG.md, verify:

- [ ] File starts with a preamble citing [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/)
- [ ] `## [Unreleased]` section exists right after the preamble
- [ ] All version headers follow the format `## [x.y.z] - YYYY-MM-DD`
- [ ] All entries are bullet points (`-`) under type headers (`### Added`, etc.)
- [ ] Entry types used are only: Added, Changed, Deprecated, Removed, Fixed, Security
- [ ] All entries are written from a user perspective (not "rewrote X", but "improved X")
- [ ] Entries are specific and complete (not "fixed bugs", but "fixed null pointer in Y")
- [ ] No git log messages are copied verbatim into the changelog
- [ ] All version links at the bottom point to valid GitHub/GitLab diffs
- [ ] Old versions are preserved (never deleted)
- [ ] Dates use ISO 8601 format (YYYY-MM-DD)

---

## Common Mistakes

### 1. Using git log as the changelog

**Problem:** Entries like "refactored parser" or "updated deps" from commit messages.

**Why it's wrong:** git log is for developers; changelogs are for users.

**Fix:** Rewrite entries for users:

- ❌ "refactored parser"
- ✅ "improved JSON parsing speed by 40%"
- ❌ "updated deps"
- ✅ "upgraded Node.js support to 18+ for better performance"

---

### 2. Missing [Unreleased] section

**Problem:** No `## [Unreleased]` section after the preamble; nowhere to add new entries.

**Fix:** Add it immediately after the preamble, before any released versions:

```markdown
# Changelog

All notable changes...

## [Unreleased]

## [1.2.0] - 2026-03-09
...
```

---

### 3. Wrong date format

**Problem:** Dates like "March 9, 2026" or "09/03/2026" or "2026-3-9".

**Why it's wrong:** Ambiguous and inconsistent; ISO 8601 is unambiguous.

**Fix:** Use `YYYY-MM-DD`:

- ❌ `March 9, 2026`
- ❌ `09/03/2026`
- ❌ `2026-3-9`
- ✅ `2026-03-09`

---

### 4. Vague or incomplete entries

**Problem:** Entries like "fixed bugs", "updated stuff", "refactored code".

**Why it's wrong:** Users don't know what actually changed.

**Fix:** Be specific and complete:

- ❌ `Fixed bugs`
- ✅ `Fixed null pointer crash when user logs out with active session`
- ❌ `Updated stuff`
- ✅ `Improved memory usage during file uploads by 20%`
- ❌ `Refactored code`
- ✅ `Redesigned event loop for 3x faster request handling`

---

### 5. Entries in the wrong section

**Problem:** "Added support for dark mode" under `### Fixed` instead of `### Added`.

**Fix:** Use the correct section:

| Section | When to use |
| --- | --- |
| **Added** | New features, new dependencies, new APIs |
| **Changed** | Changes to existing behavior, improvements, breaking changes |
| **Deprecated** | Features marked for future removal |
| **Removed** | Deleted features or dropped support |
| **Fixed** | Bug fixes, patches, security fixes |
| **Security** | Security vulnerabilities and CVE fixes |

---

### 6. Deleted old versions

**Problem:** Removed old version entries like `## [1.0.0]` to "clean up".

**Why it's wrong:** Users need historical context; deleting rewrites project history.

**Fix:** Keep all versions. If a version was broken or unsafe, mark it:

```markdown
## [1.2.1] - 2026-03-08 (YANKED)

This release contained a critical security bug. Upgrade to 1.2.2 immediately.

### Security
- Fixed SQL injection vulnerability in query builder
```

---

### 7. Broken compare links

**Problem:** Links at the bottom don't work:

```markdown
[1.2.0]: https://github.com/user/repo/compare/v1.1.0...v1.2.0
```

But the URL returns 404.

**Why it's wrong:** Users can't see what changed; broken links are useless.

**Fix:**

1. Verify the repository path is correct (user/repo)
2. Verify tags exist: `git tag -l | grep "v1.1.0\|v1.2.0"`
3. Test the link in a browser before committing
4. Use the correct platform syntax:
   - GitHub: `https://github.com/user/repo/compare/v1.0.0...v1.1.0`
   - GitLab: `https://gitlab.com/user/repo/-/compare/v1.0.0...v1.1.0`

---

### 8. No blank line between sections

**Problem:**

```markdown
### Added
- Feature A
### Fixed
- Bug B
```

**Fix:** Add a blank line:

```markdown
### Added
- Feature A

### Fixed
- Bug B
```

---

### 9. Entries without proper capitalization or punctuation

**Problem:**

```markdown
### Added
- added support for dark mode
- improved performance
```

**Fix:** Write as complete sentences:

```markdown
### Added
- Added support for dark mode toggle in settings.
- Improved JSON parsing performance by 40%.
```

---

### 10. Multiple entries on one line

**Problem:**

```markdown
- Added dark mode and custom themes and API v2 support
```

**Fix:** One entry per line:

```markdown
- Added dark mode support.
- Added custom color themes.
- Added API v2 with improved error handling.
```

---

## Quick Fixes

### Fix: No [Unreleased] section

```bash
# Add [Unreleased] at the top (after preamble)
sed -i '7i ## [Unreleased]\n' CHANGELOG.md
```

### Fix: Wrong date format

```bash
# Convert "March 9, 2026" to "2026-03-09"
# In your editor or with sed
sed -i 's/March 9, 2026/2026-03-09/g' CHANGELOG.md
```

### Fix: Entry with wrong type

Cut and paste the bullet point to the correct section header.

### Fix: Vague entry

Rewrite with specifics:

- From: "Fixed performance issue"
- To: "Fixed 100ms latency spike on homepage by optimizing image loading"

---

## Validation Tools

### Manual Checklist

Print the file and review:

```bash
head -20 CHANGELOG.md           # Check preamble and [Unreleased]
grep "^##" CHANGELOG.md         # List all sections
grep "^\-" CHANGELOG.md | head -20  # Sample entries
tail -20 CHANGELOG.md           # Check compare links
```

### markdownlint

Lint Markdown syntax:

```bash
npx markdownlint-cli2 CHANGELOG.md
```

Configure in `.markdownlint-cli2.jsonc` to ignore line-length:

```json
{
  "MD013": false
}
```

### keep-a-changelog (npm)

Validate structure:

```bash
npm install -g keep-a-changelog
npx keep-a-changelog validate
```

### Git Hook (Pre-commit)

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
if git diff --cached --name-only | grep -q CHANGELOG.md; then
    if ! grep -q "## \[Unreleased\]" CHANGELOG.md; then
        echo "❌ CHANGELOG.md missing [Unreleased] section"
        exit 1
    fi
fi
```

---

## Frequently Asked Questions

### Q: Should I use `[Unreleased]` or something else?

A: Always use `[Unreleased]` — it's the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) standard.

### Q: Can I have multiple `[Unreleased]` sections?

A: No. There should be exactly one, at the top, before all released versions.

### Q: Should the changelog go in git?

A: Yes. Commit it to the repository so it's part of the project history.

### Q: Can I auto-generate the changelog from git log?

A: Yes, with tools like `git-cliff`. But you still need to curate and rewrite entries for users.

### Q: How often should I update the changelog?

A: Add entries as you make changes, before releasing. Don't wait until release time to write them.

### Q: What if I made a mistake in a released version entry?

A: Fix it in the `[Unreleased]` section and note it in the next release. Don't rewrite old entries.

### Q: Should old versions have compare links?

A: Yes, it's helpful. Use the first release as the tag (not a compare): `[1.0.0]: https://github.com/user/repo/releases/tag/v1.0.0`.

### Q: Do I need a v prefix in tags but not in section headers?

A: Exactly. Tags are usually `v1.2.3`, but section headers are `## [1.2.3]`.
