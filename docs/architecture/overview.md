---
title: Architecture Overview
status: accepted
---

# Architecture Overview

This repository is a single flake-based control plane for NixOS hosts, Proxmox VMs/LXCs, and Home Manager profiles.

## Primary layers

- `flake.nix` exposes NixOS and Home Manager outputs.
- `hosts/` contains deployable machines and host-class bases.
- `systemModules/` contains reusable homelab service modules.
- `home/modules/` and `home/profiles/` contain user environment modules.
- `docs/` captures decisions, plans, operations, and evidence.

## Authoritative references

- [Infrastructure registry](infrastructure-registry.md) for deployed/planned VM, CT, IP, and network data.
- [SystemModules architecture](systemmodules-architecture.md) for reusable service module conventions.
- [Architecture assessment](../audits/homelab-architecture-assessment-2026-05-23.md) for findings and target architecture.
- [ADR001](../adr/ADR001-canonical-machine-inventory.md) for inventory direction.
