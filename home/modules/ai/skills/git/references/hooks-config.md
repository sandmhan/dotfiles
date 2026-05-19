# Config, Hooks & GPG Reference

---

## `git config` — Configuration Levels

Git config is layered. Lower levels override higher ones:

| Level | Scope | File | Flag |
| --- | --- | --- | --- |
| `system` | All users on machine | `C:\Program Files\Git\etc\gitconfig` | `--system` |
| `global` | Current user | `~/.gitconfig` | `--global` |
| `local` | Current repo | `.git/config` | `--local` (default) |
| `worktree` | Current worktree | `.git/config.worktree` | `--worktree` |

```bash
git config --list                       # show all effective config
git config --list --show-origin         # show config with which file it came from
git config --list --show-scope          # show scope (system/global/local)
git config --global <key> <value>       # set global config
git config --local <key> <value>        # set repo-level config
git config --unset <key>                # remove a key
git config --global --edit              # open global config in editor
git config <key>                        # read a value
```

---

## Essential Global Settings

```bash
# Identity (required for commits)
git config --global user.name "Alison Aquinas"
git config --global user.email "alison@aquinas.pro"

# Editor (this machine: VS Code)
git config --global core.editor "code --wait"

# Default branch name for new repos
git config --global init.defaultBranch main

# Pull strategy
git config --global pull.rebase false       # merge on pull (current setting)
git config --global pull.rebase true        # rebase on pull (cleaner history)
git config --global pull.ff only            # only fast-forward; fail if diverged

# Auto-squash fixup commits
git config --global rebase.autoSquash true

# Rerere (record + replay conflict resolutions)
git config --global rerere.enabled true
git config --global rerere.autoUpdate true

# Push default
git config --global push.default current   # push to same-named remote branch
git config --global push.autoSetupRemote true  # auto set upstream on push

# Diff/merge tool
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait $MERGED'
git config --global diff.tool vscode
git config --global difftool.vscode.cmd 'code --wait --diff $LOCAL $REMOTE'
```

---

## Line Endings (`core.autocrlf`)

This machine has `core.autocrlf=true`. Here's what each value means:

| Value | On checkout | On commit | Best for |
| --- | --- | --- | --- |
| `true` | LF → CRLF | CRLF → LF | Windows-only repos |
| `input` | No conversion | CRLF → LF | Cross-platform repos on Windows |
| `false` | No conversion | No conversion | Linux/Mac, or managed via .gitattributes |

```bash
# Change for cross-platform repos
git config --global core.autocrlf input
```

### `.gitattributes` — Fine-Grained Line Ending Control

`.gitattributes` in the repo root overrides `core.autocrlf` per file type:

```gitattributes
# Default: normalize all text files to LF in repo, CRLF on checkout for Windows
* text=auto

# Force LF for specific types (shell scripts, Python, etc.)
*.sh text eol=lf
*.py text eol=lf
*.yml text eol=lf

# Force CRLF (batch files, Visual Studio project files)
*.bat text eol=crlf
*.sln text eol=crlf

# Explicitly binary (no conversion)
*.png binary
*.jpg binary
*.pdf binary
*.zip binary
```

Other `.gitattributes` uses:

```gitattributes
# Custom diff driver for Word documents
*.docx diff=word

# Prevent merging of generated files
package-lock.json merge=ours

# LFS tracking (set by `git lfs track`)
*.psd filter=lfs diff=lfs merge=lfs -text
```

---

## GPG Signing (This Machine)

This machine has GPG signing configured:

- `commit.gpgsign=true` — all commits auto-signed
- `user.signingkey=829CA057F35DC2C839477F69FDD7CD4EB45DF7C1!` — the `!` pins the exact subkey

```bash
# View GPG-signed commit log
git log --show-signature
git log --format="%h %G? %GS %s"       # %G? = status, %GS = signer name
# G = good sig, B = bad sig, U = unknown key, E = missing sig, N = no sig

# Manually sign a commit (already auto-signed but can be explicit)
git commit -S -m "feat: login"

# Sign a tag
git tag -s v1.0.0 -m "Release 1.0.0"

# Verify a tag
git tag -v v1.0.0

# If signing fails: check GPG agent is running
gpg --list-secret-keys                  # list available keys
gpg-connect-agent reloadagent /bye      # restart GPG agent
```

---

## Git Aliases

Aliases in `~/.gitconfig` under `[alias]`:

```ini
[alias]
    # Compact branch graph
    lg = log --oneline --graph --all --decorate

    # Status shorthand
    st = status -s

    # Undo last commit, keep staged
    undo = reset --soft HEAD~1

    # Show last commit
    last = log -1 HEAD

    # Show all branches with tracking info
    branches = branch -vv --all

    # Amend without editing message
    amend = commit --amend --no-edit

    # Stash including untracked
    save = stash push -u

    # Restore all working tree changes (use carefully)
    discard = restore .

    # Interactive rebase last N commits: git fixup 5
    fixup = "!f() { git rebase -i HEAD~$1; }; f"
```

```bash
git config --global alias.lg "log --oneline --graph --all --decorate"
git config --global alias.st "status -s"
```

---

## Git Hooks

Hooks are scripts in `.git/hooks/` that run automatically at specific points.
They're not committed to the repo (except via hook managers like Husky or pre-commit).

### Hook Types & When They Run

| Hook | Trigger | Common Use |
| --- | --- | --- |
| `pre-commit` | Before commit is created | Lint, format, run tests |
| `prepare-commit-msg` | After message template is generated | Add ticket numbers, formatting |
| `commit-msg` | After message is typed, before commit | Enforce commit message format |
| `post-commit` | After commit is created | Notifications, logging |
| `pre-push` | Before push to remote | Run tests, check branch naming |
| `post-merge` | After merge completes | Install dependencies if package.json changed |
| `pre-rebase` | Before rebase starts | Warn about shared branches |
| `post-checkout` | After checkout/switch | Install deps, update submodules |

### Writing a Hook

```bash
# Create a pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/sh
# Run ESLint on staged JS/TS files
FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(js|ts)$')
if [ -n "$FILES" ]; then
  echo "$FILES" | xargs npx eslint
  if [ $? -ne 0 ]; then
    echo "ESLint failed. Commit aborted."
    exit 1
  fi
fi
EOF
chmod +x .git/hooks/pre-commit
```

```bash
# Enforce conventional commit message format
cat > .git/hooks/commit-msg << 'EOF'
#!/bin/sh
MSG=$(cat "$1")
PATTERN="^(feat|fix|docs|style|refactor|test|chore|ci)(\(.+\))?: .{1,72}"
if ! echo "$MSG" | grep -qE "$PATTERN"; then
  echo "Commit message must match: type(scope): description"
  echo "Example: feat(auth): add JWT middleware"
  exit 1
fi
EOF
chmod +x .git/hooks/commit-msg
```

### Sharing Hooks with a Team

`.git/hooks/` is not committed. Options for sharing:

1. **Store hooks in repo + configure git to use them:**

   ```bash
   mkdir -p .githooks
   # put hooks in .githooks/
   git config --local core.hooksPath .githooks
   ```

2. **Husky** (Node.js projects):

   ```bash
   npx husky init
   # Creates .husky/ directory with managed hooks
   ```

3. **pre-commit** (Python framework, language-agnostic):

   ```yaml
   # .pre-commit-config.yaml
   repos:
     - repo: https://github.com/pre-commit/pre-commit-hooks
       rev: v4.5.0
       hooks:
         - id: trailing-whitespace
         - id: end-of-file-fixer
   ```

### Bypassing Hooks (Use Sparingly)

```bash
git commit --no-verify                  # skip pre-commit + commit-msg hooks
git push --no-verify                    # skip pre-push hook
```

> Only bypass hooks when you understand why the hook is failing and the bypass
> is intentional (e.g., an emergency hotfix). Don't make it a habit.

---

## Credential Helpers

```bash
# View current credential helper
git config credential.helper

# Windows Credential Manager (this machine)
git config --global credential.helper manager

# macOS keychain
git config --global credential.helper osxkeychain

# Linux secret service
git config --global credential.helper /usr/lib/git-core/git-credential-libsecret

# Cache (in-memory, for CI)
git config --global credential.helper 'cache --timeout=3600'

# Azure DevOps path-based authentication (configured on this machine)
git config --global credential.https://dev.azure.com.usehttppath true
```
