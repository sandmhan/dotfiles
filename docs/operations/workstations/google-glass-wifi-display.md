---
title: Google Glass Wi-Fi Display
status: accepted
---

# Google Glass Wi-Fi Display

This runbook configures Gaia to expose a source-restricted, view-only WayVNC display to Google Glass over the trusted nursery WLAN. It does not expose VNC through Tailscale or any public interface.

## Network topology

| Endpoint | SSID | Interface | Reserved IPv4 | MAC address |
| --- | --- | --- | --- | --- |
| Gaia laptop | `Gaia_Nursery` | `wlp192s0` | `10.0.0.3/24` | `dc:56:7b:03:31:6d` |
| Google Glass | `Gaia_Nursery_2G` | `wlan0` | `10.0.0.12/24` | `f4:f5:e8:12:05:12` |

The two SSIDs are bridged 5 GHz and 2.4 GHz networks on `10.0.0.0/24`. In the router:

1. Create the two DHCP reservations shown above.
2. Confirm client isolation between `Gaia_Nursery` and `Gaia_Nursery_2G` is disabled.
3. Do not add public port forwarding for VNC.

## Declarative system configuration

`systemModules/google-glass.nix` provides:

- `wayvnc` and `openssl` in the system PATH;
- policy rule priority `5260`, directing only `10.0.0.12/32` through the main routing table instead of the accepted Tailscale subnet route;
- an explicit TCP `35900` drop for `tailscale0` in raw `PREROUTING`, before Tailscale's own `ts-input` acceptance;
- a firewall exception for TCP `35900` restricted by source address, destination address, and Wi-Fi interface;
- strict reverse-path filtering.

Tailscale route acceptance remains enabled globally, but it cannot reach the WayVNC listener.

Apply the Gaia NixOS configuration before continuing:

```bash
sudo nixos-rebuild switch --flake .#gaia
```

## Authentication lifecycle

The Glass client persists its VNC password but has no usable keyboard when it is disconnected. The host credential is therefore enrollment state, not disposable runtime state. It must remain outside Git and the Nix store at:

```text
~/.config/wayvnc-glass/password
```

The file must be owned by `sandmhan`, have mode `0600`, and contain exactly eight Base64 characters. `glass-vnc start` fails closed if it is missing, malformed, symlinked, or has the wrong mode. It never creates or rotates this password.

Generate a password only during initial enrollment, while an approved ADB or physical input path is available to place the same value on Glass:

```bash
umask 077
install -d -m 0700 "${XDG_CONFIG_HOME:-$HOME/.config}/wayvnc-glass"
openssl rand -base64 6 > "${XDG_CONFIG_HOME:-$HOME/.config}/wayvnc-glass/password"
chmod 0600 "${XDG_CONFIG_HOME:-$HOME/.config}/wayvnc-glass/password"
```

Keep a protected backup outside Git. If the host copy is lost while Glass still stores the old value, restore that exact credential with mode `0600`; do **not** generate a replacement. Rotate only when Glass can be re-enrolled, the client is lost, the WLAN trust boundary changes, or compromise is suspected.

The certificate, private key, control socket, and generated `wayvnc.ini` remain runtime-only under `$XDG_RUNTIME_DIR`. The `glass-vnc` helper regenerates them on every service start and removes them on a normal stop. `allow_broken_crypto=true` and `relax_encryption=true` enable the legacy VNC DES authentication required by Glass. The resulting session is unencrypted, so the private WLAN and narrow firewall rule remain mandatory.

## Start the view-only display

After applying the Home Manager profile, one host-side command restores the complete session after login or reboot:

```bash
glass-vnc start
```

This manually starts `glass-vnc.service`; it is deliberately not enabled at login. The service:

1. validates and reuses the already-enrolled persistent password;
2. creates or enables `HEADLESS-1` at exactly 640×360@60 Hz and scale 1;
3. assigns workspaces 7, 8, and 9 while restoring laptop focus;
4. regenerates the ephemeral certificate and WayVNC configuration;
5. starts WayVNC with remote input disabled on only `10.0.0.3:35900`.

Manage and inspect the session with:

```bash
glass-vnc status
glass-vnc restart
glass-vnc stop
journalctl --user -u glass-vnc.service
```

`glass-vnc stop` stops the listener but leaves the virtual output available. Manage the output separately when needed:

```bash
glass-display on      # Enforce 640×360@60 Hz and move workspaces 7-9
glass-display off     # Move workspaces 7-9 back, then disable HEADLESS-1
glass-display toggle
glass-display status
```

With no argument, `glass-display` toggles the output. Do not bypass `glass-vnc` with an unrestricted manual WayVNC command, bind to `0.0.0.0`, use a Tailscale address, or enable remote input.

## Troubleshooting without Glass input

| Symptom | Host-side remediation |
| --- | --- |
| `Sway output is unavailable: HEADLESS-1` | Run `glass-vnc start` or `glass-display on`. The helper creates and configures the session-scoped output. |
| `Failed to load config` for `$XDG_RUNTIME_DIR/wayvnc-glass/wayvnc.ini` | Do not invoke WayVNC directly. Run `glass-vnc start` to regenerate runtime material. |
| Glass briefly shows connected, then disconnected | Check `journalctl --user -u glass-vnc.service`. `Invalid username or password` means the host credential does not match the enrolled Glass credential. Restore the protected original; do not rotate it. |
| No listener on `10.0.0.3:35900` | Run `glass-vnc status`, then inspect the service journal. Confirm Gaia still owns `10.0.0.3`. |
| Output exists at 1920×1080 | Run `glass-display on`; merely issuing `swaymsg create_output` leaves the wrong default mode. |

These recovery steps require no keyboard or credential changes on Glass.

## Acceptance checks

After activating Gaia's configuration, run:

```bash
ip rule show
ip route get 10.0.0.12
systemctl status glass-lan-route
sudo iptables -S INPUT
sudo iptables -S ts-input
sudo iptables -t raw -S PREROUTING
sudo iptables -S nixos-fw
```

The route lookup must include:

```text
10.0.0.12 dev wlp192s0 src 10.0.0.3
```

Confirm raw `PREROUTING` drops `tailscale0` TCP `35900` before filter-table processing, regardless of `INPUT`/`ts-input` ordering. Confirm `nixos-fw` also contains the source-, destination-, interface-, and port-restricted Wi-Fi acceptance rule from `systemModules/google-glass.nix`. Once WayVNC is running, confirm it is listening only on the LAN address:

```bash
ss -ltnp | grep '10.0.0.3:35900'
```

From a tailnet peer, verify that both Gaia's Tailscale address and the advertised LAN address reject or time out on TCP `35900`:

```bash
nc -vz -w 3 100.82.221.90 35900
nc -vz -w 3 10.0.0.3 35900
```

Both negative tests must fail. From Glass on `Gaia_Nursery_2G`, the authenticated connection to `10.0.0.3:35900` must succeed.

## Prohibited changes

Do not enable or configure:

- wireless ADB;
- unrestricted TCP port `5900` or `35900`;
- remote VNC input;
- binding on `0.0.0.0`;
- Tailscale-wide VNC exposure;
- public router port forwarding;
- automatic password creation or rotation when Glass cannot be re-enrolled;
- passwords in Git, Nix expressions, derivations, command output, or documentation.
