# Install & Setup

CHANGELOG.md is a plain text file — no tools required. However, `git-cliff` is an optional
complement for automated changelog generation from commit messages.

## No Tools Required

The changelog skill works entirely without external tools. Simply:

1. Create or edit `CHANGELOG.md` in the project root
2. Follow the format in `cheatsheet.md`
3. Add entries manually under `[Unreleased]`
4. Cut releases by renaming and updating links

---

## Optional: git-cliff

**git-cliff** automates changelog generation by parsing commit messages and grouping them
into structured entries. This is optional and most useful in projects with consistent
commit conventions.

### Install on macOS

```bash
# Using Homebrew
brew install git-cliff

# Verify
git-cliff --version
```

### Install on Linux

**Debian/Ubuntu:**

```bash
sudo apt-get update
sudo apt-get install -y git-cliff
```

**Fedora/RHEL:**

```bash
sudo dnf install -y git-cliff
```

**Arch Linux:**

```bash
sudo pacman -S git-cliff
```

**Alpine Linux:**

```bash
apk add git-cliff
```

**Using Cargo (if Rust is installed):**

```bash
cargo install git-cliff
```

**Using GitHub Releases (any Linux distro):**

```bash
# Download the latest release for your architecture
wget https://github.com/orhun/git-cliff/releases/download/v0.9.2/git-cliff-0.9.2-x86_64-unknown-linux-gnu.tar.gz
tar xzf git-cliff-*.tar.gz
sudo mv git-cliff /usr/local/bin/
git-cliff --version
```

### Install on Windows

**Using winget:**

```powershell
winget install git-cliff
git-cliff --version
```

**Using scoop:**

```powershell
scoop install git-cliff
git-cliff --version
```

**Using Cargo:**

```powershell
cargo install git-cliff
```

---

## Optional: keep-a-changelog (npm)

For changelog validation in CI/CD pipelines:

```bash
npm install -g keep-a-changelog
npx keep-a-changelog validate
```

---

## Basic git-cliff Workflow

### Generate a Changelog

```bash
git-cliff > CHANGELOG.md
```

Generates a complete changelog from all commits, using conventional commit format
(e.g., `feat:`, `fix:`, `docs:`).

### Cut a Release

```bash
git-cliff --tag v1.2.3 >> CHANGELOG.md
```

Appends a new release section for tag `v1.2.3`.

### Use a Config File

Create `cliff.toml` in the project root:

```toml
[changelog]
# Changelog header
header = """
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
"""

# Unreleased section
unreleased_template = """
## [Unreleased]
"""

# Release section template
release_template = """
## [{{ version }}] - {{ date }}
"""

# Commit grouping by type
[[git.commit_parsers]]
message = "^feat"
group = "Added"

[[git.commit_parsers]]
message = "^fix"
group = "Fixed"

[[git.commit_parsers]]
message = "^doc"
group = "Documentation"

[[git.commit_parsers]]
message = "^perf"
group = "Performance"

[[git.commit_parsers]]
message = "^refactor"
group = "Changed"
```

Then run:

```bash
git-cliff --config cliff.toml
```

---

## When to Use git-cliff

**Use git-cliff if:**

- Your project uses conventional commits (`feat:`, `fix:`, etc.)
- You want to generate changelogs automatically
- You're running release workflows in CI/CD

**Skip git-cliff if:**

- You prefer manual, curated changelogs
- Your commit messages are inconsistent
- You want fine-grained control over entry wording

---

## Next Steps

- Read `cheatsheet.md` for the full format specification
- See `advanced-usage.md` for CI/CD integration
- Check `troubleshooting.md` for common issues
