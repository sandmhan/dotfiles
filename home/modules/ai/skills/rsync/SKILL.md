---
name: rsync
description: >
  Synchronise files and directories locally or over SSH with rsync for
  efficient, resumable, and checksum-verified transfers. Use when the agent
  needs to mirror a directory tree, back up files to a remote host, transfer
  large files with progress reporting, exclude patterns from a copy, or
  perform a safe dry-run before a destructive sync.
---

# rsync

Efficiently synchronise files and directories locally or over SSH with
delta transfer, checksum verification, and fine-grained exclusion control.

## Quick Start

1. Verify availability: `rsync --version`
2. Dry-run a local sync: `rsync -avn src/ dest/`
3. Live sync: `rsync -av src/ dest/`

## Intent Router

- `references/cheatsheet.md` — Common flags, local and remote sync, dry-run, exclusions, and progress output
- `references/advanced-usage.md` — Archive mode, checksums, bandwidth limits, partial transfers, hardlinks, and daemon mode
- `references/troubleshooting.md` — Trailing slash pitfalls, SSH key setup, permission errors, and interrupted transfer recovery

## Core Workflow

1. **Always dry-run first**: `rsync -avn src/ dest/` to preview what will change
2. Add `-a` (archive) to preserve permissions, timestamps, symlinks, and ownership
3. Use `--exclude` or `--exclude-from` to skip unwanted paths
4. Add `--delete` only after confirming the dry-run output — it removes files from dest not in src
5. Review the summary line (`sent X bytes … speedup Y`) to confirm the expected volume transferred

## Quick Command Reference

```bash
rsync -avn src/ dest/                               # Dry-run: show what would change
rsync -av src/ dest/                                # Local sync with verbose output
rsync -az src/ user@host:/remote/dest/              # Remote sync over SSH with compression
rsync -av --delete src/ dest/                       # Mirror: delete files absent from src
rsync -av --exclude='*.log' src/ dest/              # Exclude pattern
rsync -av --exclude-from=.rsyncignore src/ dest/    # Exclude from file
rsync -avP src/ dest/                               # Show per-file progress
rsync -av --checksum src/ dest/                     # Force checksum comparison (skip mtime)
rsync -av --bwlimit=5000 src/ dest/                 # Limit bandwidth to 5 MB/s
rsync -av --partial --progress src/ dest/           # Resume interrupted transfers
rsync -av -e "ssh -i ~/.ssh/key" src/ user@host:/d/ # Custom SSH key
rsync --version                                     # Check installed version
man rsync                                           # Full manual
```

## Safety Notes

| Area | Guardrail |
| --- | --- |
| **Always dry-run first** | `rsync -n` (or `--dry-run`) never writes. Run it before every destructive or large sync. |
| **Trailing slash on source** | `rsync src/ dest/` syncs the *contents* of `src` into `dest`. `rsync src dest/` syncs the *directory* `src` itself into `dest`. This is the single most common rsync mistake. |
| **`--delete` is destructive** | Files in `dest` that do not exist in `src` are permanently removed. Only use after dry-run confirms the deletion list is correct. |
| **Remote host trust** | Syncing to a remote host modifies files on that system. Confirm hostname, user, and path before running a live sync. |
| **Permissions and ownership** | `-a` preserves ownership, which may fail if running as non-root on the destination. Use `--no-owner --no-group` when ownership mapping is not needed. |
| **SSH access** | Ensure SSH key auth is set up before scripting. Password prompts will cause automated syncs to hang. |

## Source Policy

- Treat `man rsync` and `rsync --help` as runtime truth.
- Run `rsync --version` to confirm protocol version and capabilities before using advanced flags.
- Prefer `rsync` over `cp -r` for anything larger than a few files — it is resumable and verifiable.

## See Also

- `$cp` for simple local copies where rsync overhead is unnecessary
- `$ssh` for the underlying transport used in remote syncs
- `$mv` for relocating rather than mirroring
