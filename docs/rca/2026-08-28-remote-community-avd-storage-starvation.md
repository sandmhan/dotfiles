# RCA: Remote Community AVD Copy Storage Starvation - 2026-08-28

## Summary

Back-to-back multi-gigabyte Android AVD transfers through VM111 saturated the Dell Proxmox node's single-HDD ZFS storage. VM111's ext4 journal blocked, Proxmox storage and management operations became unresponsive, and all guests lost network accessibility until the host was power-cycled by the owner.

This incident was not an Intel I217/e1000e TX-ring hang and did not involve an OOM kill or ZFS pool fault.

## Impact

- Proxmox management, Matrix, Remote Community, and other guests became unreachable.
- OwnTracks ingestion and Matrix were unavailable during the outage.
- Matrix did not start automatically after the power cycle and required one manual VM start.
- The Android AVD installation was interrupted and the emulator failed closed on the next boot.
- A fan malfunction separately halted the first recovery boot attempt.

## Evidence and timeline (EDT)

| Time | Event |
|------|-------|
| 01:22:39 | Android emulator stopped cleanly before AVD migration. |
| 01:22:39-01:40:16 | SSH/rsync session transferred the authenticated AVD into private staging; the session wrote 5.3 GiB and reported a 5.2 GiB memory peak. |
| 01:25:50 | VM111 journald watchdog timed out. |
| 01:29:36 | Proxmox reported `/var/lib/vz` missing or unreachable. |
| 01:32:38 | VM111 reported `jbd2/vda1-8` blocked for 122 and 245 seconds; journald was killed and restarted. |
| 01:40:45 | A second full rsync from staging into `/var/lib/remote-community-emulator` began. |
| 01:43:55 | VM111 again reported its ext4 journal blocked for more than 122 seconds. |
| 01:38-01:51 | Proxmox firewall, statistics, HA, and scheduler loops took 100-187 seconds and storage locks timed out. |
| 08:45 | Owner completed a power cycle after clearing a fan-related boot halt. |

The interrupted second copy left a 3.86 GiB rsync temporary file beside the prior 5.70 GiB QCOW2, while the intact staging QCOW2 was 6.10 GiB.

## Root cause

The direct cause was unbounded back-to-back AVD I/O on a resource-constrained single-HDD Proxmox node:

1. A multi-gigabyte network rsync wrote the complete AVD into VM111.
2. A second local rsync immediately attempted to rewrite the same AVD into the service state directory.
3. Guest ext4 journal commits stalled on the ZFS-backed virtual disk.
4. Proxmox storage-dependent management and networking work became starved long enough to make the node and all guests inaccessible.

## Contributing factors

- The migration procedure prescribed a second full local copy instead of an atomic same-filesystem rename.
- Full-file checksum work and bursty rsync traffic were not rate-limited for the Dell node.
- VM111 had temporarily been changed from the documented ballooned policy to fixed 6 GiB RAM, reducing safety margin. No OOM occurred, but the change violated the runbook.
- The authenticated API 35 emulator is CPU- and memory-intensive on the two-core Ivy Bridge host.
- Matrix VM102 lacked `onboot=1`, so it remained stopped after host recovery.

## Ruled out

- No outage-time `e1000e Detected Hardware Unit Hang` message exists.
- The e1000e watchdog continued to run and found no matching NIC event.
- No outage-time OOM kill exists on Proxmox or VM111.
- `zpool status` is healthy with no pool fault.
- The emulator process had been stopped before the transfer that initiated storage degradation.
- The fan malfunction affected recovery boot only, not the original outage.

## Recovery

- Restored VM111 to 8 GiB maximum / 4 GiB balloon minimum and restarted QEMU once so the balloon device became active.
- Quarantined the interrupted destination AVD.
- Atomically renamed the intact staging AVD into the service state directory; no second data copy was performed.
- Kept the damaged AVD quarantined instead of deleting it under load.
- Enabled `onboot=1` for Matrix VM102 and started it once.
- Verified Matrix locally and externally, Remote Community health/readiness, ZFS health, and Android boot.
- Exposed the physical host CPU to the nested emulator to avoid API 35 package-manager watchdog failure during RSA signature parsing.

## Prevention

1. On same-filesystem AVD migrations, install by atomic rename and quarantine the old image.
2. On constrained single-disk hosts, rate-limit and lower the I/O priority of the one required transfer.
3. Do not run a second checksum or full local copy immediately after a multi-gigabyte transfer.
4. Require at least 2 GiB host memory headroom before emulator deployment or other heavy VM work.
5. Preserve VM111 ballooning; QEMU must be restarted after adding a balloon device to a running VM.
6. Treat `sys.boot_completed=1` as insufficient emulator readiness; also require a responsive Android activity service and bounded app preflight.
7. Keep Matrix configured for automatic boot and prioritize it over optional guests when resources are constrained.
8. Do not adopt Tasker/AutoInput as a workaround for an unhealthy Android framework; it depends on the same activity/accessibility services and broadens the trusted automation surface.
