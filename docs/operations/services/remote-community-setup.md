---
title: Remote Community Setup Runbook
status: draft
---

# Remote Community Setup Runbook

Stage 2 integrates the private `remote-community` flake, encrypted runtime policy, and loopback-only observe service into VM111. It provides no public application access, ADB-over-TCP, emulator ports, or actuation.

## Current target

- Hostname: `remote-community`
- Proxmox VM: `111`
- Reserved DHCP address: `10.0.0.13`
- MAC address: `BC:24:11:FA:CE:FD`
- Resources: 4 cores, 8 GiB maximum RAM with a 4 GiB balloon minimum, 50 GiB disk, CPU type `host`, nested KVM enabled
- SSH: `ssh sandmhan@10.0.0.13`
- Firewall: LAN TCP 22, Tailscale UDP 41641, and tailnet-interface TCP 443; keep plaintext 8080, ADB, and emulator ports closed
- Tailnet HTTPS: `https://remote-community.taila92b61.ts.net`

The first unballooned closure transfer exhausted the 15 GiB Proxmox node and the host OOM killer stopped VM111. VM111 now retains the requested 8 GiB maximum with a 4 GiB balloon minimum. Do not restart VM105 or remove ballooning while VM111 is running without re-evaluating node memory capacity.

## Rollout stages

### 1. Reserve DHCP and DNS

1. The pfSense DHCP reservation for `BC:24:11:FA:CE:FD` at `10.0.0.13` is active.
2. The DNS Resolver host override for `remote-community.homelab.local` resolves to `10.0.0.13` from pfSense.
3. Reconfirm both the reserved address and forward DNS after future network changes.

### 2. Build and deploy stage 2

From an authenticated deployment workstation with SSH access to the private `sandmhan/remote-community` GitHub repository:

```bash
nix flake show
nix build --dry-run .#nixosConfigurations.remote-community.config.system.build.toplevel --show-trace
nix build .#nixosConfigurations.remote-community.config.system.build.toplevel --no-link --show-trace
nixos-rebuild test --target-host sandmhan@10.0.0.13 --flake .#remote-community --use-remote-sudo
ssh sandmhan@10.0.0.13 'curl --fail http://127.0.0.1:8080/healthz'
ssh sandmhan@10.0.0.13 'curl --fail http://127.0.0.1:8080/readyz'
nixos-rebuild switch --target-host sandmhan@10.0.0.13 --flake .#remote-community --use-remote-sudo
```

The `remoteCommunity` flake input uses the private SSH GitHub URL and is content-pinned in `flake.lock`. Deployment workstations must have authorized GitHub SSH access.

### 3. Private SOPS policy

The real policy is encrypted in `secrets/remote-community/secrets.yaml` for the administrator and VM111 SSH-derived age recipients. The host decrypts it into `/run/secrets` and systemd copies it into the service credential directory with `LoadCredential`; plaintext policy never enters the Nix store.

Before deployment:

- confirm `sops --decrypt secrets/remote-community/secrets.yaml >/dev/null` succeeds;
- confirm repository coordinate scans find no plaintext values;
- confirm `services.remote-community` binds only to `127.0.0.1` and does not open port 8080;
- validate `/healthz` and `/readyz` over an SSH-local command before switching.

Device secrets are generated and retained outside Git under `~/.config/remote-community/devices` with mode `0600`. The `android-primary` and `ios-primary` credentials were provisioned through the stdin-only operator command on 2026-08-21; only SHA-256 digests are stored in SQLite. Do not store plaintext device secrets in SOPS on the server.

### 4. Transfer authenticated AVD

Use the upstream secure AVD migration procedure in `/home/sandmhan/repos/remote-community/docs/android-lab.md`. Transfer only a stopped, cold AVD into `/var/lib/remote-community-emulator`; do not copy lock, temporary, snapshot, or cache files.

The authenticated AVD and its existing ADB trust key were migrated over verified SSH on 2026-08-21. Android reached API 35 boot completion, the myQ Community package remained installed, and ADB/emulator listeners were loopback-only. The emulator is manually running, while the unit remains `enableAtBoot=false` pending final UI authentication verification and resource observation.

### 5. Verify emulator boot locally only

After AVD migration, start and inspect the emulator from VM111 only:

```bash
sudo systemctl start remote-community-android-emulator.service
systemctl status remote-community-android-emulator.service
adb devices -l
adb wait-for-device shell getprop sys.boot_completed
adb shell getprop ro.build.version.sdk
```

Expected results: `sys.boot_completed` becomes `1` and `ro.build.version.sdk` reports API 35. Keep ADB local to the VM; never enable ADB-over-TCP or open firewall ports for emulator access.

### 6. Direct Tailscale enrollment and HTTPS

VM111 declares a Tailscale client with no exit-node or subnet-route advertisement. Its UDP transport port is allowed, `tailscale0` permits only TCP 443, and the Rust service remains on loopback. The node was enrolled interactively on 2026-08-21 with key expiry disabled; MagicDNS and HTTPS certificates are enabled.

The enrollment command used no reusable auth-key material:

```bash
sudo tailscale up --hostname=remote-community --accept-routes=false
```

A hardened `remote-community-tailscale-serve.service` waits for the tailnet, resets stale Serve/Funnel state, publishes only the loopback service, retries bounded startup failures, and clears Serve state when disabled. The equivalent operator command is:

```bash
sudo tailscale serve --bg --https=443 http://127.0.0.1:8080
```

Tailscale reports this endpoint as tailnet-only, with Funnel disabled, and presents a valid public certificate for `remote-community.taila92b61.ts.net`. Do not expose plaintext port 8080. Configure OwnTracks only with this HTTPS URL, TLS verification, the provisioned credential IDs, and strong device secrets. Do not commit usernames, passwords, coordinates, or screenshots.

## Safety boundary

This service remains observe-only. It must not unlock, actuate, automate the Android app, reverse engineer private endpoints, or expose any access-action route. Any future actuation design requires a separate security review and ADR before implementation.
