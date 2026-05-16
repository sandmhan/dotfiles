# Homelab Development Rules

- All Proxmox VMs should extend hosts/server/default.nix
- Service modules go in systemModules/
- Use OCI containers when native NixOS services are unavailable
- Always include qemuGuest.enable for Proxmox VMs
- Test configurations with `nix build --dry-run` before deployment
- Use `nixos-rebuild switch --target-host` for remote deployment
