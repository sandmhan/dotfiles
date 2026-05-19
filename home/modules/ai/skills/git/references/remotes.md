# Remotes Reference

---

## Managing Remotes

```bash
git remote -v                               # list remotes with URLs
git remote add origin <url>                 # add remote named "origin"
git remote add upstream <url>               # add second remote (e.g., for forked repos)
git remote rename origin myorigin           # rename a remote
git remote remove <name>                    # remove a remote
git remote set-url origin <new-url>         # change remote URL
git remote set-url --push origin <push-url> # separate push URL from fetch URL
git remote show origin                      # detailed info: branches, tracking, HEAD
git remote prune origin                     # remove stale remote-tracking refs
```

---

## Fetching

Fetch downloads new commits and refs from the remote but **does not change your
working tree or local branches**. Always safe to run.

```bash
git fetch                           # fetch from default remote (origin)
git fetch origin                    # explicit remote name
git fetch --all                     # fetch all remotes
git fetch --prune                   # fetch + delete remote-tracking refs for deleted branches
git fetch --tags                    # fetch all tags
git fetch origin <branch>           # fetch a specific branch only
git fetch --depth=1                 # shallow fetch (partial clone / update)
```

`git fetch --prune` is the recommended default — it keeps your remote-tracking
branch list tidy and prevents confusion when remote branches are deleted.

---

## Pulling

`git pull` = `git fetch` + `git merge` (or rebase, depending on config).

```bash
git pull                            # fetch + merge (pull.rebase=false on this machine)
git pull --rebase                   # fetch + rebase (cleaner history; avoids merge commits)
git pull --rebase=interactive       # fetch + interactive rebase
git pull --ff-only                  # fail if fast-forward is not possible (safe default)
git pull origin <branch>            # pull specific remote branch
git pull --no-commit                # merge but don't auto-commit
git pull --allow-unrelated-histories  # for merging two unrelated repos (rare)
```

**Recommended pull strategy:**

- For feature branches: `git pull --rebase` keeps history linear
- For main/develop: `git pull` (merge) is fine; preserves merge topology
- Or configure globally: `git config --global pull.rebase true`

---

## Pushing

```bash
git push                            # push current branch to its tracking remote
git push origin <branch>            # push to specific remote + branch
git push -u origin <branch>         # push + set upstream tracking (first push)
git push --all                      # push all local branches
git push --tags                     # push all tags
git push origin <tag>               # push single tag
git push origin --delete <branch>   # delete remote branch
git push origin --delete <tag>      # delete remote tag

# Force pushing
git push --force-with-lease         # safe force: fails if remote moved since your last fetch
git push --force-if-includes        # stronger safety check (git 2.30+)
# Never: git push --force            # blindly overwrites — can destroy others' work ⚠️

# Push without running pre-push hook (use sparingly)
git push --no-verify
```

### Force-Push Safety

`--force-with-lease` checks that the remote ref matches what you last fetched. If
someone else pushed to the branch since your last fetch, the push is rejected — giving
you a chance to reconcile. This is the **only acceptable force-push** on any branch
that others might use.

```bash
# Typical safe force-push flow after interactive rebase:
git rebase -i HEAD~3
# (resolve, squash commits)
git push --force-with-lease
```

---

## Tracking Branches

A tracking branch is a local branch associated with a remote branch. Git uses this
to report ahead/behind status and to determine where `git pull`/`git push` defaults go.

```bash
git branch -vv                      # show upstream tracking for each branch
# Output: * feature/auth  abc1234 [origin/feature/auth: ahead 2] last commit

git branch -u origin/<branch>       # set upstream for current branch
git branch --set-upstream-to=origin/<branch> <local>  # set for specific branch
git branch --unset-upstream         # remove tracking

# When you clone, all remote branches get remote-tracking refs:
# origin/main, origin/develop, etc. — these are read-only snapshots updated by fetch
```

---

## Working with Forks (Upstream Workflow)

```bash
# Initial setup
git clone git@github.com:you/repo.git
git remote add upstream git@github.com:original/repo.git
git remote -v  # should show origin + upstream

# Keep your fork's main up to date
git fetch upstream
git switch main
git merge --ff-only upstream/main    # or: git rebase upstream/main
git push origin main

# Sync a feature branch with upstream changes
git switch feature/my-thing
git fetch upstream
git rebase upstream/main
git push --force-with-lease          # update your fork's feature branch
```

---

## Refspecs

A refspec maps local refs to remote refs. Usually you don't write them manually,
but understanding them helps with advanced fetch/push.

```text
Format: [+]<src>:<dst>
+ = allow non-fast-forward updates

Examples:
  refs/heads/main:refs/heads/main         # push main to remote main
  refs/heads/*:refs/remotes/origin/*      # default fetch refspec
  +refs/heads/*:refs/remotes/origin/*     # fetch, allowing force updates
```

```bash
# Push to a different remote branch name
git push origin local-branch:remote-branch

# Fetch a specific remote branch to a local name
git fetch origin feature/x:refs/remotes/origin/feature/x

# Delete a remote branch via refspec
git push origin :old-branch-name          # empty src = delete dst
```

---

## Credential Helpers (This Machine)

- **Windows Credential Manager** (`credential.helper=manager`) — credentials stored securely in Windows vault
- **Azure DevOps** — `credential.https://dev.azure.com.usehttppath=true` is configured (required for ADO's path-based auth)

```bash
# If credentials need refreshing
git credential reject          # clear stored credential for current URL
# Then re-run the git operation — will prompt for new credentials

# For GitHub: use personal access tokens or GitHub CLI
gh auth login                  # GitHub CLI handles credential setup

# Check which credential helper is active
git config credential.helper
```

---

## Submodule Remote Operations

When working in repos that have submodules:

```bash
git clone --recurse-submodules <url>                # clone with all submodules
git pull --recurse-submodules                       # pull + update submodules
git submodule update --remote --merge               # update submodule to latest remote
```

See `references/submodules.md` for full submodule documentation.
