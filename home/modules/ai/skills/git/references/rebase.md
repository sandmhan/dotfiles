# Rebase & Cherry-Pick Reference

---

## Rebase vs Merge — When to Use Each

| Situation | Use |
| --- | --- |
| Integrating a finished feature into main | `merge --no-ff` (preserves merge topology) |
| Keeping a feature branch up to date with main | `rebase main` (stay linear, avoid merge commits) |
| Cleaning up messy WIP commits before a PR | `rebase -i HEAD~N` (squash/fixup) |
| Applying one specific commit from another branch | `cherry-pick <sha>` |
| Publishing history (shared branch) | **Never rebase** — use merge |

> ⚠️ **The golden rule:** Never rebase commits that have already been pushed to a
> branch others are using. Rebase rewrites commit SHAs — anyone else with those
> commits will have diverged history and will need to hard-reset or re-clone.

---

## Basic Rebase

```bash
# Update feature branch with latest main (clean, no merge commits)
git switch feature/my-thing
git fetch origin
git rebase origin/main

# Equivalent to: replay all commits on feature/my-thing on top of latest main

# On conflict:
git status                      # see which files need resolution
# Edit files, then:
git add <resolved-files>
git rebase --continue           # proceed to next commit
git rebase --skip               # skip current commit (use when patch is already applied)
git rebase --abort              # abandon rebase, restore original branch state
```

---

## Interactive Rebase (`rebase -i`)

Interactive rebase lets you edit, reorder, squash, delete, or reword commits before
they land. This is the cleanest way to polish a branch before merging.

```bash
git rebase -i HEAD~4            # interactively edit the last 4 commits
git rebase -i <sha>             # edit commits after <sha> (not including it)
git rebase -i origin/main       # edit all commits not yet in origin/main
```

**The editor opens with a list like:**

```text
pick abc1234 feat: initial login form
pick def5678 wip: debugging
pick ghi9012 wip: more debugging
pick jkl3456 fix: null check

# Commands:
# p, pick   = use commit as-is
# r, reword = use commit, edit message
# e, edit   = use commit, pause to amend (then rebase --continue)
# s, squash = meld into previous commit (opens editor to merge messages)
# f, fixup  = meld into previous commit, discard this message
# d, drop   = remove commit entirely
# x, exec   = run shell command after this commit
```

**Common transforms:**

```text
# Squash 3 WIP commits into the first:
pick abc1234 feat: initial login form
fixup def5678 wip: debugging
fixup ghi9012 wip: more debugging
pick jkl3456 fix: null check

# Reorder commits (just move lines)
# Delete a commit (change pick to drop, or delete the line)
# Rename a commit message (change pick to reword)
```

After saving, git replays commits in order. Resolve any conflicts that arise, then
`git rebase --continue`.

---

## Autosquash Workflow

Instead of manually changing `pick` to `fixup` in the editor, use fixup commits
from the start:

```bash
# Make your main commit
git commit -m "feat: add user login"

# Later, realize you need to fix something in that commit
git add <files>
git commit --fixup=HEAD                 # or: --fixup=<sha> for an older commit

# When ready to clean up, autosquash automatically orders fixup commits:
git rebase -i --autosquash HEAD~5

# Configure it globally so you never need the flag:
git config --global rebase.autoSquash true
```

---

## Rebase --onto (Range Rebase)

Rebase a range of commits from one base to another. Useful when you accidentally
branched off the wrong branch.

```bash
# Scenario: feature was accidentally branched from old-base, should be on main
git rebase --onto main old-base feature

# Syntax: git rebase --onto <new-base> <old-base> <branch>
# = "take commits that are in feature but not in old-base, apply them onto main"

# Example: extract last 3 commits of a branch and replay on main
git rebase --onto main HEAD~3 HEAD
```

---

## Rebase with Signing

GPG signing is enabled globally on this machine (`commit.gpgsign=true`). When you
rebase, new commits are created — they will be GPG-signed automatically if signing
is configured. No extra flags needed.

```bash
# Verify signing after rebase
git log --show-signature -3
```

---

## Rerere (Reuse Recorded Resolution)

When you resolve the same conflict multiple times (e.g., during long-running rebases
or repeated merges), `rerere` records the resolution and replays it automatically.

```bash
git config --global rerere.enabled true     # enable globally
git config --global rerere.autoUpdate true  # auto-stage after replaying resolution

# When a conflict is auto-resolved from a recorded resolution:
# git status shows: "Resolved <file> using previous resolution."
# Review the auto-resolution, then: git rebase --continue

git rerere                          # show rerere status
git rerere diff                     # show what rerere would apply
git rerere forget <file>            # discard a recorded resolution
```

---

## Cherry-Pick

Cherry-pick applies the changes introduced by specific commits to your current branch.
It creates a **new commit** with a new SHA — it does not move or remove the original.

```bash
git cherry-pick <sha>               # apply one commit
git cherry-pick <sha1> <sha2>       # apply multiple commits (in order)
git cherry-pick <sha1>..<sha2>      # apply range: sha1 is excluded, sha2 is included
git cherry-pick <sha1>^..<sha2>     # apply range: both sha1 and sha2 included

git cherry-pick --no-commit <sha>   # apply changes but don't commit (stage only)
git cherry-pick -e <sha>            # apply + open editor to edit message
git cherry-pick -x <sha>            # append "(cherry picked from <sha>)" to message (useful for tracking)
git cherry-pick -m 1 <merge-sha>    # cherry-pick from a merge commit (1 = first parent)

# Handling conflicts
git cherry-pick --continue          # after resolving conflicts
git cherry-pick --skip              # skip current commit in multi-pick
git cherry-pick --abort             # abandon the entire cherry-pick
git cherry-pick --quit              # stop but keep changes applied so far
```

**When to use cherry-pick:**

- Backporting a bug fix to a release/maintenance branch
- Applying a one-off commit from a colleague's branch you don't want to merge fully
- Recovering a commit accidentally made on the wrong branch

**When NOT to use cherry-pick:**

- When you want all commits from a branch — use merge or rebase instead
- Repeatedly cherry-picking between long-lived diverging branches creates duplicate commits

---

## Range-Diff — Comparing Rebase Results

`git range-diff` shows what changed between two versions of a patch series — useful
for reviewing what an interactive rebase actually did.

```bash
# Compare HEAD~3..HEAD vs origin/feature (before and after rebase)
git range-diff origin/main HEAD~3 HEAD

# See what changed in a PR after force-push
git range-diff <old-base>..<old-tip> <new-base>..<new-tip>
```

---

## Common Mistakes & Recovery

**Rebase went wrong — too many conflicts, want to bail:**

```bash
git rebase --abort          # restores branch to state before rebase started
```

**Already completed a bad rebase and pushed:**

```bash
# Find the pre-rebase tip in the reflog
git reflog | head -20       # look for entries before the rebase started
git reset --hard <sha>      # restore to pre-rebase state
git push --force-with-lease # update remote (coordinate with team first)
```

**Accidentally rebased a shared branch:**

```bash
# Every collaborator needs to do this after you force-push:
git fetch origin
git reset --hard origin/<branch>    # discard their local rebase-diverged history
```
