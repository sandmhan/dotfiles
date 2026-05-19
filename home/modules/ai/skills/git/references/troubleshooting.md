# Troubleshooting Reference

---

## Merge Conflicts

### Reading Conflict Markers

```text
 <<<<<<< HEAD
your version of the conflicting code
 =======
their version of the conflicting code
 >>>>>>> feature/user-auth
```

- Everything between `<<<<<<<` and `=======` is what **you** have (HEAD / current branch)
- Everything between `=======` and `>>>>>>>` is what **they** have (branch being merged in)
- Resolution: edit the file to keep what you want, remove all markers

### Resolving Conflicts

```bash
git status                              # see which files have conflicts
# Edit each conflicted file, remove all <<<<, ====, >>>> markers
git add <resolved-file>                 # mark as resolved
git merge --continue                    # complete the merge (opens commit editor)
# Or abort entirely:
git merge --abort                       # restore to pre-merge state
```

**Use VS Code as merge tool (configured on this machine):**

```bash
git mergetool                           # opens each conflicted file in VS Code
# In VS Code, use the conflict resolution buttons: Accept Current | Accept Incoming | Accept Both
```

**Accept all from one side (when you know you want everything from one branch):**

```bash
git checkout --ours <file>              # keep your version
git checkout --theirs <file>            # keep their version
git add <file>
```

### Conflicts During Rebase

Rebase conflicts are similar but resolved one commit at a time:

```bash
# Conflict during rebase — resolve the conflicted file, then:
git add <resolved-file>
git rebase --continue                   # apply next commit

# Or skip the problematic commit:
git rebase --skip

# Or abandon the entire rebase:
git rebase --abort
```

---

## Detached HEAD

A detached HEAD means you're not on any branch — you've checked out a specific commit,
tag, or remote ref directly. Any commits you make won't belong to a branch and can
be "lost" after you switch away.

```bash
# How you end up in detached HEAD:
git checkout v1.0.0                     # checking out a tag
git checkout <sha>                      # checking out a specific commit
git checkout origin/main                # checking out a remote ref

git status                              # shows: "HEAD detached at abc1234"
```

**If you want to commit in detached HEAD state:**

```bash
git switch -c new-branch-name           # create a branch to capture your commits
# Now you're safe to commit
```

**If you accidentally committed in detached HEAD:**

```bash
git log --oneline -5                    # note the SHA of your commits
git switch main                         # switch back (HEAD commits become "orphaned")
git cherry-pick <sha>                   # apply your commits onto main
# or:
git merge <sha>                         # merge the orphaned commits
# or:
git reflog                              # find the SHA, then:
git switch -c recovery-branch <sha>     # create branch at the orphaned tip
```

---

## CRLF / Line Ending Issues (Windows)

`core.autocrlf=true` is set on this machine. Common symptoms:

**Entire file shows as changed even though you didn't edit it:**

```bash
git diff --ignore-space-change          # check if it's whitespace-only
git diff --check                        # show whitespace errors
```

**Spurious CRLF warnings on commit:**

```output
warning: LF will be replaced by CRLF in src/app.js
```

This is normal with `autocrlf=true` — files have CRLF on disk but LF in repo.
To suppress: `git config --global core.safecrlf false`

**Fix for a cross-platform repo:**

1. Set `core.autocrlf=input` on all contributors' machines
2. OR add `.gitattributes` to normalize line endings:

   ```gitattributes
   * text=auto eol=lf
   *.bat text eol=crlf
   ```

3. Normalize existing repo history:

   ```bash
   git add --renormalize .
   git commit -m "chore: normalize line endings"
   ```

---

## "fatal: refusing to merge unrelated histories"

Happens when merging two repos that have no common ancestor (e.g., creating a new
repo on GitHub and trying to pull into an existing local repo).

```bash
git pull origin main --allow-unrelated-histories
# or:
git merge origin/main --allow-unrelated-histories
```

---

## Recovering a Deleted Branch

```bash
# Find the tip SHA via reflog
git reflog | grep <branch-name>
# or:
git reflog --all | grep "checkout: moving from <branch-name>"

git switch -c <branch-name> <sha>       # recreate the branch
```

---

## Accidentally Committed to the Wrong Branch

**Committed to main instead of a feature branch:**

```bash
git log --oneline -3                    # note the SHA of the misplaced commit
git switch -c feature/my-thing          # create the feature branch (stays at same commit)
git switch main
git reset --hard HEAD~1                 # remove commit from main (keep it on feature)
# If main is a shared branch and you've already pushed:
# git revert HEAD to undo safely (don't reset --hard after pushing to shared branch)
```

---

## Force-Push Rejected

```bash
# "rejected (non-fast-forward)" on force-push:
# The remote ref moved since your last fetch — someone else pushed
git fetch origin
git log HEAD..origin/branch --oneline   # see what they pushed
# Option A: incorporate their changes
git rebase origin/branch
git push --force-with-lease
# Option B: override anyway (only if you're sure)
git push --force-with-lease             # safer form -- still checks
```

---

## Large Repository Performance

```bash
# Run garbage collection
git gc                                  # pack loose objects, expire old reflog entries
git gc --aggressive                     # more thorough (slow, run infrequently)

# Set up background maintenance (modern alternative to gc)
git maintenance start                   # enables hourly background maintenance

# Partial clone (fetch only tree + commits, blobs on demand)
git clone --filter=blob:none <url>      # best for large repos; blobs fetched on checkout

# Sparse checkout (only files you need)
git clone --filter=blob:none --sparse <url>
git sparse-checkout init --cone
git sparse-checkout set src/ docs/      # only check out src/ and docs/

# Clean up unreachable objects
git reflog expire --expire=now --all
git gc --prune=now
```

---

## GPG Signing Failures

```bash
# "error: gpg failed to sign the data"
gpg --list-secret-keys                  # check key is present
gpg --list-secret-keys --keyid-format LONG

# Key expired or wrong key configured
git config --global user.signingkey <correct-key-id>

# GPG agent not running (common on Windows after restart)
gpg-connect-agent reloadagent /bye
# or:
gpg-agent --daemon

# Test GPG signing directly
echo "test" | gpg --clearsign

# Temporarily disable signing for a commit
git commit --no-gpg-sign -m "urgent fix"
```

---

## Submodule Issues

**Submodule shows as "modified" with no actual changes:**

```bash
git submodule update                    # restore to superproject's recorded commit
```

**"Fatal: no submodule mapping found in .gitmodules":**

```bash
git submodule sync
git submodule update --init
```

**Submodule directory not empty when adding:**

```bash
git rm --cached <path>                  # remove from index
rm -rf <path>                           # remove from disk
git submodule add <url> <path>          # add fresh
```

---

## Common Error Messages Quick Reference

| Error | Likely Cause | Fix |
| --- | --- | --- |
| `Your local changes would be overwritten by merge` | Uncommitted changes conflict with incoming | `git stash` then pull |
| `error: failed to push some refs` | Remote is ahead | `git pull --rebase` then push |
| `nothing to commit, working tree clean` | Nothing staged | Check `git status`; add files first |
| `fatal: not a git repository` | Not inside a repo | `git init` or `cd` to correct directory |
| `CONFLICT (content): Merge conflict in <file>` | Normal merge conflict | Edit file, resolve markers, `git add` |
| `HEAD detached at <sha>` | On a specific commit, not a branch | `git switch -c <branch>` to capture state |
| `error: cannot lock ref ... already exists` | Stale remote-tracking ref | `git remote prune origin` |
| `Untracked files in the way of merge/rebase` | Untracked file would be overwritten | `git clean -n` to preview, then `-f` |
| `Permission denied (publickey)` | SSH key not loaded | `ssh-add ~/.ssh/id_ed25519` |
| `Authentication failed` | Credential expired or wrong | Clear Windows Credential Manager entry, re-authenticate |
| `sh.exe: *** fatal error - couldn't create signal pipe` | Windows blocked sh.exe IPC (Win32 error 5) | See **Git-for-Windows sh.exe Win32 Error 5** section below |
| `sh.exe: *** fatal error - CreateFileMapping ... Win32 error 5` | Same cause — antivirus or Controlled Folder Access | See **Git-for-Windows sh.exe Win32 Error 5** section below |
| `fatal: the remote end hung up unexpectedly` (after sh.exe error) | LFS or hook subprocess was killed mid-flight | Retry; if persistent, see sh.exe fallback section below |

---

## Git-for-Windows sh.exe Win32 Error 5 (Access Denied)

### Symptoms

Any command that spawns a shell-backed helper — `git add`, `git diff`, `git commit`,
`git push` with LFS, or `git lfs pointer --file=...` — intermittently fails with:

```text
sh.exe: *** fatal error - couldn't create signal pipe, Win32 error 5
sh.exe: *** fatal error - CreateFileMapping (anonymous), Win32 error 5
fatal: the remote end hung up unexpectedly
```

Read-only plumbing (`git rev-parse`, `git ls-tree`, `git log --oneline`) usually still
works because they do not invoke `sh.exe` or LFS filter helpers.

### Root Causes

Win32 error 5 is **Access Denied** — Windows refused a kernel object request from `sh.exe`:

| Cause | Details |
| --- | --- |
| Windows Defender / third-party AV | Real-time scanner intercepts `sh.exe` spawning child processes |
| Controlled Folder Access (CFA) | Blocks untrusted executables from creating named pipes or file mappings in protected paths |
| Integrity level mismatch | Git runs at medium integrity but the terminal runs elevated (or vice versa) |
| Stale Git-for-Windows installation | Older bundled `sh.exe`/`msys-2.0.dll` has known pipe-creation bugs |
| Hook or LFS filter path | `.git/hooks/*` or LFS clean/smudge filter invoked via `sh.exe` hits the restriction |

### Diagnosis

```powershell
# 1. Check Git-for-Windows and LFS versions
git --version          # should be 2.47+ for best Windows compatibility
git lfs version        # should be 3.5+

# 2. Check if Controlled Folder Access is active
Get-MpPreference | Select-Object EnableControlledFolderAccess
# "Enabled" means CFA is on — this is the most common culprit

# 3. Test whether sh.exe itself is blocked
& "C:\Program Files\Git\bin\sh.exe" -c "echo ok"
# If this fails or is silently blocked by AV, that confirms the cause

# 4. Check hooks that might invoke sh.exe
ls .git/hooks/          # any hooks without .sample extension?

# 5. Test LFS filter invocation in isolation
GIT_TRACE=1 git status  # look for LFS filter spawn errors in trace output
```

### Fixes (in order of preference)

### Option 1 — Upgrade Git for Windows

```powershell
winget upgrade Git.Git
# Or download latest from https://gitforwindows.org/
```

### Option 2 — Add Git to Controlled Folder Access allowed apps

```text
Windows Security → Virus & threat protection
→ Ransomware protection → Manage Controlled folder access
→ Allow an app through Controlled folder access
→ Add: C:\Program Files\Git\bin\sh.exe
→ Add: C:\Program Files\Git\usr\bin\sh.exe
→ Add: C:\Program Files\Git\cmd\git.exe
→ Add: C:\Program Files\Git\mingw64\bin\git-lfs.exe
```

### Option 3 — Temporarily disable real-time AV scanning for the repo path

Add your repo root as an exclusion in Windows Security → Virus & threat protection settings →
Exclusions. Re-enable after confirming the issue is resolved.

### Option 4 — Run terminal and Git at the same integrity level

Avoid mixing elevated (Run as Administrator) terminals with normal Git operations.
Open a fresh non-elevated terminal and retry.

### Option 5 — Bypass LFS filter for the session

```bash
# Disable LFS smudge filter temporarily (won't download LFS content on checkout,
# but prevents sh.exe invocation during index operations)
git -c filter.lfs.smudge= -c filter.lfs.process= status
git -c filter.lfs.smudge= -c filter.lfs.process= add <file>
git -c filter.lfs.smudge= -c filter.lfs.process= commit -m "..."
```

### Plumbing Fallback (When High-Level Commands Are Unreliable)

If `git add` / `git commit` are consistently failing mid-operation, use Git's
low-level plumbing to commit without invoking `sh.exe`:

```bash
# 1. Manually update the index for specific files (no shell helper invoked)
git update-index --add --cacheinfo <mode>,<blob-sha>,<path>
# e.g. for a regular file already stored as a blob:
git update-index --add path/to/file.txt
# For an LFS pointer file, get the existing blob SHA first:
git ls-tree HEAD -- path/to/large.bin   # shows blob SHA of current pointer

# 2. Write the current index to a tree object
TREE=$(git write-tree)

# 3. Create a commit object from the tree
COMMIT=$(git commit-tree "$TREE" -p HEAD -m "your commit message")

# 4. Advance the branch ref
git update-ref refs/heads/main "$COMMIT"
```

After a plumbing commit the working tree may appear "dirty" to `git status`
until the index is reconciled. Run `git checkout -- .` or `git reset HEAD` to
sync the working tree, or just continue working — the branch ref and history
are correct.

> **Important:** This approach bypasses LFS clean/smudge filters. Only use it
> for files that are already stored correctly in the object store (e.g., when
> renaming or reorganizing existing LFS pointer files rather than adding new
> LFS content).
