# rsync Advanced Usage

## Backup with versioning

```bash
# Snapshot backup with hard-linked unchanged files (efficient)
rsync -av --delete \
  --link-dest=/backups/latest \
  src/ /backups/$(date +%Y%m%d)/

ln -snf /backups/$(date +%Y%m%d) /backups/latest
```

This creates a full snapshot at each run but only stores changed files as new
inodes — unchanged files are hardlinked to the previous snapshot.

## Resuming interrupted transfers

```bash
rsync -avP src/ dest/               # --partial: keep incomplete files
rsync -av --partial src/ dest/      # Same; re-run to resume
```

rsync uses size and mtime to skip already-transferred files. Use `--checksum`
to force verification when mtime cannot be trusted.

## Cross-platform considerations

```bash
# Preserve permissions when syncing between Linux hosts
rsync -av src/ user@host:/dest/

# Syncing to FAT/NTFS (no Unix permissions)
rsync -rvt --no-perms --no-owner --no-group src/ /mnt/usb/

# macOS to Linux: skip resource fork files
rsync -av --exclude='._*' --exclude='.DS_Store' src/ dest/
```

## Using rsync as a safe `mv`

```bash
# Cross-filesystem "move": copy + remove source on success
rsync -av --remove-source-files src/ dest/
# Then clean up the now-empty source directory
find src/ -type d -empty -delete
```

## Daemon mode (rsync server)

```bash
# /etc/rsyncd.conf
[mymodule]
path = /data/shared
read only = no
list = yes
uid = nobody
gid = nobody

# Start daemon
rsync --daemon

# Connect from client
rsync -av rsync://host/mymodule/ local/
```

## Filtering rules

rsync filter rules are processed in order; first match wins:

```bash
rsync -av \
  --filter="+ *.conf" \
  --filter="- *.log" \
  --filter="- tmp/" \
  src/ dest/
```

Rules:

- `+` include
- `-` exclude
- `H` hide (like exclude but does not delete from dest)
- `P` protect (like include for `--delete`)

## SSH options

```bash
rsync -av -e "ssh -i ~/.ssh/deploy_key -p 2222 -o StrictHostKeyChecking=no" \
  src/ user@host:/dest/
```

## Checking what will be deleted before using --delete

```bash
# Always preview --delete operations
rsync -avn --delete src/ dest/ | grep "^deleting"
```

Only proceed with the live run after confirming the deletion list is safe.
