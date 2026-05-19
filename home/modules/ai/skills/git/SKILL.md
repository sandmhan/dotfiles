---
name: git
description: >
  Use this skill for ANY git-related task: committing, branching, merging, rebasing,
  pushing/pulling, resolving merge conflicts, interactive rebase, cherry-pick, stash,
  worktree, bisect, reflog recovery, submodules, git-lfs large file management,
  git flow branching workflow (feature/release/hotfix branches), GPG-signed commits,
  hooks, gitconfig, .gitattributes, and troubleshooting any git error or confusing
  behavior. Trigger whenever the user mentions git, commits, branches, merging,
  rebasing, pull requests, history rewriting, "my repo", git lfs, git flow, or any
  git subcommand — even casually ("I messed up a commit", "how do I undo this",
  "what's the difference between merge and rebase"). Also trigger for .gitignore
  authoring, repository hygiene (gc, prune, reflog), and anything involving version
  control workflows across Linux, macOS, and Windows (Git Bash / MINGW64) environments.
---

# Git Skill

Handle all git-related work with this skill — from quick one-liners to complex history
rewrites, multi-branch workflows, LFS migrations, and team branching strategies.

---

## Reference Files

Load the relevant reference file when you need depth on a specific domain. For simple
queries the inline quick reference below is usually sufficient.

| Topic | File | Load when... |
| --- | --- | --- |
| Install & setup | `references/install-and-setup.md` | User needs to install git or do initial configuration |
| Basics — init, clone, add, commit, diff | `references/basics.md` | init/clone/add/commit/diff/status/.gitignore questions |
| Branching & merging | `references/branching.md` | branch/switch/merge/tag/checkout/--no-ff questions |
| Remotes — fetch, pull, push | `references/remotes.md` | remote/fetch/pull/push/force/origin/upstream/refspec questions |
| Rebase & cherry-pick | `references/rebase.md` | rebase/cherry-pick/squash/rebase -i/fixup/rerere questions |
| History — log, blame, bisect | `references/history.md` | log/blame/bisect/grep/describe/reflog questions |
| Undoing changes | `references/undoing.md` | reset/restore/revert/clean/undo/recover questions |
| Stash & worktrees | `references/stash-worktree.md` | stash/worktree/WIP/parallel branch questions |
| Git Flow workflow | `references/gitflow.md` | git flow/feature branch/release/hotfix/gitflow questions |
| Git LFS | `references/lfs.md` | lfs/large file/binary/track/migrate/lock questions |
| Submodules | `references/submodules.md` | submodule/nested repo/superproject questions |
| Config, hooks & GPG | `references/hooks-config.md` | config/hooks/alias/GPG/sign/.gitattributes/autocrlf questions |
| Troubleshooting | `references/troubleshooting.md` | conflict/detached HEAD/CRLF/error/recovery/broke questions; Win32 error 5/sh.exe fatal errors on Windows |

---

## Quick Command Reference

These cover ~80% of daily git use. For deeper options, load the relevant reference file.

```bash
# ── Snapshot & inspect ─────────────────────────────────────────────────────
git status                          # what's staged, unstaged, untracked
git diff                            # unstaged changes
git diff --staged                   # staged changes (what will be committed)
git log --oneline --graph --all     # visual branch history

# ── Staging & committing ───────────────────────────────────────────────────
git add -p                          # interactive patch staging (review each hunk)
git add <file>                      # stage specific file
git commit -m "feat: add login"     # commit with message
git commit                          # open configured editor to write full commit message
# If commit.gpgsign=true, all commits are signed automatically

# ── Branching ──────────────────────────────────────────────────────────────
git switch -c feature/my-thing      # create + switch (preferred over checkout -b)
git switch main                     # switch to existing branch
git branch -vv                      # list branches with tracking info
git merge --no-ff feature/my-thing  # merge with explicit merge commit (preserve history)
git branch -d feature/my-thing      # delete merged branch

# ── Remote sync ────────────────────────────────────────────────────────────
git fetch --prune                   # fetch + remove stale remote-tracking refs
git pull                            # fetch + merge (behavior depends on pull.rebase config)
git push -u origin feature/my-thing # push + set upstream
git push --force-with-lease         # safe force-push (fails if remote moved unexpectedly)
# Never use bare `git push --force` on a shared branch

# ── Rebase ─────────────────────────────────────────────────────────────────
git rebase main                     # rebase current branch onto main
git rebase -i HEAD~3                # interactive rebase last 3 commits
# ⚠️  Never rebase commits already pushed to a shared branch

# ── Undoing ────────────────────────────────────────────────────────────────
git restore <file>                  # discard working tree changes for a file
git restore --staged <file>         # unstage a file (keep changes in working tree)
git reset --soft HEAD~1             # undo last commit, keep staged
git reset --mixed HEAD~1            # undo last commit, unstage (default)
git reset --hard HEAD~1             # undo last commit + discard changes (destructive)
git revert HEAD                     # safe undo on shared branch (creates new commit)

# ── Recovery ───────────────────────────────────────────────────────────────
git reflog                          # find "lost" commits after reset/rebase
git stash                           # shelve WIP to switch branches quickly
```

---

## Workflow Patterns

### Feature Branch Workflow

```bash
# Start a feature
git switch main && git fetch --prune && git pull
git switch -c feature/user-auth

# Work, commit regularly
git add -p
git commit -m "feat(auth): add JWT middleware"

# Push and open a PR
git push -u origin feature/user-auth

# Merge (on main, after PR approval)
git switch main && git pull
git merge --no-ff feature/user-auth -m "Merge feature/user-auth into main"
git push
git branch -d feature/user-auth
git push origin --delete feature/user-auth
```

### Interactive Rebase — Squash Before Merge

```bash
# Squash last 4 WIP commits into one clean commit
git rebase -i HEAD~4
# In the editor: keep first as 'pick', change others to 'fixup' or 'squash'
# After save, force-push (safe because branch is yours only)
git push --force-with-lease

# Alternative: use fixup commits from the start
git commit --fixup=HEAD~1           # marks a commit to be squashed into its target
git rebase -i --autosquash HEAD~5   # autosquash orders fixup commits automatically
```

### Hotfix Workflow (Manual, Without git-flow)

```bash
# Production is broken — branch from the release tag
git switch main && git pull
git switch -c hotfix/fix-null-crash

# Fix, commit, tag
git commit -m "fix: handle null user in session"
git switch main && git merge --no-ff hotfix/fix-null-crash
git tag -a v1.2.1 -m "Hotfix: null crash in session handler"
git push && git push --tags

# Back-merge to develop so the fix is in the next release
git switch develop && git merge --no-ff hotfix/fix-null-crash
git push
git branch -d hotfix/fix-null-crash
```

---

## Safety Rules

Always verify before running destructive operations. Suggest the safe alternative first.

| Command | Risk | Action |
| --- | --- | --- |
| `git reset --hard` | Discards all working tree + staged changes | Confirm explicitly; suggest `git stash` first |
| `git push --force` | Overwrites remote history | **Never suggest bare `--force`** — use `--force-with-lease` |
| `git branch -D` | Deletes branch without merge check | Confirm branch is merged or intentionally abandoned |
| `git clean -fd` | Permanently deletes untracked files | Always run `--dry-run` first to preview |
| `git filter-branch` / `filter-repo` | Rewrites all history (new SHAs) | Warn: team must force-push + all collaborators re-clone |
| `git lfs migrate` | Rewrites history | Same as filter-branch — coordinate with whole team |
| `git rebase <shared branch>` | Rewrites commits already on remote | Warn: breaks others' local repos |

---

## Platform Notes

### Windows / Git Bash (MINGW64)

- **Line endings**: `core.autocrlf=true` — Git converts LF→CRLF on checkout, CRLF→LF on commit. Fine for Windows-only repos; may cause spurious diffs in cross-platform teams. Fix per-repo with `.gitattributes`.
- **Symlinks**: `core.symlinks=false` by default on Windows — symlinks appear as plain text files. Enable with admin rights + `git config core.symlinks true`.
- **GPG signing**: If `commit.gpgsign=true` is set globally, all commits are signed automatically. Use `git log --show-signature` to verify.
- **Editor**: Set with `git config --global core.editor`. VS Code: `code --wait`.
- **Credential helper**: Windows Credential Manager (`manager`). Azure DevOps repos need `credential.https://dev.azure.com.usehttppath=true`.
- **Default branch**: Set `git config --global init.defaultBranch main` for new repos.

### Linux / macOS

- **Line endings**: `core.autocrlf=false` is typical; use `.gitattributes` to enforce consistent endings across platforms.
- **Credential helper**: `git-credential-store`, `git-credential-cache`, or OS keychain helpers.
- **GPG signing**: Install gpg, generate key, and configure `git config --global user.signingkey <keyid>`.
- **Default branch**: `git config --global init.defaultBranch main`.
