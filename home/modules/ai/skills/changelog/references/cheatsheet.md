# Changelog Format Cheatsheet

Complete reference for the Keep a Changelog format (v1.1.0).

---

## Preamble

Every CHANGELOG.md starts with a preamble:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
```

---

## Structure

```markdown
# Changelog

All notable changes...

## [Unreleased]

### Added
- Feature 1
- Feature 2

### Changed
- Behavior change 1

### Fixed
- Bug fix 1

## [1.2.0] - 2026-03-09

### Added
- Feature A
- Feature B

### Fixed
- Bug A

## [1.1.0] - 2026-02-15

...

[Unreleased]: https://github.com/user/repo/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/user/repo/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/user/repo/releases/tag/v1.1.0
```

---

## Entry Types

### Added

New features, new dependencies, new public APIs.

**Examples:**

- User-facing features: "Added dark mode toggle in settings"
- Performance: "Added caching layer to reduce API calls by 50%"
- Infrastructure: "Added GitHub Actions CI/CD pipeline"
- Dependencies: "Added `lodash` v4.17 for utility functions"

### Changed

Changes to existing behavior, improvements, refactors.

**Examples:**

- API changes: "Changed `/users` endpoint to return paginated results"

- Improvements: "Improved error messages in validation flow"
- Breaking changes: "Changed default port from 8080 to 3000"
- UX: "Redesigned form layout for better mobile experience"

### Deprecated

Features marked for removal in a future version; users should plan migration.

**Examples:**

- "Deprecated `getUser()` method; use `fetchUser()` instead"

- "Deprecated support for Node 14; upgrade to Node 16 or later"
- "Deprecated API v1 endpoints in favor of v2"

### Removed

Features, dependencies, or support that have been deleted.

**Examples:**

- "Removed `lodash` dependency"

- "Removed legacy API v1 endpoints"
- "Removed support for Windows 7"

### Fixed

Bug fixes, patches, security hotfixes.

**Examples:**

- "Fixed null pointer crash when parsing invalid JSON"

- "Fixed memory leak in event listener cleanup"
- "Fixed incorrect calculation in tax formula"

### Security

Security vulnerabilities and fixes.

**Examples:**

- "Fixed XSS vulnerability in user input sanitization"

- "Fixed SQL injection in query builder"
- "Updated OpenSSL to patch CVE-2023-xxxxx"

---

## Version Section Format

### Standard Release

```markdown
## [1.2.3] - 2026-03-09
```

**Pattern:** `## [MAJOR.MINOR.PATCH] - YYYY-MM-DD`

- Use [Semantic Versioning](https://semver.org/)
- Date is ISO 8601 (YYYY-MM-DD)
- No time component
- Square brackets required

### Yanked Release

A release that was broken or insecure and should not be used:

```markdown
## [1.2.2] - 2026-03-08 (YANKED)
```

Add `(YANKED)` to indicate users should skip this version.

---

## The [Unreleased] Section

Always at the top, after the preamble. Where new entries go before a release.

```markdown
## [Unreleased]

### Added
- Feature coming in the next release

### Fixed
- Bug fixed but not yet released
```

After a release, create a fresh `[Unreleased]` section:

```markdown
## [Unreleased]

## [1.2.0] - 2026-03-09

### Added
- ...
```

---

## Compare Links

At the bottom of the file, link each version to the diff on GitHub/GitLab:

```markdown
[Unreleased]: https://github.com/user/repo/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/user/repo/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/user/repo/releases/tag/v1.1.0
```

**Patterns:**

- **Compare two versions:** `https://github.com/user/repo/compare/v1.0.0...v1.1.0`
- **Compare tag to HEAD:** `https://github.com/user/repo/compare/v1.0.0...HEAD`
- **First release:** `https://github.com/user/repo/releases/tag/v1.0.0`

**For GitLab:**

- Compare: `https://gitlab.com/user/repo/-/compare/v1.0.0...v1.1.0`
- Tag: `https://gitlab.com/user/repo/-/releases/v1.0.0`

---

## Best Practices

### Write for Users, Not Developers

❌ **Bad:**

```markdown
### Changed
- Rewrote parser
- Refactored event loop
```

✅ **Good:**

```markdown
### Changed
- Improved JSON parsing speed by 40%
- Reduced memory usage during file uploads by 20%
```

### Be Specific

❌ **Bad:**

```markdown
### Fixed
- Fixed bugs
- Fixed stuff
```

✅ **Good:**

```markdown
### Fixed
- Fixed null pointer crash when user logs out with active session
- Fixed incorrect date calculation for leap years
- Fixed layout shift on mobile when sidebar loads
```

### One Entry Per Line

❌ **Bad:**

```markdown
- Added support for dark mode and custom themes and user preferences
```

✅ **Good:**

```markdown
- Added dark mode toggle
- Added support for custom color themes
- Added persistent user preference storage
```

### Group Related Changes

❌ **Bad:**

```markdown
### Changed
- Updated API endpoint
- Updated API documentation
- Updated API error handling
```

✅ **Good:**

```markdown
### Changed
- Redesigned API endpoints to follow REST standards
  - Unified error responses across all endpoints
  - Updated documentation with examples
```

---

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Using git log messages as entries | Rewrite for users; prioritize impact not implementation |
| Missing `[Unreleased]` section | Add it after every release |
| Wrong date format (e.g., "March 9, 2026") | Use ISO 8601: `2026-03-09` |
| Deleting old versions | Keep all versions; mark broken ones `(YANKED)` |
| Broken compare links | Test links before committing |
| Entries in wrong section | Use the quick reference above or the full spec |
| No capitalization or punctuation | Write complete sentences for clarity |

---

## Validation Checklist

- [ ] Preamble cites [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/)
- [ ] `[Unreleased]` section exists at the top
- [ ] All entries are under correct type headers
- [ ] Version headers follow `## [x.y.z] - YYYY-MM-DD` format
- [ ] All versions have compare links at the bottom
- [ ] Entries are written for users, not developers
- [ ] No vague entries ("fixed bugs", "updated stuff")
- [ ] Old versions are kept, not deleted
- [ ] No git log messages copied as entries
