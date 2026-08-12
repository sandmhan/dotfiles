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
| Google Glass | `Gaia_Nursery_2G` | `wlan0` | `10.0.0.175/24` | `f4:f5:e8:12:05:12` |

The two SSIDs are bridged 5 GHz and 2.4 GHz networks on `10.0.0.0/24`. In the router:

1. Create the two DHCP reservations shown above.
2. Confirm client isolation between `Gaia_Nursery` and `Gaia_Nursery_2G` is disabled.
3. Do not add public port forwarding for VNC.

## Declarative system configuration

`systemModules/google-glass.nix` provides:

- `wayvnc` and `openssl` in the system PATH;
- policy rule priority `5260`, directing only `10.0.0.175/32` through the main routing table instead of the accepted Tailscale subnet route;
- an explicit TCP `35900` drop for `tailscale0` in raw `PREROUTING`, before Tailscale's own `ts-input` acceptance;
- a firewall exception for TCP `35900` restricted by source address, destination address, and Wi-Fi interface;
- strict reverse-path filtering.

Tailscale route acceptance remains enabled globally, but it cannot reach the WayVNC listener.

Apply the Gaia NixOS configuration before continuing:

```bash
sudo nixos-rebuild switch --flake .#gaia
```

## Runtime authentication material

WayVNC authentication material must remain outside Git and the Nix store. Run these commands as `sandmhan`; do not use `sudo`:

```bash
umask 077
install -d -m 0700 "${XDG_CONFIG_HOME:-$HOME/.config}/wayvnc-glass" "$XDG_RUNTIME_DIR/wayvnc-glass"

password_file="${XDG_CONFIG_HOME:-$HOME/.config}/wayvnc-glass/password"
openssl rand -base64 6 > "$password_file"
chmod 0600 "$password_file"

openssl req -x509 -newkey rsa:2048 -nodes -days 30 \
  -subj '/CN=gaia-glass-wayvnc' \
  -keyout "$XDG_RUNTIME_DIR/wayvnc-glass/private-key.pem" \
  -out "$XDG_RUNTIME_DIR/wayvnc-glass/certificate.pem"
chmod 0600 "$XDG_RUNTIME_DIR/wayvnc-glass/private-key.pem"
```

The password is exactly eight random Base64 characters (48 bits of entropy). The persistent password file is owned by `sandmhan` with mode `0600`; the certificate, key, and generated WayVNC configuration are runtime-only. Rotate it whenever the Glass client is lost, the WLAN trust boundary changes, or the password may have been observed.

Create the ephemeral configuration without printing the password:

```bash
password_file="${XDG_CONFIG_HOME:-$HOME/.config}/wayvnc-glass/password"
config_file="$XDG_RUNTIME_DIR/wayvnc-glass/wayvnc.ini"

{
  printf '%s\n' \
    'enable_auth=true' \
    'allow_broken_crypto=true' \
    'relax_encryption=true' \
    "password=$(<"$password_file")" \
    "certificate_file=$XDG_RUNTIME_DIR/wayvnc-glass/certificate.pem" \
    "private_key_file=$XDG_RUNTIME_DIR/wayvnc-glass/private-key.pem"
} > "$config_file"
chmod 0600 "$config_file"
```

`allow_broken_crypto=true` and `relax_encryption=true` enable the legacy VNC DES authentication required by the Glass client. The resulting Glass session is unencrypted and does not provide modern end-to-end transport security; the private WLAN and narrow firewall rule remain mandatory.

## Start the view-only display

Create the headless Sway output if it does not already exist, and confirm its name is `HEADLESS-1`. Then run WayVNC as the interactive user:

```bash
wayvnc \
  --config "$XDG_RUNTIME_DIR/wayvnc-glass/wayvnc.ini" \
  --disable-input \
  --output HEADLESS-1 \
  --max-fps=15 \
  --socket "$XDG_RUNTIME_DIR/wayvnc-glass-wifi.ctl" \
  --log-level=info \
  10.0.0.3:35900
```

This listener intentionally remains a foreground user process. Do not bind it to `0.0.0.0`, the Tailscale address, or any public interface. Remote input must remain disabled.

## Acceptance checks

After activating Gaia's configuration, run:

```bash
ip rule show
ip route get 10.0.0.175
systemctl status glass-lan-route
sudo iptables -S INPUT
sudo iptables -S ts-input
sudo iptables -t raw -S PREROUTING
sudo iptables -S nixos-fw
```

The route lookup must include:

```text
10.0.0.175 dev wlp192s0 src 10.0.0.3
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
- passwords in Git, Nix expressions, derivations, command output, or documentation.
