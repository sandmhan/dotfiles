---
name: vm-deployment
description: "Use for VM provisioning, service-specific configs, and nixos-rebuild automation"
---

# VM Deployment Automation

## Purpose
Automate the provisioning and deployment of new VMs for homelab services.

## Capabilities
- Generate VMA images for Proxmox deployment
- Create service-specific VM configurations
- Automate remote deployment via nixos-rebuild
- Validate deployments and service health
- Manage VM lifecycle (create, update, destroy)

## Deployment Patterns

### New Service VM
1. Create hosts/<service>/default.nix based on hosts/server template
2. Add service-specific systemModules
3. Update flake.nix with new configuration
4. Build and test configuration locally
5. Generate VMA image for Proxmox deployment
6. Deploy and validate service operation

### Service Update
1. Modify configuration in workspace
2. Test changes with nix build --dry-run
3. Deploy to VM with nixos-rebuild switch --target-host
4. Validate service operation and rollback if needed

## Best Practices
- Always test configurations before deployment
- Use staging VMs for major changes
- Maintain deployment documentation
- Monitor resource usage and performance
- Plan for backup and recovery procedures
