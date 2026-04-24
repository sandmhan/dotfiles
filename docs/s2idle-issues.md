# s2idle Suspend Issues - Framework 13 AMD Ryzen AI 300

## Hardware
- Framework Laptop 13 (AMD Ryzen AI 300 Series)
- BIOS version: 03.03
- Kernel: 6.19.11 (linuxPackages_latest)
- Sleep mode: s2idle only (deep sleep not available)

## Problem Summary

Intermittent issue where the laptop enters a suspend loop after lid close. The display goes off, power LED turns off, and the built-in keyboard/touchpad become unresponsive after resume. Bluetooth input devices (Corne keyboard) continue to work.

## Observed Behavior (2025-04-23 logs)

1. Lid close triggers `suspend-then-hibernate` via logind
2. System wakes spuriously after ~3 seconds with no corresponding "Lid opened" event
3. Since logind still sees lid as closed, it re-suspends within 30 seconds
4. This creates a suspend loop (3 cycles observed: 12:47, 12:49, 12:50)
5. Built-in keyboard (i8042 AT Translated Set 2) and touchpad (PIXA3854 i2c) silently fail to reinitialize after resume - no errors logged
6. Bluetooth Corne keyboard re-registers successfully after each wake

## Root Causes Identified

### 1. Spurious wakes from USB host controllers
Four USB/XHC wakeup sources are enabled (`XHC0`, `XHC1`, `XHC3`, `XHC4` in `/proc/acpi/wakeup`). These trigger wakes during s2idle even though the lid is still closed, starting the suspend loop.

### 2. Internal input devices fail to resume from s2idle
The i2c bus (touchpad) and i8042 controller (keyboard) don't properly reinitialize after s2idle resume. No kernel errors are logged - the devices just stop responding.

### 3. Slow RTC reads during suspend
Kernel logs show `Reading current time from RTC took around 133-172 ms` during suspend cycles, indicating RTC timing issues on this AMD platform.

## Additional Issues Noticed

### udev rule spam (unrelated to suspend)
`/etc/udev/rules.d/99-local.rules:74` references `GROUP="plugdev"` which doesn't exist on NixOS. This is the QMK `hid_listen` rule in `configuration.nix:282`. It fires every ~3 seconds, flooding the journal. Fix: remove `GROUP="plugdev"` from the rule (it already has `TAG+="uaccess"`).

### TPM timeout errors during suspend
```
tpm tpm0: cmdReady timed out
tpm tpm0: tpm_relinquish_locality: : error -62
```
These appear on every suspend cycle. Non-blocking (kernel ignores them) but may indicate firmware/TPM interaction issues.

## Possible Mitigations to Investigate

### Kernel parameters
Add `rtc_cmos.use_acpi_alarm=1` to `boot.kernelParams` to address the slow RTC reads during suspend.

### Disable USB wakeup sources
Add a udev rule to disable AMD USB host controllers as wakeup sources, preventing spurious wakes that start the suspend loop. Trade-off: can't wake laptop via USB keyboard (lid open and power button still work).

```nix
# Example udev rule to investigate
ACTION=="add", SUBSYSTEM=="pci", ATTR{power/wakeup}=="enabled", ATTRS{vendor}=="0x1022", RUN+="${pkgs.bash}/bin/bash -c 'echo disabled > /sys$env{DEVPATH}/power/wakeup'"
```

### Resume hook to rebind input devices
A systemd service that unbinds/rebinds the i2c controller (`AMDI0010:03`) after resume to force touchpad reinitialization. The i8042 keyboard may also need similar treatment.

```nix
# Example systemd service to investigate
systemd.services.fix-resume-input = {
  description = "Rebind input drivers after resume";
  after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
  wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "...unbind/rebind AMDI0010:03 on i2c_designware...";
  };
};
```

### BIOS update
Check for updates with `sudo fwupdmgr get-updates`. Framework has released BIOS updates that may improve suspend behavior on this platform.

### Fix plugdev udev rule
In `configuration.nix`, change the `hid_listen` rule from:
```
KERNEL=="hidraw*", MODE="0660", GROUP="plugdev", TAG+="uaccess", TAG+="udev-acl"
```
to:
```
KERNEL=="hidraw*", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
```
