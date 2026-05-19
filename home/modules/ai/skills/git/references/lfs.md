# Git LFS Reference

Git LFS (Large File Storage) replaces large binary files in a repository with small
**pointer files**. The actual file contents are stored on an LFS server (GitHub,
GitLab, self-hosted, etc.) and fetched on demand.

This machine has **Git LFS 3.7.0** installed with LFS filters configured globally.

---

## How LFS Works

```text
Without LFS:   repo/binary.psd  →  150 MB in every clone
With LFS:      repo/binary.psd  →  text pointer (134 bytes) in repo
                                   150 MB file on LFS server, fetched on checkout
```

The pointer file looks like:

```text
version https://git-lfs.github.com/spec/v1
oid sha256:4d7a214614ab2935c943f9e0ff69d22eadbb8f32b1258daaa5e2ca24d17e2393
size 12345
```

LFS hooks (`clean`, `smudge`, `filter-process`) handle the conversion transparently
during `git add` and `git checkout`.

---

## Initial Setup

LFS filters are already installed globally on this machine. For a new repository
you still need to configure which file types to track:

```bash
# Verify LFS is installed and active
git lfs version                         # → git-lfs/3.7.0
git lfs env                             # show LFS configuration for current repo

# For a new repo (only needed once per repo, already done globally)
git lfs install
```

---

## Tracking File Types

```bash
# Track a file pattern (appends to .gitattributes)
git lfs track "*.psd"
git lfs track "*.mp4" "*.mov" "*.avi"
git lfs track "*.zip"
git lfs track "models/*.bin"

# Always commit .gitattributes after tracking
git add .gitattributes
git commit -m "chore: configure LFS tracking for media files"

# View currently tracked patterns
git lfs track

# Stop tracking a pattern
git lfs untrack "*.zip"

# Track by exact filename
git lfs track --filename "specific-file.dat"
```

**What goes in .gitattributes after tracking:**

```text
*.psd filter=lfs diff=lfs merge=lfs -text
*.mp4 filter=lfs diff=lfs merge=lfs -text
models/*.bin filter=lfs diff=lfs merge=lfs -text
```

> **Important:** Adding a pattern to `.gitattributes` only affects **future** `git add`
> operations. Files already committed to history are NOT retroactively converted.
> Use `git lfs migrate` (see below) to convert existing history.

---

## Normal Workflow (After Tracking is Set Up)

Once `.gitattributes` is committed, the LFS workflow is transparent:

```bash
git add design.psd                      # LFS clean filter runs; pointer committed
git commit -m "design: update mockup"
git push                                # LFS pre-push hook uploads the actual file
git pull                                # LFS smudge filter runs; file downloaded
```

---

## Inspecting LFS State

```bash
git lfs status                          # show LFS files in working tree vs index
git lfs ls-files                        # list all LFS-tracked files in current commit
git lfs ls-files -l                     # include SHA and size
git lfs ls-files --all                  # include all refs, not just HEAD
git lfs pointer --file=design.psd       # show the pointer content for a file
git lfs env                             # show LFS server URL, credential info, config
git lfs logs last                       # show recent LFS log entries (for debugging)
```

---

## Fetching & Pulling LFS Content

Shallow clones or `--no-checkout` clones may not have LFS content yet:

```bash
git lfs fetch                           # download LFS objects for current ref
git lfs fetch --all                     # download ALL LFS objects for all refs
git lfs fetch origin main               # download for specific ref
git lfs pull                            # fetch + checkout (update working tree)
git lfs checkout                        # materialize LFS files already fetched
```

**When cloning a repo with LFS:**

```bash
git clone <url>                         # LFS content is downloaded automatically
# If you cloned without LFS (or LFS wasn't installed when you cloned):
git lfs install
git lfs pull                            # download all LFS objects
```

---

## Pruning Local LFS Cache

LFS caches files locally in `.git/lfs/objects/`. This grows over time:

```bash
git lfs prune                           # delete LFS objects no longer referenced
git lfs prune --dry-run                 # preview what would be deleted
git lfs prune --verify-remote           # only prune objects confirmed on the remote
git lfs prune --recent                  # keep recent refs (don't prune last N days)
```

---

## Migration — Convert Existing History

Use `git lfs migrate` to retroactively move large files that are already committed
into LFS. This **rewrites git history** (new commit SHAs).

> ⚠️ **Coordinate with your team before migrating.** After migration:
>
> - All collaborators must `git clone` a fresh copy (existing clones are broken)
> - All open pull requests need to be rebased
> - Remote history must be force-pushed

```bash
# See which file types are large in history
git lfs migrate info
git lfs migrate info --top=20           # show top 20 by size
git lfs migrate info --include="*.mp4,*.psd"

# Import: convert files to LFS (rewrites history)
git lfs migrate import --include="*.mp4"
git lfs migrate import --include="*.mp4,*.psd,*.zip"
git lfs migrate import --include="*.bin" --exclude="vendor/"
git lfs migrate import --everything     # migrate all branches and tags
git lfs migrate import --include="*.mp4" --above=50mb  # only files > 50MB

# Export: convert LFS pointers back to real files (reverse migration)
git lfs migrate export --include="*.mp4"

# After migration: force-push all refs
git push --force --all
git push --force --tags
```

---

## File Locking

File locking prevents merge conflicts on binary files that can't be text-merged
(e.g., Photoshop files, compiled assets). Requires server-side locking support
(GitHub and GitLab support this).

```bash
# Lock a file before editing
git lfs lock design/hero.psd

# List locked files (yours + others)
git lfs locks
git lfs locks --remote origin

# Unlock after committing
git lfs unlock design/hero.psd

# Force unlock a file locked by someone else (requires permissions)
git lfs unlock --force design/hero.psd
```

**Configure .gitattributes for locking:**

```text
*.psd filter=lfs diff=lfs merge=lfs -text lockable
```

---

## Troubleshooting LFS

**"Smudge error" or files appear as pointer text:**

```bash
git lfs pull                            # force re-download LFS content
# If still broken:
git lfs fetch --all
git lfs checkout
```

**Push rejected: LFS objects missing:**

```bash
git lfs push --all origin              # explicitly push all LFS objects
```

**Large file accidentally committed without LFS:**

```bash
# Option 1: if not yet pushed, amend
git lfs track "*.bin"
git add .gitattributes <the-file>
git commit --amend --no-edit

# Option 2: if already pushed, use migrate
git lfs migrate import --include="*.bin"
git push --force-with-lease
```

**Check LFS storage usage:**

```bash
git lfs du                              # disk usage of LFS objects in repo
```

**Environment debugging:**

```bash
git lfs env                             # full LFS config: endpoint, access, filters
GIT_TRACE=1 git push                    # trace all git operations including LFS
```
