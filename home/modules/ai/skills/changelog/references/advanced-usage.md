# Advanced Usage

---

## Automating Changelog in Release Workflow

### Release Script (Bash)

```bash
#!/bin/bash
set -e

VERSION=$1
if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

# Verify version format (e.g., 1.2.3)
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid version format: $VERSION (expected: 1.2.3)"
  exit 1
fi

TODAY=$(date +%Y-%m-%d)
TAG="v$VERSION"

echo "📝 Updating CHANGELOG.md..."
# Update CHANGELOG.md: rename [Unreleased] to [VERSION] - DATE
sed -i "s/## \[Unreleased\]/## [$VERSION] - $TODAY/" CHANGELOG.md

# Add blank [Unreleased] section at the top
sed -i "/^## \[$VERSION\]/i ## [Unreleased]\n" CHANGELOG.md

# Update compare links (assuming GitHub)
OLD_TAG=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")
if [ -n "$OLD_TAG" ]; then
  COMPARE_LINK="[$VERSION]: https://github.com/user/repo/compare/$OLD_TAG...$TAG"
else
  COMPARE_LINK="[$VERSION]: https://github.com/user/repo/releases/tag/$TAG"
fi

# Update unreleased link
sed -i "s|\[Unreleased\]: .*|\[Unreleased\]: https://github.com/user/repo/compare/$TAG...HEAD|" CHANGELOG.md

echo "✅ CHANGELOG.md updated"

git add CHANGELOG.md
git commit -m "chore: bump version to $VERSION"
git tag -a "$TAG" -m "Release $VERSION"

echo "✨ Release $VERSION ready!"
echo "   Next: git push && git push --tags"
```

**Usage:**

```bash
bash release.sh 1.2.3
```

### Release Script (PowerShell)

```powershell
param(
    [string]$Version
)

if (-not $Version) {
    Write-Host "Usage: ./release.ps1 -Version 1.2.3"
    exit 1
}

# Validate version format
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-Host "Invalid version format: $Version (expected: 1.2.3)"
    exit 1
}

$Today = Get-Date -Format "yyyy-MM-dd"
$Tag = "v$Version"
$ChangelogPath = "CHANGELOG.md"

Write-Host "📝 Updating CHANGELOG.md..."

# Read changelog
$content = Get-Content $ChangelogPath -Raw

# Replace [Unreleased] with [VERSION] - DATE
$content = $content -replace '## \[Unreleased\]', "## [$Version] - $Today"

# Add blank [Unreleased] section at top
$lines = $content -split "`n"
$insertIndex = 0
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^## \[') {
        $insertIndex = $i
        break
    }
}
[System.Collections.ArrayList]$linesList = $lines
$linesList.Insert($insertIndex, "## [Unreleased]")
$content = $linesList -join "`n"

# Update links (assuming GitHub)
$oldTag = git describe --tags --abbrev=0 HEAD^ 2>$null
if ($oldTag) {
    $compareLink = "[$Version]: https://github.com/user/repo/compare/$oldTag...$Tag"
} else {
    $compareLink = "[$Version]: https://github.com/user/repo/releases/tag/$Tag"
}

$content = $content -replace '\[Unreleased\]: .*', "[Unreleased]: https://github.com/user/repo/compare/$Tag...HEAD"

Set-Content $ChangelogPath $content
Write-Host "✅ CHANGELOG.md updated"

git add $ChangelogPath
git commit -m "chore: bump version to $Version"
git tag -a $Tag -m "Release $Version"

Write-Host "✨ Release $Version ready!"
Write-Host "   Next: git push && git push --tags"
```

**Usage:**

```powershell
./release.ps1 -Version 1.2.3
```

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Release

on:
  push:
    tags:
      - v*

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Validate CHANGELOG.md
        run: |
          # Check for [Unreleased] section
          if ! grep -q "## \[Unreleased\]" CHANGELOG.md; then
            echo "❌ CHANGELOG.md must have [Unreleased] section"
            exit 1
          fi

          # Check for the released version
          VERSION=${GITHUB_REF#refs/tags/v}
          if ! grep -q "## \[$VERSION\]" CHANGELOG.md; then
            echo "❌ CHANGELOG.md missing entry for $VERSION"
            exit 1
          fi

          echo "✅ CHANGELOG.md is valid"

      - name: Create GitHub Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          body_path: ./CHANGELOG.md
```

### GitLab CI

```yaml
release:
  stage: deploy
  script:
    # Validate CHANGELOG.md
    - |
      if ! grep -q "## \[Unreleased\]" CHANGELOG.md; then
        echo "❌ CHANGELOG.md must have [Unreleased] section"
        exit 1
      fi
      VERSION=${CI_COMMIT_TAG#v}
      if ! grep -q "## \[$VERSION\]" CHANGELOG.md; then
        echo "❌ CHANGELOG.md missing entry for $VERSION"
        exit 1
      fi
    - echo "✅ CHANGELOG.md is valid"
  only:
    - tags
```

---

## Mono-Repo: Per-Package Changelogs

For projects with multiple packages, maintain a CHANGELOG.md per package:

```text
my-monorepo/
├── CHANGELOG.md (root changelog)
├── packages/
│   ├── core/
│   │   └── CHANGELOG.md
│   └── ui/
│       └── CHANGELOG.md
```

### Root Changelog Structure

```markdown
# Changelog

All notable changes across all packages.

## [Unreleased]

### packages/core
- [core] Added feature X

### packages/ui
- [ui] Fixed bug Y

## [1.2.0] - 2026-03-09

### packages/core
- [core] Added feature A

### packages/ui
- [ui] Fixed bug B
```

### Package Changelog

```markdown
# @my-org/core Changelog

## [Unreleased]

### Added
- Feature X

## [2.0.0] - 2026-03-09

### Changed
- Breaking: Renamed export from `foo()` to `bar()`
```

---

## git-cliff Config for Mono-Repos

```toml
[git.commit_parsers]
message = "^feat(core)"
group = "Added (core)"

message = "^fix(core)"
group = "Fixed (core)"

message = "^feat(ui)"
group = "Added (ui)"

message = "^fix(ui)"
group = "Fixed (ui)"

[git.skip_tags]
patterns = ["beta", "rc"]
```

Then generate with:

```bash
git-cliff --config cliff.toml > CHANGELOG.md
```

---

## Extracting Release Notes for GitHub Releases

Extract the section for a specific version:

```bash
#!/bin/bash
VERSION=$1
awk "/^## \[$VERSION\]/,/^## \[/" CHANGELOG.md | head -n -1
```

Or in PowerShell:

```powershell
param([string]$Version)
$pattern = "^## \[$Version\]"
$content = Get-Content CHANGELOG.md
$start = $content | Select-String -Pattern $pattern | ForEach-Object { [array]::IndexOf($content, $_) }
$end = $content[($start+1)..($content.Count)] | Select-String -Pattern "^## \[" | ForEach-Object { $start + 1 + [array]::IndexOf($content[($start+1)..($content.Count)], $_) }
$content[$start..($end-1)]
```

---

## Linting Changelog in Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash

if git diff --cached --name-only | grep -q "CHANGELOG.md"; then
    echo "🔍 Linting CHANGELOG.md..."

    # Check [Unreleased] exists
    if ! grep -q "## \[Unreleased\]" CHANGELOG.md; then
        echo "❌ [Unreleased] section missing"
        exit 1
    fi

    # Check all entries have types
    if grep -q "^## \[.*\]" CHANGELOG.md | grep -v "^\-"; then
        echo "❌ Entries must be bullet points under type headers"
        exit 1
    fi

    echo "✅ CHANGELOG.md looks good"
fi

exit 0
```

Make it executable:

```bash
chmod +x .git/hooks/pre-commit
```

---

## Generating Markdown Release Notes

Extract release notes for a version and convert to Markdown:

```bash
#!/bin/bash
VERSION=$1

awk "/^## \[$VERSION\]/,/^## \[/" CHANGELOG.md |
  sed '1d;$d' |                    # Remove first and last lines (version headers)
  sed 's/^### /#### /g' |          # Downgrade ### to ####
  sed 's/^## \[Unreleased\]//' |   # Remove stray Unreleased
  grep -v '^$' > release-$VERSION.md

echo "Generated release-$VERSION.md"
```
