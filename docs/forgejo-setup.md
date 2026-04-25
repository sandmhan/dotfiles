# Forgejo Git Server Setup Guide

## Overview

The Forgejo Git server provides self-hosted Git repository management for the homelab, including repository mirroring from GitHub, Git LFS support, and PostgreSQL-backed storage. It supports both VM and container deployments with intelligent configuration optimization.

## Features

- **Self-hosted Git**: Full Git hosting with web interface
- **GitHub Mirroring**: Mirror repositories from GitHub for local backup and redundancy
- **Git LFS**: Large File Storage for binary assets
- **PostgreSQL Backend**: Reliable database storage with deployment-aware tuning
- **Nginx Reverse Proxy**: Clean URL access with optional SSL
- **Monitoring Integration**: PostgreSQL exporter for Prometheus metrics
- **SOPS Secrets**: Encrypted admin credentials and secret key

## Architecture

```
┌─────────────────┐    HTTPS/SSH    ┌──────────────────┐    SQL     ┌─────────────────┐
│   Git Clients   │◄──────────────►│   Forgejo        │◄──────────►│   PostgreSQL    │
│                 │                │                  │            │                 │
│ • CLI (git)     │                │ • Web UI (:3000) │            │ • forgejo DB    │
│ • IDE           │                │ • SSH (:3022)    │            │ • Session data  │
│ • CI/CD         │                │ • API            │            │ • LFS metadata  │
└─────────────────┘                └──────────────────┘            └─────────────────┘
         │                                  │
         │ :443/:80                          │ :9187
         ▼                                  ▼
┌─────────────────┐                ┌─────────────────┐
│     Nginx       │                │  PG Exporter    │
│  Reverse Proxy  │                │  (Prometheus)   │
└─────────────────┘                └─────────────────┘
```

## Deployment Options

| Option | Resource Usage | Use Case |
|--------|----------------|----------|
| **VM** (`hosts/git/`) | 2 cores, 2-4GB RAM | Full-featured Git server on dedicated hardware |
| **LXC** (`hosts/lxc-git/`) | 1 core, 1GB RAM | Resource-efficient deployment on constrained hardware |

## Prerequisites

### 1. Secrets Configuration

Generate and configure Forgejo secrets:

```bash
# Generate admin password and secret key
FORGEJO_ADMIN_PASSWORD=$(openssl rand -base64 32)
FORGEJO_SECRET_KEY=$(openssl rand -base64 64)

# Create unencrypted secrets file
cat > secrets/forgejo/secrets.yaml << EOF
forgejo-admin-password: $FORGEJO_ADMIN_PASSWORD
forgejo-secret-key: $FORGEJO_SECRET_KEY
EOF

# Encrypt with sops
sops -e -i secrets/forgejo/secrets.yaml

# Verify encryption
sops -d secrets/forgejo/secrets.yaml
```

### 2. Age Key Setup

Ensure the Git host has an age key for secret decryption:

```bash
# Generate age key on git host
ssh user@git-host "sudo mkdir -p /var/lib/sops-nix"
ssh user@git-host "sudo age-keygen -o /var/lib/sops-nix/key.txt"

# Get public key for .sops.yaml
ssh user@git-host "sudo age-keygen -y /var/lib/sops-nix/key.txt"

# Update .sops.yaml with the public key
```

## Deployment

### Option A: VM Deployment (Recommended for Dedicated Hardware)

```bash
# 1. Deploy base VM using proven VMA pattern
qmrestore /var/lib/vz/dump/vzdump-qemu-nixos-*.vma.zst 109 --storage local-zfs

# 2. Configure VM resources
qm set 109 --cores 2 --memory 2048 --name git
qm set 109 --net0 virtio,bridge=vmbr0,firewall=1

# 3. Start VM and get IP
qm start 109

# 4. Deploy Forgejo configuration
nixos-rebuild switch --target-host sandmhan@[VM_IP] --flake .#git --sudo

# 5. Verify services
curl http://[VM_IP]:3000/api/v1/version  # Forgejo API
curl http://[VM_IP]:80/                   # Nginx proxy
```

### Option B: LXC Deployment (Resource-Efficient)

```bash
# 1. Create LXC container (method depends on Proxmox setup)

# 2. Deploy Forgejo configuration to container
nixos-rebuild switch --target-host git@[CONTAINER_IP] --flake .#lxc-git --sudo

# 3. Verify services
curl http://[CONTAINER_IP]:3000/api/v1/version
```

## Configuration

### Module Options

The Forgejo module (`systemModules/forgejo.nix`) provides these options under `homelab.forgejo`:

| Option | Default | Description |
|--------|---------|-------------|
| `enable` | `false` | Enable Forgejo Git server |
| `deploymentType` | `"vm"` | `vm`, `container`, or `hybrid` |
| `resourceProfile` | `"standard"` | `minimal`, `standard`, or `high` |
| `domain` | `"git.homelab.local"` | Domain name for Forgejo |
| `sshPort` | `3022` | SSH port for Git operations |
| `httpPort` | `3000` | HTTP port for web interface |
| `lfs.enable` | `true` | Git LFS support |
| `registration.enable` | `false` | Open user registration |
| `mirroring.enable` | `true` | GitHub mirror support |
| `actions.enable` | `false` | CI/CD runner (Forgejo Actions) |
| `nginx.enable` | `true` | Nginx reverse proxy |
| `postgresExporter.enable` | `true` | Prometheus PostgreSQL exporter |

### PostgreSQL Tuning by Deployment Type

| Setting | Container | VM Minimal | VM Standard | VM High |
|---------|-----------|------------|-------------|---------|
| `shared_buffers` | 64MB | 128MB | 256MB | 512MB |
| `effective_cache_size` | 256MB | 512MB | 1GB | 2GB |
| `work_mem` | 4MB | 8MB | 16MB | 32MB |

### Systemd Resource Limits

| Service | Container | VM Minimal | VM Standard/High |
|---------|-----------|------------|------------------|
| Forgejo | 512M / 50% CPU | 768M / 75% CPU | No hard limits |
| PostgreSQL | 256M / 25% CPU | 512M / 50% CPU | No hard limits |
| Nginx | 64M / 10% CPU | No limits | No hard limits |

## Usage

### Initial Setup

After first deployment, create the admin user:

```bash
# SSH into the git host
ssh user@git-host

# Create admin user via CLI
sudo -u forgejo forgejo admin user create \
  --username admin \
  --password "$(sudo cat /run/secrets/forgejo-admin-password)" \
  --email admin@homelab.local \
  --admin
```

### Mirroring a GitHub Repository

1. Log into the Forgejo web interface
2. Click "+" > "New Migration"
3. Select "GitHub" as the source
4. Enter the repository URL
5. Enable "Mirror" to keep it synchronized

### Git SSH Access

```bash
# Clone via Forgejo SSH
git clone ssh://git@git.homelab.local:3022/user/repo.git

# Add SSH config for convenience
# ~/.ssh/config
Host git.homelab.local
  Port 3022
  User git
```

### Git LFS

```bash
# Initialize LFS in a repository
git lfs install
git lfs track "*.bin" "*.zip" "*.tar.gz"
git add .gitattributes
git commit -m "Enable Git LFS tracking"
```

## Network Access

### Firewall Configuration

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| SSH Management | 22 | TCP | Host SSH access |
| HTTP | 80 | TCP | Nginx reverse proxy |
| HTTPS | 443 | TCP | Nginx SSL (when configured) |
| Git SSH | 3022 | TCP | Git SSH operations |
| Node Exporter | 9100 | TCP | Prometheus system metrics |
| PG Exporter | 9187 | TCP | PostgreSQL metrics |

### DNS Configuration

```bash
# Add to your DNS server or /etc/hosts
10.0.20.206 git.homelab.local
```

## Monitoring Integration

### Adding to Prometheus

Add the Git server to the monitoring configuration:

```nix
# In hosts/monitor/default.nix
homelab.monitoring.prometheus.staticTargets = {
  "node-exporters" = [
    # ... existing targets
    "10.0.20.206:9100"  # Git server
  ];
};

homelab.monitoring.prometheus.additionalScrapeConfigs = [
  {
    job_name = "forgejo-postgres";
    static_configs = [
      {
        targets = [ "10.0.20.206:9187" ];
        labels = { service = "forgejo-postgres"; };
      }
    ];
  }
];
```

## Maintenance

### Backup

```bash
# Backup Forgejo data
rsync -av git-host:/var/lib/forgejo/ /backup/forgejo/

# Backup PostgreSQL database
ssh git-host "sudo -u postgres pg_dump forgejo" > /backup/forgejo-db.sql

# Backup Git LFS objects
rsync -av git-host:/var/lib/forgejo/lfs/ /backup/forgejo-lfs/
```

### Updates

```bash
# Update Forgejo
nixos-rebuild switch --target-host user@git-host --flake .#git --sudo

# Restart services if needed
ssh git-host "sudo systemctl restart forgejo postgresql nginx"
```

## Troubleshooting

### Common Issues

#### Forgejo Not Starting
```bash
# Check service status
ssh git-host "sudo systemctl status forgejo"
ssh git-host "sudo journalctl -u forgejo -f"

# Check PostgreSQL is running
ssh git-host "sudo systemctl status postgresql"
ssh git-host "sudo -u postgres pg_isready"
```

#### Cannot Push via SSH
```bash
# Test SSH connectivity
ssh -p 3022 git@git.homelab.local

# Check Forgejo SSH server
ssh git-host "sudo ss -tlnp | grep 3022"

# Verify firewall
ssh git-host "sudo iptables -L | grep 3022"
```

#### Database Connection Issues
```bash
# Check PostgreSQL logs
ssh git-host "sudo journalctl -u postgresql -f"

# Test database connection
ssh git-host "sudo -u forgejo psql -d forgejo -c 'SELECT 1'"
```

#### Secret Decryption Failed
```bash
# Verify age key
ssh git-host "sudo ls -la /var/lib/sops-nix/key.txt"

# Test secret decryption
sops -d secrets/forgejo/secrets.yaml

# Check secret files at runtime
ssh git-host "sudo ls -la /run/secrets/"
```

### Log Analysis

```bash
# Forgejo logs
ssh git-host "sudo journalctl -u forgejo -f"

# PostgreSQL logs
ssh git-host "sudo journalctl -u postgresql -f"

# Nginx logs
ssh git-host "sudo journalctl -u nginx -f"

# Health check results
ssh git-host "sudo journalctl -u forgejo-health-check"
```

## Integration with Other Services

### CI/CD with Forgejo Actions

```nix
# Enable Actions runner in host configuration
homelab.forgejo.actions.enable = true;
```

### Webhook Integration

Configure webhooks in Forgejo to notify other homelab services:
- Matrix notifications for push events
- Deployment triggers for infrastructure changes
- Monitoring alerts for repository events
