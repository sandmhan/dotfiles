# Stash & Worktrees Reference

Both stash and worktrees solve the same fundamental problem — you're in the middle
of something and need to switch context. They approach it differently:

- **Stash** — saves your WIP to a stack, cleans the working tree, lets you switch
  branches, then pops it back. One working tree at a time.
- **Worktree** — checks out a second branch into a separate directory, so you can
  work on both simultaneously. No stashing needed.

---

## `git stash`

### Saving & Restoring

```bash
git stash                               # stash tracked changes (staged + unstaged)
git stash push                          # same as above (explicit form)
git stash push -m "WIP: auth refactor"  # stash with a description
git stash push -u                       # include untracked files
git stash push -a                       # include untracked + ignored files
git stash push -p                       # interactive patch — stash only selected hunks
git stash push --keep-index             # stash only unstaged changes (leave staged)
git stash push -- path/to/file.ts       # stash only specific files

git stash list                          # show all stashes
# Output: stash@{0}: WIP on feature/auth: abc1234 last commit message
#         stash@{1}: WIP on main: def5678 ...

git stash pop                           # apply most recent stash + remove from stack
git stash pop stash@{2}                 # apply specific stash + remove from stack
git stash apply                         # apply most recent stash, KEEP in stack
git stash apply stash@{1}               # apply specific stash, keep in stack
```

### Inspecting Stashes

```bash
git stash show                          # summary of most recent stash
git stash show -p                       # full diff of most recent stash
git stash show stash@{1}                # summary of specific stash
git stash show -p stash@{1}             # full diff of specific stash
```

### Managing the Stack

```bash
git stash drop                          # delete most recent stash
git stash drop stash@{2}                # delete specific stash
git stash clear                         # delete all stashes ⚠️ irreversible

# Create a branch from a stash (useful if stash conflicts on current branch)
git stash branch <new-branch> stash@{0}
# = creates branch at the commit where the stash was made, applies stash, drops stash
```

### Partial Stash Workflow

```bash
# Stash only unstaged changes (keep staged ones ready to commit)
git stash push --keep-index

# Stash work-in-progress, commit the ready changes, restore WIP
git stash
git commit -m "feat: partial feature"
git stash pop
```

---

## `git worktree`

A worktree lets you check out a branch into a separate directory while keeping your
main working tree untouched. Both are linked to the same repository — they share
commits, refs, and objects.

### Creating Worktrees

```bash
# Add a worktree for a branch in a new directory
git worktree add ../hotfix hotfix/v1.2.1
# Now ../hotfix has the hotfix branch checked out

# Create a new branch and worktree at the same time
git worktree add -b hotfix/v1.2.1 ../hotfix main

# Detached HEAD worktree (to inspect a specific commit without a branch)
git worktree add --detach ../inspect <sha>

# Worktrees can be relative or absolute paths
git worktree add /tmp/review-pr feature/user-auth
```

### Listing & Managing

```bash
git worktree list                       # list all worktrees
git worktree list --porcelain           # machine-readable format

# Output:
# worktree /path/to/main
# HEAD abc1234
# branch refs/heads/main
#
# worktree /path/to/../hotfix
# HEAD def5678
# branch refs/heads/hotfix/v1.2.1
```

### Locking, Moving, Removing

```bash
git worktree lock ../hotfix             # prevent auto-prune (e.g., on external drive)
git worktree lock --reason "external disk" ../hotfix
git worktree unlock ../hotfix

git worktree move ../hotfix ../hotfix-new   # move worktree to new path
git worktree remove ../hotfix           # remove worktree directory + unlink from repo
git worktree prune                      # remove stale worktree metadata (when dir was manually deleted)
git worktree repair                     # fix worktree links after manual directory moves
```

### Typical Worktree Use Cases

**Hotfix while feature branch is dirty:**

```bash
# You're deep in a feature, don't want to stash/restore
git worktree add ../hotfix -b hotfix/null-crash main

# In a separate terminal:
cd ../hotfix
# Fix the bug, commit, push
git commit -m "fix: null crash in session"
git push origin hotfix/null-crash

# Back in main working tree — nothing disturbed
cd ../main-repo
git fetch --prune
```

**Reviewing a PR without losing your place:**

```bash
git worktree add ../review-pr-123 origin/feature/pr-123
cd ../review-pr-123
# Test the PR, run tests, leave comments
cd ../main-repo
git worktree remove ../review-pr-123
```

**Building multiple versions simultaneously:**

```bash
git worktree add ../build-v1 v1.0.0
git worktree add ../build-v2 v2.0.0
# Build both in parallel in separate terminals
```

### Worktree Constraints

- A branch can only be checked out in **one** worktree at a time. Attempting to
  add a second worktree for the same branch fails with an error.
- Use `--detach` if you need to inspect the same commit from multiple directories.
- Worktrees share the same `.git` directory — they see the same refs, stashes,
  and object database.

---

## Stash vs Worktree Decision Guide

| Need | Use |
| --- | --- |
| Quick context switch, same branch later | `git stash` |
| Switch to an unrelated branch briefly | `git stash` |
| Work on two branches simultaneously | `git worktree` |
| Hotfix while feature is in progress | `git worktree` (safer — no stash/pop risk) |
| Review a PR without changing your tree | `git worktree` |
| WIP is complex and stash conflicts likely | `git worktree` |
| Need to keep specific files uncommitted | `git stash push -- <files>` |
