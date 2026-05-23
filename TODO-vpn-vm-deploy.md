# Tailscale Router Deployment — Completed

The `vpn` VM is deployed as the homelab Tailscale subnet router.

- Canonical status: `docs/infrastructure-registry.md`
- Hostname: `vpn`
- VM ID: `110`
- LAN IP: `10.0.0.168`
- Tailscale access: `ssh sandmhan@100.120.234.19`

This file is retained only as a short status pointer because older notes referenced it during deployment. Future VPN/router changes should be documented in `docs/infrastructure-registry.md` and the relevant service runbook.

WireGuard is retained/planned for optional service-specific use, but Tailscale is the current remote-access path.
