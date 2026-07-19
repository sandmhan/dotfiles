---
title: Framework 13 Firmware Reboot Follow-up
status: accepted
---

# Framework 13 Firmware Reboot Follow-up

Use this runbook after rebooting Gaia to apply the firmware updates staged on
2026-07-19. Keep the charger connected until the firmware update and all automatic
restarts finish.

## Staged state before reboot

- Host: `gaia`, Framework Laptop 13 (AMD Ryzen AI 300 Series)
- System firmware: `3.03` staged to update to `4.02`
- UEFI Secure Boot dbx: `20230501` staged to update to `20260402`
- fwupd recorded both updates as `update-in-progress`
- Battery was charging at 68% with AC online when the updates were staged
- No NixOS or Home Manager configuration was activated
- Git branch: `feat/framework-13-hardware-optimizations`
- Relevant commits:
  - `f1645bb feat(gaia): preserve work across closed-lid AC use`
  - `0352fec feat(gaia): align Framework AI power management`

## Verified outcome

The follow-up completed successfully on 2026-07-19:

- System Firmware reports `0.0.4.2`; Linux reports BIOS `04.02`.
- UEFI dbx reports `20260402`.
- fwupd history records both updates as successful.
- fwupd reports no remaining update for either device.

The BIOS capsule applied on the first reboot. The dbx capsule had to be staged
again by device ID and applied on a second reboot. fwupd 2.0.19 continued to
prompt for a reboot afterward despite the successful versions and history; this
matches [upstream fwupd issue 9720](https://github.com/fwupd/fwupd/issues/9720)
and was not treated as a third-reboot request.

## Reboot safely

1. Save or stop any work that cannot survive a restart, including long-running
   Codex sessions.
2. Leave the charger attached.
3. Reboot normally:

   ```console
   systemctl reboot
   ```

4. Allow the firmware progress screen and any automatic restarts to finish. Do
   not power off the laptop, close the lid, or remove the charger during the
   update.
5. Log back into Gaia before running the checks below.

## Verify the firmware update

Confirm the BIOS reported by Linux:

```console
cat /sys/class/dmi/id/bios_version
```

Expected result: `03.04.02`, `4.02`, or an equivalent representation of BIOS
4.02.

Inspect fwupd's device and update history:

```console
fwupdmgr get-devices
fwupdmgr get-history
fwupdmgr check-reboot-needed
fwupdmgr get-updates --no-unreported-check
```

Success criteria:

- System Firmware reports version `0.0.4.2` or `4.02`.
- UEFI dbx reports version `20260402`.
- History records both updates as successful.
- `check-reboot-needed` does not request another restart, except for the known
  fwupd 2.0.19 false-positive described above.
- Neither update remains marked `update-in-progress`.

If fwupd requests another reboot, keep the charger connected and reboot once
more before proceeding. If either update is failed or still pending afterward,
capture these diagnostics and stop before activating the NixOS changes:

```console
fwupdmgr get-history --json
journalctl -b -u fwupd.service --no-pager
journalctl -b -1 -k --no-pager
```

## Resume the hardware configuration work

After both firmware updates are verified, return to the repository and confirm
the handoff state:

```console
cd /home/sandmhan/dotfiles
git switch feat/framework-13-hardware-optimizations
git status --short --branch
```

The branch already contains the agreed power behavior:

- Power Profiles Daemon with balanced mode on AC and power-saver on battery
- Bluetooth left enabled
- Display blanking after 10 minutes without suspending plugged-in work
- Closed lid ignored on AC so long-running processes continue
- Suspend-then-hibernate when the lid is closed on battery or AC is removed
- An 80% battery charge ceiling
- The nixos-hardware Framework AMD Ryzen AI 300 profile

The remaining decisions were resolved without activating the branch:

- Keep the display at 60 Hz for the initial post-firmware baseline. The panel
  exposes a native 47.998 Hz mode, which can be added later through a
  user-session power policy.
- Keep fingerprint authentication disabled for Ly, `sudo`, `su`, TTY login,
  swaylock, and Hyprland. A post-activation boot confirmed that Ly's sequential
  PAM conversation delayed password login by the full five-second fingerprint
  timeout. Keep `fprintd` enabled so the enrolled fingerprints remain available
  when evaluating display managers or lock screens with parallel authentication.
- Follow nixpkgs' maintained default kernel (`linuxPackages`) instead of
  `linuxPackages_latest`.

These decisions are recorded in:

- `307599e feat(gaia): stabilize kernel and fingerprint login`
- `6ba40a6 feat(gaia): add declarative firmware status helper`

## Declarative firmware maintenance

Gaia enables `services.fwupd`, so NixOS owns the daemon and the persistent
`fwupd-refresh.timer`. The timer refreshes LVFS metadata automatically; a manual
`fwupdmgr refresh` is not part of routine maintenance.

After activating this branch, use the Nix-installed read-only summary command:

```console
gaia-firmware-status
```

Firmware payloads and BIOS state are mutable hardware state outside the Nix
store and its rollback model. Keep installation and reboot explicit:

```console
fwupdmgr update
systemctl reboot
```

Do not run unattended `fwupdmgr update` from a timer: it can stage a capsule
that flashes during an otherwise routine reboot. Gaia currently exposes no
settings through `fwupdmgr get-bios-settings`, so BIOS setup values cannot be
managed through fwupd policy. The charge ceiling and power policy remain
declarative through their existing sysfs-backed NixOS services.

The updated Gaia closure passed a fresh dry-run after the follow-up edits. Run
it again after any further edits and before activation:

```console
nix build --dry-run .#nixosConfigurations.gaia.config.system.build.toplevel --show-trace
```
