# Undoing Changes Reference

Understanding git's three trees is the key to choosing the right undo command:

- **Working tree** — files on disk as you see them
- **Index (staging area)** — snapshot of what will go into the next commit
- **HEAD** — the current commit

---

## The Three Trees Visualized

```text
Working Tree    Index (Stage)    HEAD (last commit)
─────────────   ──────────────   ──────────────────
 your edits  →   git add      →   git commit

 ← git restore    ← git restore --staged
 ← ─────────────── git reset --hard
                  ← git reset --mixed (default)
                                  ← git reset --soft
```

---

## `git restore` — Discard Working Tree or Staged Changes

`git restore` is the modern, safe replacement for `git checkout -- <file>`.
It only touches files, never moves HEAD.

```bash
# Discard unstaged changes to a file (restore from index/stage)
git restore <file>
git restore .                           # discard all unstaged changes

# Unstage a file (move from index back to working tree, keep changes)
git restore --staged <file>
git restore --staged .                  # unstage everything

# Discard changes AND unstage (restore from HEAD)
git restore --source=HEAD --staged --worktree <file>

# Restore a file from a specific commit or branch
git restore --source=<sha> <file>
git restore --source=HEAD~2 src/auth.ts
```

> ⚠️ `git restore <file>` permanently discards your working tree changes for that
> file. There is no undo. If unsure, stash first: `git stash push <file>`.

---

## `git reset` — Move HEAD (and optionally Index/Working Tree)

`git reset` moves the current branch's HEAD pointer. The `--soft`, `--mixed`, and
`--hard` flags control how far the reset reaches.

```bash
# ── Soft: move HEAD only ────────────────────────────────────────────────────
# Commits are "undone" but changes remain staged (in the index)
git reset --soft HEAD~1                 # undo last commit, keep staged
git reset --soft HEAD~3                 # undo last 3 commits, all changes staged

# When to use: you want to recommit with a different message, or combine commits

# ── Mixed: move HEAD + reset index (default) ────────────────────────────────
# Commits are undone and changes are unstaged (in working tree)
git reset HEAD~1                        # same as: git reset --mixed HEAD~1
git reset HEAD~3

# When to use: you want to unstage commits and re-stage selectively

# ── Hard: move HEAD + reset index + reset working tree ────────────────────
# Commits are undone AND working tree changes are discarded ⚠️
git reset --hard HEAD~1
git reset --hard <sha>
git reset --hard origin/main            # match exactly what's on remote

# When to use: you want to completely throw away commits AND their changes
# Recovery: still possible via reflog within 90 days
```

**Relative commit notation:**

```text
HEAD       = current commit
HEAD~1     = one commit back (parent)
HEAD~3     = three commits back
HEAD^      = first parent (same as HEAD~1)
HEAD^2     = second parent (for merge commits)
<sha>      = specific commit
```

---

## `git revert` — Safe Undo for Shared Branches

`git revert` creates a **new commit** that undoes the changes of a previous commit.
Unlike `reset`, it does not rewrite history — making it safe to use on branches
others have pulled.

```bash
git revert HEAD                         # revert last commit (opens editor for message)
git revert HEAD --no-edit               # revert last commit, use auto-generated message
git revert <sha>                        # revert a specific commit
git revert <sha1>..<sha2>              # revert a range (sha1 exclusive)
git revert --no-commit <sha>            # stage revert changes without committing
git revert -m 1 <merge-sha>            # revert a merge commit (1 = keep first parent)

# Revert multiple commits without individual commits (then commit once)
git revert --no-commit HEAD~3..HEAD
git commit -m "revert: undo last 3 commits"
```

**Choosing between reset and revert:**

| Situation | Use |
| --- | --- |
| Undo commits on a **private** branch | `git reset` (clean history) |
| Undo commits on a **shared** branch | `git revert` (safe, non-destructive) |
| Remove a specific old commit from history | `git revert <sha>` |
| Remove a merge commit | `git revert -m 1 <merge-sha>` |

---

## `git clean` — Remove Untracked Files

`git clean` removes files from the working tree that are not tracked by git.
**Always run `--dry-run` first.**

```bash
git clean -n                            # dry run — preview what would be deleted
git clean -f                            # force: delete untracked files
git clean -fd                           # force: delete untracked files + directories
git clean -fX                           # force: delete only .gitignore'd files
git clean -fx                           # force: delete ALL untracked (including ignored)
git clean -i                            # interactive mode — review each file

# Combined with restore for full "pristine" reset:
git restore .                           # discard tracked file changes
git clean -fd                           # remove all untracked
```

> ⚠️ `git clean -fd` cannot be undone. Files are permanently deleted (not moved to
> Recycle Bin). Always run `-n` first.

---

## Recovery Patterns

### Recover "Lost" Commits After Reset

Commits that were moved past by `reset --hard` are still in the object database
for 90 days. Find them with `reflog`:

```bash
git reflog                              # find the SHA of the commit you want
git reset --hard <sha>                  # restore the branch to that commit
# or:
git cherry-pick <sha>                   # selectively apply the lost commit
```

### Recover a Deleted Branch

```bash
git reflog | grep "moving from"         # find when the branch tip was HEAD
# or:
git reflog --all | grep <branch-name>
git switch -c <branch-name> <sha>       # recreate branch at recovered SHA
```

### Recover a Specific File from History

```bash
# Restore a deleted file from a specific commit
git restore --source=<sha> -- path/to/file.ts
# or:
git checkout <sha> -- path/to/file.ts   # older syntax, same effect

# Find which commit deleted the file
git log --all --full-history -- path/to/file.ts
```

### Undo a `git revert`

```bash
# Revert the revert (creates a new commit re-applying the original change)
git revert <sha-of-the-revert-commit>
```

### Undo an Accidental Merge

```bash
# If the merge commit hasn't been pushed:
git reset --hard HEAD~1                 # undo the merge commit

# If already pushed (shared branch):
git revert -m 1 <merge-sha>            # create a revert commit
```

---

## Amendment (Edit Last Commit)

```bash
git commit --amend                      # edit message + content of last commit
git commit --amend --no-edit            # add staged changes to last commit silently
git commit --amend --author="Name <email>"

# Then force-push to update remote (only for your own feature branches)
git push --force-with-lease
```

> ⚠️ `--amend` rewrites the last commit (new SHA). Never amend commits that others
> have pulled.
