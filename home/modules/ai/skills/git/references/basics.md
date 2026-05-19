# Git Basics Reference

---

## Starting a Repository

```bash
git init                            # initialize new repo in current directory
git init <dir>                      # create and initialize <dir>
git init --initial-branch=main      # set default branch name (or configure globally)

git clone <url>                     # clone into directory named from URL
git clone <url> <dir>               # clone into specific directory
git clone --depth=1 <url>           # shallow clone (last commit only) — fast for CI
git clone --branch <branch> <url>   # clone and check out specific branch
git clone --filter=blob:none <url>  # partial clone (blobs fetched on demand) — huge repos
git clone --recurse-submodules <url> # clone + initialize all submodules
```

---

## Working Tree Status

```bash
git status                  # full status with hints
git status -s               # short format: XY filename (X=staged, Y=unstaged)
git status --porcelain      # machine-readable short format
```

**Status flags (short format):**

| Code | Meaning |
| --- | --- |
| `M` | Modified and staged |
| `M` | Modified, not staged |
| `A` | New file, staged |
| `??` | Untracked file |
| `D` | Deleted, staged |
| `UU` | Merge conflict |

---

## Staging Changes

```bash
git add <file>              # stage specific file
git add <dir>/              # stage all changes in directory
git add -A                  # stage all changes (new + modified + deleted)
git add -u                  # stage modified + deleted (not new untracked)
git add -p                  # interactive patch mode — review and stage individual hunks
git add -i                  # fully interactive staging menu
```

**Patch mode (`-p`) commands:** `y` accept, `n` skip, `s` split hunk, `e` edit hunk manually, `?` help.

```bash
git restore --staged <file> # unstage a file (keep working tree change)
git restore --staged .      # unstage everything
```

---

## Diffing

```bash
git diff                            # unstaged changes vs index
git diff --staged                   # staged changes vs HEAD (what will be committed)
git diff HEAD                       # all changes (staged + unstaged) vs HEAD
git diff <branch>                   # working tree vs another branch
git diff <commit>..<commit>         # between two commits
git diff --stat                     # summary of changed files + line counts
git diff --word-diff                # highlight changed words (not full lines)
git diff --ignore-space-change      # ignore whitespace-only changes
```

---

## Committing

```bash
git commit -m "feat: add login"         # commit with inline message
git commit                              # open editor (VS Code on this machine)
git commit -a -m "fix: typo"            # stage all tracked + commit in one step
git commit --amend                      # edit the last commit (message and/or content)
git commit --amend --no-edit            # amend without changing message
git commit --allow-empty -m "trigger"   # commit with no changes (useful for CI triggers)

# Fixup commits — for use with rebase -i --autosquash
git commit --fixup=HEAD                 # marks this commit to be squashed into HEAD
git commit --fixup=<sha>                # marks to be squashed into specified commit
git commit --squash=<sha>               # like fixup but prompts to edit message

# Author & date overrides
git commit --author="Name <email>"
git commit --date="2025-01-15T10:00:00"
git commit --reset-author               # reset author to current configured identity

# GPG signing (already globally enabled via commit.gpgsign=true)
git commit -S                           # explicitly GPG-sign this commit
git commit --no-gpg-sign               # override: commit without GPG signature
```

**Conventional commit prefixes** (widely used standard):

- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation only
- `refactor:` no functional change
- `chore:` build/tooling/deps
- `test:` adding tests
- `ci:` CI configuration

---

## Viewing History

```bash
git log                             # full commit log
git log --oneline                   # compact: SHA + first line
git log --oneline --graph --all     # visual branch graph (most useful default)
git log -p                          # log + full diff per commit
git log -p --follow <file>          # file history including renames
git log --stat                      # log + file-level change summary
git log --shortstat                 # log + summary line per commit
git log -<n>                        # show last n commits
git log <branch>                    # log for another branch
git log main..feature               # commits on feature not in main
git log --since="2 weeks ago"
git log --author="Alison"
git log --grep="fix: null"          # search commit messages
git log -S "functionName"           # pickaxe: commits that added/removed this string
git log -G "regex"                  # commits where diff matches regex
```

**Custom format examples:**

```bash
git log --format="%h %ad %s" --date=short   # hash, date, subject
git log --format="%C(yellow)%h%Creset %s %C(blue)(%ar)%Creset"  # colored
```

---

## .gitignore

Patterns use gitignore rules:

```gitignore
# Exact file
secret.env

# All files with extension
*.log
*.pyc

# Directory (trailing slash)
node_modules/
dist/
.venv/

# Negate (re-include after ignoring)
!important.log

# Only in root
/config.local.json

# Any depth
**/tmp/
```

```bash
git check-ignore -v <file>          # explain why a file is ignored
git ls-files --others --ignored --exclude-standard  # list all ignored files
git rm --cached <file>              # stop tracking a file (leave it on disk)
```

Global ignore file: `~/.gitignore_global` — configure with:

```bash
git config --global core.excludesfile ~/.gitignore_global
```

---

## Tagging

```bash
git tag                             # list all tags
git tag v1.0.0                      # lightweight tag at HEAD
git tag -a v1.0.0 -m "Release"      # annotated tag (recommended; stores tagger + date)
git tag -s v1.0.0 -m "Release"      # GPG-signed annotated tag
git tag -a v1.0.0 <sha>             # tag specific commit
git push origin v1.0.0              # push a single tag
git push origin --tags              # push all tags
git tag -d v1.0.0                   # delete local tag
git push origin --delete v1.0.0     # delete remote tag
git show v1.0.0                     # show tag details + commit
```
