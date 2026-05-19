# Submodules Reference

A git submodule is a repository embedded inside another repository. The outer
repository (superproject) stores a pointer (commit SHA) to a specific commit in
the inner repository (submodule) — not the submodule's files directly.

---

## When to Use Submodules

Good fit:

- Shared libraries that are versioned and changed independently
- Third-party code where you want to track a specific commit/version
- Monorepo-adjacent setups where separate teams own separate repos

Less ideal alternatives to consider first:

- **npm/pip/cargo/etc.** — better for language-ecosystem dependencies
- **git subtree** — simpler if you don't need independent history
- **package registries** — for distributable libraries

---

## Adding a Submodule

```bash
git submodule add <url> <path>
# Example:
git submodule add https://github.com/org/shared-lib.git libs/shared

# After adding, two things change:
# 1. A .gitmodules file is created (or appended to)
# 2. A new staged entry appears for libs/shared (the pointer commit)

git status
# Changes to be committed:
#   new file: .gitmodules
#   new file: libs/shared       ← this is the commit pointer, not the files

git commit -m "chore: add shared-lib submodule"
```

**.gitmodules file:**

```ini
[submodule "libs/shared"]
    path = libs/shared
    url = https://github.com/org/shared-lib.git
    branch = main               # optional: track a specific branch
```

---

## Cloning with Submodules

```bash
# Clone and initialize all submodules in one step (recommended)
git clone --recurse-submodules <url>

# If you cloned without --recurse-submodules:
git submodule init                      # register submodules from .gitmodules
git submodule update                    # check out the recorded commit in each
# Combined:
git submodule update --init
git submodule update --init --recursive # for nested submodules
```

---

## Updating Submodules

### Updating to the Superproject's Recorded Commit

This is the default behavior — bring the submodule to what the superproject says:

```bash
git submodule update                    # update all to their recorded commit
git submodule update libs/shared        # update specific submodule only
git submodule update --init --recursive # init + update all levels
```

### Updating to Latest Remote Commit

```bash
git submodule update --remote           # fetch + update to latest on tracked branch
git submodule update --remote libs/shared
git submodule update --remote --merge   # merge into current submodule branch
git submodule update --remote --rebase  # rebase instead of detach
```

After `--remote`, the submodule pointer in the superproject has changed. Commit
the update:

```bash
git add libs/shared
git commit -m "chore: update shared-lib to latest"
```

---

## Working Inside a Submodule

The submodule directory is a full git repository. Navigate into it to work:

```bash
cd libs/shared
git log --oneline -5
git switch -c fix/my-bug
git commit -m "fix: something"
git push
cd ..

# The superproject now sees the submodule as "modified" (dirty pointer)
git status
# modified: libs/shared (new commits)
git add libs/shared
git commit -m "chore: pin shared-lib to fix/my-bug tip"
```

> **Common gotcha:** After working in a submodule, the HEAD is often **detached**.
> Before committing to the submodule, make sure you're on a branch:
>
> ```bash
> cd libs/shared
> git branch                  # if output shows "* (HEAD detached at abc1234)"
> git switch main             # or your feature branch
> ```

---

## Running Commands Across All Submodules

```bash
git submodule foreach <cmd>             # run shell command in each submodule
git submodule foreach git status
git submodule foreach git fetch --prune
git submodule foreach git pull origin main
git submodule foreach --recursive <cmd> # include nested submodules
```

---

## Syncing After .gitmodules Changes

When a teammate changes submodule URLs in `.gitmodules`:

```bash
git submodule sync                      # update .git/config URLs from .gitmodules
git submodule sync --recursive          # for nested submodules
git submodule update --init             # then re-initialize
```

---

## Removing a Submodule

There's no `git submodule remove` command. It requires a few manual steps:

```bash
# 1. Unregister the submodule
git submodule deinit -f libs/shared

# 2. Remove the submodule directory from the work tree and index
git rm -f libs/shared

# 3. Remove the .git/modules entry (keeps the old clone from conflicting with re-adds)
rm -rf .git/modules/libs/shared        # on Windows: Remove-Item -Recurse .git\modules\libs\shared

# 4. Commit
git commit -m "chore: remove shared-lib submodule"
```

---

## Pull & Push with Submodules

```bash
# Pull superproject changes + update submodules to their new recorded commits
git pull --recurse-submodules

# Or as two steps:
git pull
git submodule update --init --recursive

# Configure globally:
git config --global submodule.recurse true  # auto-recurse for pull, fetch, checkout

# Push: ensure submodule changes are pushed before superproject
git push --recurse-submodules=check     # abort if any submodule has unpushed commits
git push --recurse-submodules=on-demand # push submodules first, then superproject
```

---

## Submodule Status

```bash
git submodule status                    # show commit each submodule points to
# Output:
# -abc1234 libs/shared             ← minus = not initialized
#  abc1234 libs/shared (v1.0.0)    ← space = matches superproject pointer
# +def5678 libs/shared             ← plus = ahead of superproject pointer (modified)
# Uabc1234 libs/shared             ← U = merge conflicts

git submodule summary                   # show what changed in submodules
```

---

## Common Mistakes & Fixes

**"Submodule directory is not empty" on add:**

```bash
git rm --cached <path>
rm -rf <path>
git submodule add <url> <path>
```

**Submodule is detached HEAD after update:**
This is normal — `git submodule update` checks out a specific SHA, not a branch.
To work on the submodule, explicitly switch to a branch:

```bash
cd <submodule-path>
git switch main                         # or your target branch
```

**Submodule pointer mismatch ("modified" with no actual changes):**
Usually means the submodule was updated `--remote` but not committed:

```bash
git submodule update                    # restore to superproject's recorded commit
# or commit the new pointer:
git add <submodule-path> && git commit -m "chore: update submodule pointer"
```

**Can't re-add submodule after removal:**
The stale `.git/modules/<name>` directory prevents re-adding. Remove it:

```bash
rm -rf .git/modules/<submodule-name>    # Windows: Remove-Item -Recurse
```
