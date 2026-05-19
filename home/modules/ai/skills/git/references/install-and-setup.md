# Git Install & Setup

## Prerequisites

- macOS 10.13+, Linux (Debian/Fedora/Arch/Alpine), or Windows (Git Bash, WSL2, or native)
- Ability to use package manager or curl/installer

## Install by Platform

| macOS | Debian/Ubuntu | Fedora/RHEL | Windows |
| --- | --- | --- | --- |
| `brew install git` | `apt install git` | `dnf install git` | `winget install Git.Git` |

## Post-Install Configuration

After installing, configure identity and behavior:

```bash
# Set identity (required for commits)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Set default branch name for new repos
git config --global init.defaultBranch main

# Choose your editor (VS Code example)
git config --global core.editor "code --wait"

# Enable rebase on pull (avoid merge commits by default)
git config --global pull.rebase true

# Set line-ending handling (platform-specific)
# On Windows:
git config --global core.autocrlf true

# On macOS/Linux:
git config --global core.autocrlf input

# Set credential helper
# macOS (uses Keychain):
git config --global credential.helper osxkeychain

# Linux (cache credentials for 15 mins):
git config --global credential.helper cache --timeout=900

# Windows (uses Credential Manager):
git config --global credential.helper manager
```

### SSH Key Setup (optional but recommended)

```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t ed25519 -C "your.email@example.com"

# Copy public key to clipboard
# macOS:
cat ~/.ssh/id_ed25519.pub | pbcopy

# Linux:
cat ~/.ssh/id_ed25519.pub | xclip -selection clipboard

# Windows (PowerShell):
Get-Content ~/.ssh/id_ed25519.pub | Set-Clipboard

# Add key to your GitHub/GitLab account via web UI
# Test connection:
ssh -T git@github.com
```

### Global .gitignore (optional)

Create `~/.gitignore_global` for patterns to ignore everywhere:

```text
.DS_Store
Thumbs.db
*.swp
*~
.idea/
.vscode/
node_modules/
```

Then register it:

```bash
git config --global core.excludesfile ~/.gitignore_global
```

## Verification

```bash
# Check version
git --version

# Verify config
git config --global --list | grep -E 'user\.|core\.editor|pull\.rebase|credential\.'

# Test a commit (in a test repo)
mkdir test-repo && cd test-repo
git init
git add .
git commit --allow-empty -m "test: verify git setup" --no-edit
git log --oneline
```

## Troubleshooting

### "fatal: not a git repository"

- You're outside a git repo. Run `git init` to create one or `git clone` to copy an existing repo.

### "Please tell me who you are" on first commit

- Git user.name and user.email not configured. Run the config commands above with `--global`.

### "Permission denied (publickey)" when pushing

- SSH key not added to your remote account, or ssh-agent doesn't have the key loaded.
- Check: `ssh -T git@github.com` or `ssh -T git@gitlab.com`

### Line-ending issues (CRLF/LF)

- Files swapped between Windows/Unix show as modified even if unchanged.
- Fix: Set `core.autocrlf` to `true` (Windows) or `input` (Unix/macOS) — see config section above.
- Or use `.gitattributes` for per-repo override.
