---
title: KDE Connect Setup and Usage on Gaia
status: accepted
---

# KDE Connect Setup and Usage on Gaia

This guide covers deployment, phone pairing, daily usage, verification, and troubleshooting for KDE Connect on the Gaia Sway desktop and the `sandmhan` Home Manager profile.

## What the integration provides

The repository splits ownership between NixOS and Home Manager:

- `hosts/gaia/default.nix` enables the KDE Connect firewall rules for TCP and UDP ports `1714-1764` without installing a second system-level package.
- `home/modules/kdeconnect.nix` installs KDE Connect, starts `kdeconnectd` with the graphical user session, and provides the Rofi and Waybar integrations.
- `home/options.nix` exposes `myHome.features.enableKDEConnect`.
- `home/profiles/desktop.nix` enables the feature for `sandmhan`.
- `home/modules/wm.nix` places the phone status immediately to the left of the Tailscale/VPN status.
- `home/modules/theming.nix` styles connected phones green and disconnected phones with the muted base color.
- Existing SwayNotificationCenter configuration handles KDE Connect notifications; no second notification daemon is used.

The native KDE Connect tray indicator is disabled because the custom Waybar module provides the same entry point without showing two icons.

## Deploy the configuration

Validate both system and user configurations before activation:

```bash
nix build --dry-run .#nixosConfigurations.gaia.config.system.build.toplevel --show-trace
nix build --dry-run .#homeConfigurations.sandmhan.activationPackage --show-trace
```

Apply the NixOS configuration first so the firewall permits discovery and pairing, then apply Home Manager:

```bash
make gaia
make sandmhan
```

A logout is normally unnecessary. If the Waybar module does not reload after activation, run:

```bash
pkill -SIGUSR2 waybar
```

## Install KDE Connect on the phone

### Android

Install **KDE Connect** from one of these sources:

- F-Droid
- Google Play

F-Droid is a good default when both versions are available and current.

### iPhone

Install **KDE Connect** from the App Store and grant Local Network access. Pairing and basic sharing are available, but iOS background restrictions limit persistent connectivity, notification mirroring, SMS, and automatic clipboard synchronization compared with Android.

## Pair the phone

1. Connect Gaia and the phone to the same non-guest Wi-Fi network.
2. Open KDE Connect on the phone and leave it running during initial pairing.
3. On Gaia, use one of these entry points:
   - Right-click the phone icon in Waybar to open KDE Connect settings.
   - Press `Ctrl+Alt+K`, then select **Open KDE Connect** when no phone is reachable.
   - Launch **KDE Connect** through the normal Rofi application launcher.
4. Select the other device and request pairing from either Gaia or the phone.
5. Accept the pairing request on both devices.
6. Compare the fingerprints shown on both devices before accepting.
7. Wait a few seconds for the Waybar icon to turn green.

KDE Connect primarily uses local-network discovery. Bluetooth is not required. Tailscale and other VPNs normally do not carry KDE Connect's multicast discovery.

A VPN can prevent discovery even when Gaia and the phone are connected to the same Wi-Fi, particularly when the VPN routes back into that same LAN. For initial pairing, disconnect the VPN on both devices. For reliable daily use, configure the VPN client to allow LAN access or exclude Gaia's local subnet (`10.0.0.0/24`) from the tunnel.

## Android permissions and reliability

Grant only the permissions needed for the integrations you intend to use.

| Capability | Phone permission or setting |
| --- | --- |
| Mirrored phone notifications | Notification permission and notification access |
| SMS and call integration | SMS, phone, contacts, and call-log access where offered |
| Sending and receiving files | Files, photos, or media access |
| Browsing phone files from Thunar | Enable filesystem exposure and select directories to expose |
| Clipboard synchronization | Enable the clipboard plugin; newer Android versions may restrict background clipboard access |
| Find/ring phone | Enable the find-device plugin and allow notification/audio behavior |
| Reliable background connection | Set battery usage to **Unrestricted** or disable battery optimization |
| Vendor-specific Android builds | Permit background activity and autostart if those controls exist |
| Local discovery | Allow nearby-device or local-network access when requested |

Recommended KDE Connect plugins on the phone:

- Notification sync
- Clipboard
- Share and receive
- SMS
- Find my phone
- Multimedia control
- Remote input, when connecting to a desktop environment with a compatible RemoteDesktop portal; Gaia's current Sway session does not provide one
- Filesystem exposure/SFTP

For filesystem browsing, open the filesystem plugin settings on the phone and explicitly select the directories Gaia may access.

## Waybar status

The KDE Connect status appears immediately to the left of the Tailscale/VPN icon.

- **Green linked-phone icon:** at least one paired phone is reachable.
- **Muted disconnected-phone icon:** no paired phone is currently reachable.
- **Hover:** shows the number and names of reachable devices.
- **Left-click:** opens the Rofi KDE Connect actions menu.
- **Right-click:** opens the KDE Connect settings application.

Waybar checks connection state every five seconds.

## Rofi menu and keyboard shortcut

Open the actions menu by either:

- Pressing `Ctrl+Alt+K` in Sway.
- Left-clicking the KDE Connect Waybar icon.
- Running `kdeconnect-menu` from a terminal or Rofi's run mode.

When multiple phones are reachable, select a device first. The available actions are:

- **Open KDE Connect settings** — manage pairing and plugins.
- **Ping phone** — display a KDE Connect ping on the phone.
- **Ring phone** — help locate the phone.
- **Send clipboard** — send Gaia's current clipboard contents.
- **Share text** — enter text through Rofi and send it to the phone.
- **Share URL or file** — enter a URL or an absolute local file path.
- **Browse phone files** — mount the phone's exposed filesystem and open it in Thunar.
- **Open SMS** — launch the KDE Connect SMS application.
- **Refresh devices** — request discovery again and reopen the menu.

Successful and failed actions generate normal desktop notifications through SwayNotificationCenter.

## Notifications

Once the phone's notification plugin and Android notification access are enabled, mirrored notifications appear through SwayNotificationCenter. Use the existing notification-center controls:

- Click the notification icon in Waybar.
- Press `Ctrl+Alt+N` to toggle the notification center.

Notification behavior, grouping, do-not-disturb state, and history remain owned by the existing SwayNC configuration.

## Verify the desktop service

Check the user service and discoverable devices:

```bash
systemctl --user status kdeconnect
kdeconnect-cli --list-backends
kdeconnect-cli --refresh
kdeconnect-cli --list-devices
kdeconnect-cli --list-available
```

`--list-available` only shows paired and currently reachable devices. Follow live service logs with:

```bash
journalctl --user -u kdeconnect -f
```

Confirm the evaluated firewall ranges with:

```bash
nix eval --json .#nixosConfigurations.gaia.config.networking.firewall.allowedTCPPortRanges
nix eval --json .#nixosConfigurations.gaia.config.networking.firewall.allowedUDPPortRanges
```

Both outputs should include the range from `1714` through `1764`.

## Troubleshooting

### Devices do not discover each other

1. Confirm both devices are on the same Wi-Fi network.
2. Disconnect VPNs on both Gaia and the phone, even if the VPN endpoint routes back into the same local network.
3. Avoid guest Wi-Fi and networks with client/AP isolation.
4. Keep the phone application open during initial discovery.
5. Run:

   ```bash
   kdeconnect-cli --refresh
   kdeconnect-cli --list-devices
   ```

6. Confirm the Gaia NixOS configuration was applied, not only Home Manager.
7. Restart the desktop service:

   ```bash
   systemctl --user restart kdeconnect
   ```

8. If KDE Connect works with the VPN disconnected, enable the VPN client's LAN-access setting or exclude `10.0.0.0/24` from the tunnel.
9. On Android, verify background activity, local-network access, and battery optimization settings.

### The phone is paired but the icon stays muted

Run:

```bash
kdeconnect-cli --list-available --id-name-only
```

If it returns no devices, KDE Connect considers the phone unreachable. Open the phone app, confirm Wi-Fi connectivity, and refresh devices. If the command shows the phone but Waybar remains stale, reload Waybar:

```bash
pkill -SIGUSR2 waybar
```

### SMS messages appear without contact names

SMS history and contact synchronization use separate KDE Connect plugins. If messages load but senders remain as phone numbers:

1. Grant KDE Connect the **Contacts** permission on Android.
2. Confirm the **Contact synchronization** plugin is enabled for Gaia in the phone application.
3. Confirm the phone is paired and reachable, then force a fresh synchronization on Gaia:

   ```bash
   device_id="$(kdeconnect-cli --list-available --id-only | head -n 1)"
   busctl --user call \
     org.kde.kdeconnect \
     "/modules/kdeconnect/devices/$device_id/contacts" \
     org.kde.kdeconnect.device.contacts \
     synchronizeRemoteWithLocal
   ```

4. Close and reopen `kdeconnect-sms` so it reloads the synchronized contact cache.

A successful D-Bus call normally produces no output. Gaia stores the resulting contact cache under `~/.local/share/kpeoplevcard/kdeconnect-<device-id>/`.

### Remote input does not work on Sway

Gaia's current `xdg-desktop-portal-wlr` backend implements screenshot and screen-sharing portals, but it does not implement `org.freedesktop.portal.RemoteDesktop`. KDE Connect receives the phone's remote-input events but cannot inject them into the Sway session. The journal reports errors similar to:

```text
Unable to handle remote input. RemoteDesktop portal not authenticated
No such interface “org.freedesktop.portal.RemoteDesktop”
```

This is a Gaia desktop-backend limitation, not a missing Android permission. Enabling the remote-input plugin or granting additional phone permissions will not make it work in the current Sway session. Practical alternatives are:

- use KDE Connect remote input in a Plasma/KWin session;
- adopt a RemoteDesktop portal backend that explicitly supports the active wlroots compositor; or
- implement a trusted bridge to Sway's virtual pointer and keyboard protocols.

Do not install a portal backend solely because it advertises the RemoteDesktop interface; it must also support input injection through the active compositor.

### Notifications do not appear

- Confirm the notification plugin is enabled for this paired device.
- Grant Android notification access to KDE Connect.
- Confirm SwayNC is active:

  ```bash
  systemctl --user status swaync
  ```

- Check KDE Connect logs for plugin errors:

  ```bash
  journalctl --user -u kdeconnect --since today
  ```

### Clipboard sharing fails

- Enable the clipboard plugin on both devices.
- Be aware that recent Android releases restrict applications from reading the clipboard in the background.
- Open KDE Connect on the phone and retry **Send clipboard**.

### Phone filesystem does not mount

- Enable the filesystem/SFTP plugin on the phone.
- Select at least one exposed directory in the plugin settings.
- Keep the phone unlocked for the first mount attempt.
- Retry **Browse phone files** and inspect `journalctl --user -u kdeconnect` if it fails.

## Security notes

- Pair only after confirming that the fingerprints shown on Gaia and the phone match.
- Remove devices that are lost, replaced, or no longer trusted.
- The NixOS KDE Connect module opens TCP and UDP ports `1714-1764` on Gaia's normal firewall interfaces.
- Gaia treats `tailscale0` as a trusted firewall interface, so paired-device trust and tailnet membership remain important.
- Public or guest Wi-Fi may expose the listening KDE Connect service to other clients even though pairing still requires approval. Stop the user service when KDE Connect is not wanted:

  ```bash
  systemctl --user stop kdeconnect
  ```

## Disable or roll back

To disable the user integration declaratively, set:

```nix
myHome.features.enableKDEConnect = false;
```

Disabling Home Manager stops managing the daemon and desktop integrations, but the Gaia firewall range remains open until `programs.kdeconnect` is also removed or disabled in `hosts/gaia/default.nix` and the NixOS configuration is rebuilt.
