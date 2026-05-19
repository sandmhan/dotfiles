# rsync Troubleshooting

## Wrong files synced (trailing slash mistake)

**Symptom:** `rsync -av src dest/` creates `dest/src/` instead of syncing into `dest/`.

```bash
# With trailing slash on source: syncs CONTENTS
rsync -av src/ dest/    # → dest/file1, dest/file2

# Without trailing slash on source: syncs the DIRECTORY
rsync -av src dest/     # → dest/src/file1, dest/src/file2
```

Always dry-run first: `rsync -avn src/ dest/` to confirm which files will appear where.

## Files unexpectedly deleted (--delete)

**Symptom:** Files in dest disappear after a sync.

`--delete` removes files in dest that are absent in src. This is intentional for mirroring but destructive if misapplied.

```bash
# Always preview --delete
rsync -avn --delete src/ dest/ | grep "^deleting"

# Safer: use --delete-dry-run first, then add --backup
rsync -av --delete --backup --backup-dir=/backup/$(date +%Y%m%d) src/ dest/
```

## SSH connection refused or timeout

```bash
# Test SSH connectivity independently
ssh user@host "echo ok"

# Check port and key
rsync -av -e "ssh -v -p 22 -i ~/.ssh/key" src/ user@host:/dest/

# Increase timeout
rsync -av -e "ssh -o ConnectTimeout=30" src/ user@host:/dest/
```

## Permission denied on destination

```bash
ls -ld /destination/                # Check write permission
sudo rsync -av src/ dest/           # Run with elevated privileges

# When preserving ownership requires root
rsync -av --no-owner --no-group src/ dest/   # Skip ownership (as non-root)
```

## Transfer stalls or is very slow

```bash
# Check network throughput independently
iperf3 -c host

# Limit rsync to avoid saturating the link
rsync -av --bwlimit=10000 src/ dest/    # 10 MB/s limit

# Disable compression for local or fast-network transfers (overhead not worth it)
rsync -av src/ dest/                    # Omit -z for LAN
```

## "rsync: command not found" on remote host

```bash
# Specify the remote rsync binary path
rsync -av --rsync-path=/usr/local/bin/rsync src/ user@host:/dest/
```

## Partial transfers leaving tmp files in dest

```bash
# Use --partial-dir to keep partial files in a separate location
rsync -av --partial-dir=.rsync-partial src/ dest/

# Resume: re-run the same command; rsync will resume from .rsync-partial
```

## Checksum mismatch warnings

```bash
# Force full checksum comparison (ignores mtime)
rsync -av --checksum src/ dest/

# Useful when files have been touched (mtime changed) without content change
```

## "vanished file" warnings

**Symptom:** `rsync warning: some files vanished before they could be transferred`

A file listed at the start of the run was deleted or renamed before rsync could transfer it. This is not a fatal error and typically means another process modified the source during the sync. Exit code 24 is returned; treat it as a warning, not a failure.
