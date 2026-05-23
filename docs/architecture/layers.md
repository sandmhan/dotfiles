---
title: Documentation and System Layers
status: accepted
---

# Layers

| Layer | Repository paths | Notes |
| --- | --- | --- |
| Flake outputs | `flake.nix` | Evaluation entry point. |
| Host classes | `hosts/server`, `hosts/proxmox-base`, `hosts/lxc-base` | To be consolidated by Phase 2. |
| Service modules | `systemModules/` | Preferred reusable service abstraction. |
| User profiles | `home/modules`, `home/profiles` | Keep separate from homelab service roles. |
| Operations docs | `docs/operations/` | Setup guides and runbooks. |
