---
title: Data Flow
status: draft
---

# Data Flow

The main operational flow is: flake inputs and host modules are evaluated locally or on a builder, deployments are pushed to NixOS guests, and Proxmox provides VM/LXC lifecycle, networking, storage, and backup substrate.

See [infrastructure-registry.md](infrastructure-registry.md) for host relationships and [operations](../operations/index.md) for service setup details.
