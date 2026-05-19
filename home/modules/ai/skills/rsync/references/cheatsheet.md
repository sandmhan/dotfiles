# rsync Cheatsheet

## Essential flags

| Flag | Meaning |
| --- | --- |
| `-a` | Archive: `-r -l -p -t -g -o -D` — preserves almost everything |
| `-v` | Verbose: show transferred files |
| `-n` / `--dry-run` | Simulate: show what would change without writing |
| `-z` | Compress during transfer (useful over slow links) |
| `-P` | Shorthand for `--partial --progress` |
| `--partial` | Keep partially transferred files so transfers can resume |
| `--progress` | Show per-file transfer progress |
| `--delete` | Delete files in dest that are absent in src |
| `--exclude=PATTERN` | Skip files matching pattern |
| `--exclude-from=FILE` | Read exclusion patterns from a file |
| `--checksum` | Compare by checksum instead of size+mtime |
| `--bwlimit=KBPS` | Limit bandwidth (e.g. `--bwlimit=5000` = 5 MB/s) |
| `-e ssh` | Use SSH as transport (default for `user@host:` paths) |
| `--remove-source-files` | Delete source files after successful transfer |
| `-H` | Preserve hardlinks |
| `--stats` | Show transfer statistics summary |

## Critical: trailing slash on source

```bash
rsync -av src/  dest/   # Sync CONTENTS of src into dest (dest/file1, dest/file2...)
rsync -av src   dest/   # Sync src DIRECTORY into dest  (dest/src/file1...)
```

**The trailing slash on the source changes the meaning entirely.**

## Common invocations

```bash
rsync -avn src/ dest/                               # Dry-run preview
rsync -av src/ dest/                                # Local sync
rsync -avz src/ user@host:/remote/dest/             # Remote via SSH
rsync -av --delete src/ dest/                       # Mirror (delete extras)
rsync -avP src/ dest/                               # Progress + resume
rsync -av --exclude='*.log' src/ dest/              # Exclude pattern
rsync -av --exclude-from=.rsyncignore src/ dest/    # Exclude from file
rsync -av --checksum src/ dest/                     # Force checksum verify
rsync -av --bwlimit=5000 src/ user@host:/dest/      # Bandwidth limit
rsync -av -e "ssh -p 2222" src/ user@host:/dest/    # Custom SSH port
rsync -av --stats src/ dest/                        # Transfer statistics
```

## Useful exclude patterns

```bash
--exclude='*.tmp'           # Exclude by extension
--exclude='.git/'           # Exclude git directory
--exclude='node_modules/'   # Exclude npm deps
--exclude='__pycache__/'    # Exclude Python cache
--exclude='*.log'
--exclude='*.DS_Store'      # macOS metadata
```

## Verifying a sync

```bash
rsync -avn --checksum src/ dest/    # Dry-run with checksum: shows any remaining diffs
diff -r src/ dest/                  # Full content comparison
```
