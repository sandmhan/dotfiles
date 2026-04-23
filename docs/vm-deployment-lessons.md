# VM Deployment Lessons Learned

## Successful Approach: VMA Base + Target Host Deployment

**What Worked:**
```bash
# 1. Use proven working VMA (same as Matrix server)
qmrestore /var/lib/vz/dump/vzdump-qemu-nixos-26.05.20260111.ffbc9f8.vma.zst 105 --storage local-zfs

# 2. Configure VM resources  
qm set 105 --cores 4 --memory 8192 --name agent-sandbox

# 3. Fix network (remove invalid MAC)
qm set 105 --net0 virtio,bridge=vmbr0,firewall=1

# 4. Start and get IP
qm start 105
# VM gets DHCP IP (e.g., 10.0.0.160)

# 5. Deploy specific configuration via target-host
nixos-rebuild switch --target-host sandmhan@10.0.0.160 --flake .#agent-sandbox --sudo
```

## Why This Approach Works

### 1. **Proven Foundation**
- Uses exact same VMA that successfully runs Matrix server (VM 102)
- Avoids filesystem creation hangs that plagued custom image builds
- Known-good hardware detection and basic NixOS setup

### 2. **Separation of Concerns**
- **Base Image**: Minimal working NixOS (via proven VMA)
- **Specific Config**: Application-specific setup (via nixos-rebuild)
- No complex image generation with service-specific packages

### 3. **"Minimal Boot First, Features Second"**
- VMA contains only essential NixOS with networking and SSH
- Heavy packages (Claude Code, Docker, development tools) added after boot
- Eliminates filesystem creation bottlenecks during image build

### 4. **Established Workflow**
- Same pattern used for Matrix server deployment
- Leverages existing Proxmox + NixOS integration
- Uses standard `nixos-rebuild --target-host` deployment method

## Failed Approaches and Why

### 1. **Custom VMA Image Generation** ❌
```bash
# This failed consistently
nixos-rebuild build-image --image-variant proxmox --flake .#agentVMA
```

**Problems:**
- **Filesystem Hangs**: `cptofs` hung for 2+ hours during 50GB filesystem creation
- **Complexity**: Complex configurations caused build-time evaluation errors
- **Size Issues**: Large disk allocations triggered filesystem tooling bugs

### 2. **nixos-anywhere Deployment** ❌
```bash
# This had multiple blocking issues  
nixos-anywhere --flake .#agent-sandbox root@10.0.0.159
```

**Problems:**
- **Dependency Hell**: Arch live system had OpenSSL version conflicts
- **kexec Failures**: Could not download/extract kexec due to SSL issues
- **Additional Complexity**: Added Arch Linux as intermediate layer
- **Debugging Overhead**: Multiple moving parts made troubleshooting harder

### 3. **LXC Container Generation** ❌
```bash
# Configuration errors blocked deployment
nixos-generate --format proxmox-lxc --flake .#lxc-monitor
```

**Problems:**
- **Configuration Complexity**: Grafana settings format errors  
- **Service Conflicts**: Module option validation failures
- **Limited Documentation**: Less mature than VM deployment path

### 4. **Direct Production VM Deployment** ❌
```bash
# Terrible idea - would break Matrix server
nixos-rebuild switch --target-host sandmhan@10.0.0.6 --flake .#agent-sandbox
```

**Problems:**
- **Production Risk**: Could break working Matrix homeserver
- **Resource Conflicts**: Matrix and agent services would conflict
- **Single Point of Failure**: Loss of working services

## Key Lessons

### 1. **Reuse Proven Components**
- Don't rebuild what already works
- Matrix VMA is a known-good NixOS base for Proxmox
- Leverage existing successful patterns

### 2. **Separate Image Building from Service Configuration**
- Base images should be minimal and stable
- Service-specific complexity belongs in deployment phase
- Avoid heavy packages in image generation

### 3. **Filesystem Size Matters for Image Generation**
- Large disk allocations (50GB) trigger cptofs hangs
- Start with smaller disks (16GB), resize after deployment
- Image build tools have undocumented size limitations

### 4. **Configuration Syntax is Critical**
- Syntax errors (`in:` vs `in`) block entire deployments
- Validate configurations locally before remote deployment
- Simple typos cause disproportionate debugging overhead

### 5. **Network Configuration Pitfalls**
- Invalid MAC addresses (00:00:00:00:00:00) prevent DHCP
- Proxmox auto-generates valid MACs when not specified
- Network issues appear as "VM not responding" symptoms

## Recommended Deployment Pattern

For all future Proxmox VMs:

1. **Start with proven VMA**: Use `vzdump-qemu-nixos-26.05.20260111.ffbc9f8.vma.zst`
2. **Configure VM resources**: Set cores, memory, name via `qm set`  
3. **Ensure network config**: Use `virtio,bridge=vmbr0,firewall=1` for auto-MAC
4. **Deploy via target-host**: Use `nixos-rebuild --target-host` for services
5. **Test incrementally**: Verify SSH access before complex deployments

## File Locations

- **Working VMA**: `/var/lib/vz/dump/vzdump-qemu-nixos-26.05.20260111.ffbc9f8.vma.zst`
- **VM Configs**: `hosts/{service}/default.nix` 
- **Base Templates**: `hosts/server/default.nix`, `hosts/proxmox-base/default.nix`
- **Deployment Commands**: See project `CLAUDE.md`

## Success Metrics

- ✅ **Matrix Server**: VM 102 at 10.0.0.6 (working production)
- ✅ **Agent Sandbox**: VM 105 at 10.0.0.160 (deployed successfully)
- ✅ **Pattern Validation**: Same VMA + target-host works reliably
- ✅ **Resource Efficiency**: LXC scaffolding ready for lightweight services

This pattern should be the foundation for all future homelab service deployments.