# Remaining Setup Tasks for Homelab Infrastructure

## Overview

This document outlines the remaining tasks needed to complete the homelab infrastructure setup, particularly focusing on sops secrets management and WireGuard VPN deployment.

## Priority Tasks

### 1. Complete sops-nix Secrets Integration

#### 1.1 Merge feat/sops Branch
```bash
# Check current branch status
git status

# Merge feat/sops branch
git checkout main  # or your target branch
git merge feat/sops

# Resolve any conflicts if they exist
```

#### 1.2 Generate Age Keys for All Hosts

**For each host that needs secrets access:**

```bash
# Generate age keypair for each host
ssh user@host "sudo mkdir -p /var/lib/sops-nix"
ssh user@host "sudo age-keygen -o /var/lib/sops-nix/key.txt"

# Get the public key to add to .sops.yaml
ssh user@host "sudo age-keygen -y /var/lib/sops-nix/key.txt"
```

**Update .sops.yaml with actual public keys:**
```yaml
keys:
  - &admin_age age1your_admin_key_here
  - &gaia_key age1your_gaia_public_key_here
  - &nvr_key age1your_nvr_public_key_here  
  - &matrix_key age1your_matrix_public_key_here
  - &vpn_key age1your_vpn_public_key_here
```

#### 1.3 Populate Secret Files

**WireGuard Secrets (`secrets/wireguard/secrets.yaml`):**
```bash
# 1. Generate WireGuard server keys
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo $SERVER_PRIVATE_KEY | wg pubkey)

# 2. Generate client keys for each device
CLIENT_PRIVATE_KEY_LAPTOP=$(wg genkey)
CLIENT_PUBLIC_KEY_LAPTOP=$(echo $CLIENT_PRIVATE_KEY_LAPTOP | wg pubkey)

CLIENT_PRIVATE_KEY_PHONE=$(wg genkey)
CLIENT_PUBLIC_KEY_PHONE=$(echo $CLIENT_PRIVATE_KEY_PHONE | wg pubkey)

# 3. Create unencrypted secrets file
cat > secrets/wireguard/secrets.yaml << EOF
server-private-key: $SERVER_PRIVATE_KEY
clients: |
  [
    {
      "name": "laptop-framework", 
      "publicKey": "$CLIENT_PUBLIC_KEY_LAPTOP",
      "allowedIPs": ["10.100.0.2/32"],
      "comment": "Framework laptop"
    },
    {
      "name": "phone-android",
      "publicKey": "$CLIENT_PUBLIC_KEY_PHONE", 
      "allowedIPs": ["10.100.0.3/32"],
      "comment": "Android phone"
    }
  ]
EOF

# 4. Encrypt the file with sops
sops -e -i secrets/wireguard/secrets.yaml

# 5. Update hosts/vpn/default.nix with server public key
# Replace YOUR_SERVER_PUBLIC_KEY_HERE with $SERVER_PUBLIC_KEY

# 6. Save client private keys securely for device configuration
echo "Laptop private key: $CLIENT_PRIVATE_KEY_LAPTOP"
echo "Phone private key: $CLIENT_PRIVATE_KEY_PHONE"
```

**Matrix Secrets (if not already done):**
```bash
# Generate Matrix registration shared secret
MATRIX_REGISTRATION_SECRET=$(openssl rand -base64 32)

# Generate PostgreSQL password
POSTGRES_PASSWORD=$(openssl rand -base64 24)

# Create and encrypt Matrix secrets
cat > secrets/matrix/secrets.yaml << EOF
registration_shared_secret: $MATRIX_REGISTRATION_SECRET
postgres_password: $POSTGRES_PASSWORD
EOF

sops -e -i secrets/matrix/secrets.yaml
```

**Other Required Secrets:**
- `secrets/shared/secrets.yaml` - Cross-service credentials
- `secrets/user/personal.yaml` - Personal configuration
- Additional service-specific secret files as services are deployed

### 2. Deploy WireGuard VPN Server

#### 2.1 Build and Test Configuration
```bash
# Test the VPN configuration builds correctly
nix build .#vpn --dry-run

# If successful, build the actual configuration
nix build .#vpn
```

#### 2.2 Deploy VPN Server

**Option A: Dedicated VM (Recommended)**
```bash
# Use proven VMA + target-host deployment pattern
qmrestore /var/lib/vz/dump/vzdump-qemu-nixos-*.vma.zst 106 --storage local-zfs
qm set 106 --cores 1 --memory 1024 --name vpn
qm set 106 --net0 virtio,bridge=vmbr0,firewall=1
qm start 106

# Deploy VPN configuration once IP is assigned
nixos-rebuild switch --target-host sandmhan@[VPN_VM_IP] --flake .#vpn --sudo
```

**Option B: Add to Existing VM (Resource Constrained)**
```bash
# Add WireGuard module to existing VM (e.g., matrix or nixos-builder)
# Update the host's default.nix to import ../../systemModules/wireguard.nix
# Then deploy: nixos-rebuild switch --target-host user@host --flake .#hostname
```

#### 2.3 Configure Router Port Forwarding
```bash
# Forward UDP 51820 from router to VPN server IP
# Router config varies by model - typically in NAT/Port Forwarding section
External Port: 51820 (UDP)
Internal IP: [VPN_VM_IP]
Internal Port: 51820 (UDP)
```

#### 2.4 Test VPN Connectivity
```bash
# On VPN server, check WireGuard status
sudo wg show

# From client device, test connection
# Configure client with generated private key and server public key
# Test connectivity: ping 10.0.0.1
```

### 3. Build Additional Service Configurations

#### 3.1 Monitoring Stack (`systemModules/monitoring.nix`)
```bash
# Build Prometheus + Grafana configuration
# Test: nix build .#lxc-monitor --dry-run  # or .#monitor for VM version

# Key components to implement:
# - Prometheus with scrape configs for all VMs
# - Grafana with default dashboards
# - Node exporters on all hosts
# - Integration with alerting (future)
```

#### 3.2 NAS Configuration (`systemModules/nas.nix`)
```bash
# Build NFS/Samba server configuration  
# Test: nix build .#lxc-nas --dry-run

# Key components:
# - NFS exports for /srv/media, /srv/recordings, /srv/backups
# - Samba shares for Windows/Mac access
# - Backup automation (borgbackup or restic)
# - Storage health monitoring (smartd)
```

#### 3.3 Git Server (`systemModules/forgejo.nix`)
```bash
# Build Forgejo configuration
# Test: nix build .#lxc-git --dry-run

# Key components:
# - Forgejo with PostgreSQL backend
# - Nginx reverse proxy
# - SSH on port 3022
# - GitHub repo mirroring setup
```

#### 3.4 Matrix Agent Control Plane (`systemModules/matrix-agent-bridge.nix`)
```bash
# Enhance existing Matrix configuration with bot service
# Add remote agent control capabilities via Matrix chat

# Key components:
# - Matrix bot user for agent interaction
# - Command parsing and execution
# - Integration with NixOS Builder for autonomous deployments
# - Status reporting to dedicated Matrix rooms
```

### 4. Network Infrastructure Setup

#### 4.1 VLAN Configuration (Future — Not Yet Implemented)

> **Note:** All services currently run on the flat `10.0.0.0/24` network. VLAN setup is deferred until after core services are deployed and stable.

```bash
# Future: Configure Cisco 3750G switch with planned VLANs:
# VLAN 1: 10.0.0.0/24 (Management)
# VLAN 10: 10.0.10.0/24 (IoT devices)  
# VLAN 20: 10.0.20.0/24 (Services)
# VLAN 30: 10.0.30.0/24 (Guest)

# Future: Update Protectli router configuration
# Future: Configure inter-VLAN routing and firewall rules
```

#### 4.2 DNS Configuration
```bash
# Set up internal DNS for homelab services
# Option A: Pi-hole or AdGuard Home
# Option B: Simple dnsmasq configuration
# Option C: Existing router DNS customization

# Add records for:
# matrix.sandmhan.dev -> Matrix server IP
# grafana.sandmhan.dev -> Monitoring server IP  
# etc.
```

### 5. Service Deployment Strategy

Due to resource constraints on the Dell node, deploy services selectively:

#### 5.1 Phase 1 (Deploy Now - Essential Services)
```bash
# 1. WireGuard VPN (enables remote management)
nixos-rebuild switch --target-host user@vpn-host --flake .#vpn

# 2. Monitoring Stack (observability foundation)
nixos-rebuild switch --target-host user@monitor-host --flake .#lxc-monitor
```

#### 5.2 Phase 2 (Deploy When Resources Allow)
```bash
# 3. NAS Services (storage foundation)
nixos-rebuild switch --target-host user@nas-host --flake .#lxc-nas

# 4. Git Server (development workflow)
nixos-rebuild switch --target-host user@git-host --flake .#lxc-git

# 5. Matrix Agent Control (autonomous operations)
nixos-rebuild switch --target-host user@matrix-host --flake .#matrix
```

#### 5.3 Phase 3 (Requires Gaming PC Node)
```bash
# GPU-dependent services wait for Gaming PC repurposing:
# - AI Server (llama.cpp, whisper, ComfyUI)
# - Media Server (nixflix stack with GPU transcoding) 
# - Frigate NVR (AI detection via local API)
# - Fitness Tracking (wger)
```

### 6. Documentation and Maintenance

#### 6.1 Update Infrastructure Registry
```bash
# Update docs/infrastructure-registry.md as services are deployed
# Include actual IP addresses, resource allocations, and status
```

#### 6.2 Create Operational Runbooks
```bash
# Document common operations:
# - Adding new WireGuard clients
# - Deploying configuration changes
# - Monitoring and alerting procedures
# - Backup and recovery procedures
# - Security incident response
```

#### 6.3 Backup Strategy
```bash
# Implement comprehensive backup:
# - VM snapshots in Proxmox
# - Configuration backup (git + external storage)
# - Secret backup (encrypted, separate from sops files)
# - Data backup (NAS content, user data)
```

## Success Metrics

- [ ] **WireGuard VPN**: Remote access to homelab services from anywhere
- [ ] **Secrets Management**: All secrets properly encrypted and managed via sops  
- [ ] **Monitoring**: Complete observability of all infrastructure components
- [ ] **Autonomous Operations**: NixOS Builder + Matrix bot enable unattended deployments
- [ ] **Documentation**: All procedures documented and tested
- [ ] **Backup/Recovery**: Disaster recovery procedures validated

## Next Immediate Actions

1. **Generate and configure age keys** for sops-nix
2. **Populate WireGuard secrets** and deploy VPN server
3. **Test remote access** via VPN to homelab services
4. **Build monitoring configuration** for deployment readiness  
5. **Update documentation** as tasks are completed

This approach ensures a solid foundation for autonomous homelab management while respecting current resource constraints.