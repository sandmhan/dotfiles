# Branching & Merging Reference

---

## Creating and Switching Branches

Prefer `git switch` over `git checkout` for branch operations — `checkout` is overloaded
(it also manipulates files), while `switch` is unambiguous.

```bash
git switch <branch>                 # switch to existing branch
git switch -c <new-branch>          # create + switch (= git checkout -b)
git switch -c <branch> <start>      # create from a specific commit/tag/branch
git switch -                        # switch back to previous branch
git switch --detach <sha>           # detach HEAD at a specific commit (read-only explore)

# Legacy (still valid, widely used)
git checkout <branch>
git checkout -b <new-branch>
git checkout -b <branch> origin/<branch>  # create local tracking branch from remote
```

---

## Listing and Managing Branches

```bash
git branch                          # list local branches
git branch -a                       # list local + remote-tracking branches
git branch -v                       # with last commit summary
git branch -vv                      # with tracking info and ahead/behind counts
git branch --merged                 # branches already merged into HEAD (safe to delete)
git branch --no-merged              # branches NOT yet merged

git branch -m <old> <new>           # rename branch
git branch -m <new>                 # rename current branch
git branch -d <branch>              # delete (only if merged)
git branch -D <branch>              # force delete (even if unmerged) ⚠️ confirm first
git branch --set-upstream-to=origin/<branch>  # set upstream for current branch
git branch -u origin/<branch>       # shorthand for set-upstream-to
git branch --unset-upstream         # remove upstream association
```

---

## Merging

### Merge Strategies

```bash
git merge <branch>                  # merge branch into current (fast-forward if possible)
git merge --no-ff <branch>          # always create a merge commit (recommended for features)
git merge --squash <branch>         # squash all branch commits into staged changes (then commit manually)
git merge --ff-only <branch>        # merge only if fast-forward is possible, else abort

git merge --abort                   # abort in-progress merge (restore pre-merge state)
git merge --continue                # continue after resolving conflicts
git merge --quit                    # abort but keep working tree changes
```

### Why `--no-ff` Matters

Fast-forward merges lose the fact that a feature branch existed — the commits appear
as if they were all made directly on main. Using `--no-ff` creates an explicit merge
commit that:

- Preserves the branch topology in `git log --graph`
- Makes it easy to revert an entire feature with `git revert -m 1 <merge-commit>`
- Shows when a feature was integrated, not just when each commit was made

```text
Fast-forward:    A──B──C──D──E       (no record of feature/auth branch)
--no-ff:         A──B─────────E      (merge commit E references D)
                      \──C──D/
```

### Merge Strategies (advanced)

```bash
git merge -s ort <branch>           # default strategy (Ostensibly Recursive's Twin)
git merge -s recursive <branch>     # older default (pre-2.34)
git merge -s octopus <branch1> <branch2>  # merge multiple branches at once
git merge -X ours <branch>          # on conflict: prefer our side automatically
git merge -X theirs <branch>        # on conflict: prefer their side automatically
git merge -X ignore-space-change <branch>
```

### Conflict Resolution

When a merge hits a conflict:

```bash
git status                          # see which files have conflicts
# Edit conflicted files — resolve <<<<< / ===== / >>>>> markers
git add <resolved-file>             # mark as resolved
git merge --continue                # commit the merge
```

Open in mergetool (uses VS Code on this machine):

```bash
git mergetool                       # open all conflicted files in configured tool
git mergetool <file>                # open specific file
```

See `references/troubleshooting.md` for detailed conflict resolution patterns.

---

## Rebasing vs Merging

| | Merge (`--no-ff`) | Rebase |
| --- | --- | --- |
| History | Preserves exact timeline + topology | Rewrites commits to be linear |
| Merge commit | Yes | No |
| Safe on shared branches | Yes | **No** |
| Good for | Feature integration into main | Keeping a feature branch up to date with main |
| Bisect-friendliness | Medium (merge commits add noise) | High (linear history) |

The golden rule: **never rebase commits that have been pushed to a shared branch.**

See `references/rebase.md` for full rebase documentation.

---

## Branch Naming Conventions

Recommended patterns (compatible with git-flow prefixes):

| Purpose | Pattern | Example |
| --- | --- | --- |
| Feature | `feature/<short-description>` | `feature/user-auth` |
| Bug fix | `fix/<issue-or-description>` | `fix/null-session-crash` |
| Hotfix | `hotfix/<version>` | `hotfix/v1.2.1` |
| Release | `release/<version>` | `release/v2.0.0` |
| Chore | `chore/<description>` | `chore/update-deps` |
| Experiment | `experiment/<description>` | `experiment/ai-search` |

Tips:

- Use lowercase, hyphens (not underscores or spaces)
- Keep it short but descriptive
- Include ticket/issue number if relevant: `feature/PROJ-123-login-page`

---

## Cherry-Pick

> Prefer cherry-pick when you need one specific commit from another branch,
> not the whole branch history.

See `references/rebase.md` for full cherry-pick documentation.

```bash
git cherry-pick <sha>               # apply a commit onto current branch
git cherry-pick <sha1>..<sha2>      # apply a range (excludes sha1, includes sha2)
git cherry-pick <sha1>^..<sha2>     # apply a range (includes sha1)
git cherry-pick --no-commit <sha>   # apply changes without committing (stage only)
git cherry-pick --abort             # abort in-progress cherry-pick
```
