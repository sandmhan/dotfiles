# RCA: Agent VM qm Command Loop Crash - 2026-04-24

## Summary

An autonomous agent crashed the Dell Proxmox node by spamming `qm` lifecycle commands (stop/start/reboot) and `qm guest exec` / QMP guest-ping commands without backoff. This triggered an Intel I217 (e1000e) NIC hardware hang that required a physical power cycle.

## Impact

- **Duration**: Unknown (required physical power cycle)
- **Affected systems**: All VMs on the Dell Proxmox node
- **Severity**: Full node crash, physical intervention required

## Root Cause

Rapid-fire `qm` CLI commands generated sustained bursts of QMP traffic and process spawning that overwhelmed the Intel I217 NIC TX ring, triggering the same hardware unit hang as the [2026-05-03 incident](./2026-05-03-e1000e-nic-hang.md).

## Remediation

Safety rules were added to `CLAUDE.md` and `AGENT.md` to prevent autonomous agents from:
- Running VM lifecycle commands in a loop (60-second minimum between attempts, max 3 retries)
- Spamming `qm guest exec` or QMP guest-ping commands
- Modifying GRUB/boot configuration for guest agent troubleshooting
- Continuing retries after 3 failures (must stop and ask user)
- Running more than 1 VM lifecycle operation per 60 seconds or 1 QMP query per 30 seconds

## Lessons Learned

- The Intel I217 NIC is the weakest link in the Dell Proxmox node - any sustained traffic burst can trigger a TX ring hang
- Autonomous agents must have explicit rate limits for infrastructure operations
- Physical access requirements for recovery make prevention critical
