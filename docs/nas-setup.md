# Network Attached Storage (NAS) Setup Guide

## Overview

The NAS service provides centralized file sharing, backup storage, and data management for the entire homelab infrastructure. It supports both VM and container deployments with intelligent configuration optimization based on deployment type and resource profile.

## Features

- **NFS Server**: High-performance file sharing for Unix/Linux systems
- **SMB/CIFS Server**: Windows and macOS compatibility (VM deployment only)
- **Automated Backup**: BorgBackup for deduplicating backups (VM deployment)
- **Cloud Sync**: rclone integration for cloud storage synchronization
- **Health Monitoring**: SMART disk monitoring and storage alerts
- **Flexible Deployment**: Full VM or lightweight container options

## Architecture

```
┌─────────────────┐    NFS/SMB     ┌──────────────────┐    Web/SSH    ┌─────────────────┐
│   Client Apps   │◄──────────────►│   NAS Service    │◄──────────────►│   Management    │
│                 │                │                  │                │                 │
│ • Jellyfin      │                │ • File Sharing   │                │ • SSH Access    │
│ • Frigate       │                │ • Backup Storage │                │ • Health Checks │
│ • User Devices  │                │ • Cloud Sync     │                │ • Monitoring    │
└─────────────────┘                └──────────────────┘                └─────────────────┘
                                             │
                                             │ Storage
                                             ▼
                                   ┌──────────────────┐
                                   │   Storage Pool   │
                                   │                  │
                                   │ • Media Files    │
                                   │ • Backups        │
                                   │ • Documents      │
                                   │ • Archives       │
                                   └──────────────────┘
```

## Configuration

The NAS module follows the new systemModules architecture with intelligent defaults based on deployment type and resource profile.

### VM Configuration (Full Features)

```nix
# hosts/nas/default.nix
homelab.nas = {
  enable = true;
  deploymentType = "vm";
  resourceProfile = "standard";

  # Storage configuration
  storage = {
    basePath = "/srv/nas";
    
    shares = {
      "media" = {
        path = "/srv/nas/media";
        description = "Media files for Jellyfin and Frigate";
        allowedUsers = [ "@users" "jellyfin" "frigate" ];
        allowedHosts = [ "10.0.0.0/16" ];
      };
      
      "backups" = {
        path = "/srv/nas/backups";
        description = "Service backup storage";
        allowedUsers = [ "@users" "backup" ];
        allowedHosts = [ "10.0.0.0/16" ];
      };
    };
  };

  # Full NFS and SMB support
  nfs = {
    enable = true;
    version = 4;
  };

  smb = {
    enable = true;
    workgroup = "HOMELAB";
    security = "user";
  };

  # Comprehensive backup services
  backup = {
    enable = true;
    borgbackup.enable = true;
    rclone.enable = true;
  };

  # Full monitoring with disk health
  monitoring = {
    enable = true;
    diskHealth = true;
  };
};
```

### Container Configuration (Lightweight)

```nix
# hosts/lxc-nas/default.nix
homelab.nas = {
  enable = true;
  deploymentType = "container";
  resourceProfile = "minimal";

  # Basic storage shares
  storage = {
    basePath = "/srv/nas";
    
    shares = {
      "shared" = {
        path = "/srv/nas/shared";
        description = "Basic shared storage";
        allowedUsers = [ "@users" ];
        allowedHosts = [ "10.0.0.0/16" ];
      };
    };
  };

  # NFS only (SMB disabled automatically)
  nfs.enable = true;
  smb.enable = false;  # Automatically disabled in containers

  # Backup services disabled for resource efficiency
  backup.enable = false;

  # Basic monitoring without disk health
  monitoring = {
    enable = true;
    diskHealth = false;  # Disabled in containers
  };
};
```

## Deployment

### Prerequisites

1. **Network Setup**: Ensure homelab VLANs are configured
2. **Storage Planning**: Calculate storage needs for shares and retention
3. **DNS Configuration**: Set up hostname resolution

### Storage Planning

```bash
# Estimate storage requirements
# Media: ~2TB for movies/TV/music/photos
# Backups: 20-30% of total homelab data
# Documents: ~100GB for personal files
# Archives: Variable based on long-term storage needs

# Example calculation for VM deployment:
# - 2TB for media
# - 500GB for backups  
# - 100GB for documents
# - 500GB for archives
# Total: ~3.1TB + overhead = 4TB recommended
```

### VM Deployment

1. **Create and Configure VM**:
   ```bash
   # Create VM from base VMA image
   qmrestore /var/lib/vz/dump/vzdump-qemu-nixos-*.vma.zst 101 --storage local-zfs
   
   # Configure VM resources
   qm set 101 --cores 4 --memory 8192 --name nas
   qm set 101 --net0 virtio,bridge=vmbr0,firewall=1
   
   # Add storage volumes
   qm set 101 --scsi1 local-zfs:vm-101-disk-1,size=500G    # Main NAS storage
   qm set 101 --scsi2 local-zfs:vm-101-disk-2,size=100G    # Backup storage
   
   # Start VM
   qm start 101
   ```

2. **Deploy NAS Configuration**:
   ```bash
   # Wait for VM to boot and get IP address
   # Deploy configuration
   nixos-rebuild switch --target-host sandmhan@10.0.20.101 --flake .#nas --sudo
   ```

3. **Verify NAS Services**:
   ```bash
   # Test SSH access
   ssh sandmhan@10.0.20.101
   
   # Check NFS exports
   showmount -e 10.0.20.101
   
   # Check SMB shares
   smbclient -L //10.0.20.101 -N
   
   # Test file access
   sudo mkdir /mnt/test
   sudo mount -t nfs4 10.0.20.101:/srv/nas/media /mnt/test
   ls /mnt/test
   sudo umount /mnt/test
   ```

### Container Deployment

1. **Create LXC Container**:
   ```bash
   # Note: LXC creation varies by Proxmox setup
   # This is a placeholder for actual LXC creation process
   
   # Deploy configuration once container is running
   nixos-rebuild switch --target-host nasadmin@10.0.20.201 --flake .#lxc-nas --sudo
   ```

2. **Verify Container NAS**:
   ```bash
   # Check container status
   ssh nasadmin@10.0.20.201
   
   # Verify NFS service
   systemctl status nfs-server
   showmount -e localhost
   
   # Test storage access
   df -h /srv/nas
   ```

## Service Integration

### Media Server Integration (Jellyfin)

```nix
# In Jellyfin host configuration
fileSystems."/var/lib/jellyfin/media" = {
  device = "nas.homelab.local:/srv/nas/media";
  fsType = "nfs4";
  options = [ "rw" "bg" "hard" "intr" "tcp" ];
};

# Jellyfin service configuration
services.jellyfin = {
  enable = true;
  # Media library will be available at /var/lib/jellyfin/media
};
```

### NVR Integration (Frigate)

```nix
# In Frigate host configuration
fileSystems."/var/lib/frigate/recordings" = {
  device = "nas.homelab.local:/srv/nas/recordings";
  fsType = "nfs4";
  options = [ "rw" "bg" "hard" "intr" "tcp" ];
};

# Frigate storage configuration
services.frigate.settings.record = {
  path = "/var/lib/frigate/recordings";
  # Frigate will write recordings to NAS storage
};
```

### Backup Client Configuration

```nix
# Example: Backup Matrix server to NAS
services.borgbackup.jobs.matrix-backup = {
  paths = [ "/var/lib/matrix-synapse" ];
  repo = "backup@nas.homelab.local:borg-repos/matrix";
  encryption = {
    mode = "repokey-blake2";
    passCommand = "cat /run/secrets/borg-passphrase";
  };
  startAt = "daily";
  prune.keep = {
    daily = 7;
    weekly = 4;
    monthly = 6;
  };
};
```

## Storage Management

### Share Administration

```bash
# Add a new share to existing NAS
# 1. Update configuration in hosts/nas/default.nix
# 2. Deploy updated configuration
nixos-rebuild switch --target-host sandmhan@nas-ip --flake .#nas --sudo

# Manual share management (temporary)
sudo mkdir -p /srv/nas/new-share
sudo chown nas:nas /srv/nas/new-share
sudo chmod 755 /srv/nas/new-share

# Export new share (temporary until config deployment)
echo "/srv/nas/new-share 10.0.0.0/16(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
sudo exportfs -ra
```

### User and Permission Management

```bash
# Add user to NAS access
sudo useradd -M -s /bin/false newuser
sudo smbpasswd -a newuser  # For SMB access

# Set up group permissions
sudo usermod -a -G nas newuser

# Configure directory permissions
sudo chown -R nas:nas /srv/nas/shared-directory
sudo chmod -R 775 /srv/nas/shared-directory
```

### Backup Management

```bash
# List backup repositories
sudo -u backup borg list /srv/nas/borg-repos/homelab

# Check repository integrity
sudo -u backup borg check /srv/nas/borg-repos/homelab

# Extract files from backup
sudo -u backup borg extract /srv/nas/borg-repos/homelab::archive-name path/to/file

# Prune old backups manually
sudo -u backup borg prune /srv/nas/borg-repos/homelab \
  --keep-daily=7 --keep-weekly=4 --keep-monthly=6
```

## Monitoring and Maintenance

### Health Monitoring

```bash
# Check NAS service health
curl http://nas.homelab.local:9100/metrics | grep filesystem

# Monitor disk usage
df -h /srv/nas/*

# Check SMART status (VM deployments)
sudo smartctl -H /dev/sda
sudo smartctl -a /dev/sda

# Check NFS statistics
nfsstat -s

# Check SMB connections
sudo smbstatus
```

### Performance Monitoring

```bash
# Monitor I/O performance
iostat -x 1

# Check network file access
nethogs

# Monitor active connections
ss -tuln | grep -E "(2049|445|139)"

# Check file locking
sudo lslocks
```

### Automated Health Checks

The NAS service includes automated health monitoring:

```bash
# VM health check (runs daily)
systemctl status nas-maintenance.service
journalctl -u nas-maintenance.service

# Container health check (runs every 30 minutes)
systemctl status nas-health-check.service
journalctl -u nas-health-check.service
```

## Troubleshooting

### Common Issues

#### NFS Access Problems

```bash
# Check if NFS server is running
systemctl status nfs-server

# Verify exports are loaded
sudo exportfs -v

# Check firewall rules
sudo iptables -L -n | grep -E "(111|2049)"

# Test from client
showmount -e nas.homelab.local
sudo mount -v -t nfs4 nas.homelab.local:/srv/nas/media /mnt/test
```

#### SMB Connection Issues

```bash
# Check SMB service status
systemctl status samba-smbd samba-nmbd

# Test SMB connectivity
smbclient -L //nas.homelab.local -N

# Check SMB configuration
sudo testparm

# View active SMB sessions
sudo smbstatus
```

#### Storage Space Issues

```bash
# Check disk usage by directory
sudo du -sh /srv/nas/*

# Find large files
sudo find /srv/nas -type f -size +1G -exec ls -lh {} \;

# Clean up old backup snapshots
sudo -u backup borg prune /srv/nas/borg-repos/* --dry-run

# Check for disk errors
sudo dmesg | grep -i "error\|fail"
```

#### Permission Problems

```bash
# Fix ownership issues
sudo chown -R nas:nas /srv/nas

# Reset share permissions
sudo chmod -R 755 /srv/nas
sudo find /srv/nas -type f -exec chmod 644 {} \;

# Check SELinux/AppArmor (if enabled)
sudo getenforce  # SELinux
sudo aa-status   # AppArmor
```

### Performance Issues

#### Slow File Transfers

```bash
# Check network performance
iperf3 -s  # On NAS
iperf3 -c nas.homelab.local  # From client

# Optimize NFS mount options
sudo mount -o rw,bg,hard,intr,tcp,rsize=32768,wsize=32768 \
  nas.homelab.local:/srv/nas/media /mnt/media

# Check disk I/O
sudo iotop -ao
```

#### High CPU/Memory Usage

```bash
# Check process usage
htop
sudo ps aux | grep -E "(nfs|smb)"

# Monitor system resources
vmstat 1
iostat -x 1

# Check for resource limits (containers)
systemctl show nfs-server | grep Memory
```

### Log Analysis

```bash
# NFS server logs
journalctl -u nfs-server -f

# SMB logs
sudo tail -f /var/log/samba/log.smbd

# System logs related to storage
journalctl -u systemd-tmpfiles-resetup
dmesg | grep -i storage
```

## Security Considerations

### Network Security

```bash
# Restrict NFS access to homelab networks only
iptables -A INPUT -s 10.0.0.0/16 -p tcp --dport 2049 -j ACCEPT
iptables -A INPUT -p tcp --dport 2049 -j DROP

# Use NFSv4 for better security
mount -t nfs4 -o sec=krb5 nas.homelab.local:/srv/nas/secure /mnt/secure
```

### File Security

```bash
# Set up restricted shares
sudo mkdir /srv/nas/sensitive
sudo chown root:sensitive-group /srv/nas/sensitive
sudo chmod 750 /srv/nas/sensitive

# Use SMB encryption (when available)
# Add to SMB configuration: server signing = mandatory
```

### Backup Security

```bash
# Enable Borg encryption for sensitive backups
borg init --encryption=repokey-blake2 /srv/nas/borg-repos/sensitive

# Secure backup keys
sudo chmod 600 /root/.ssh/borg_key
```

## Migration and Maintenance

### Data Migration

```bash
# Migrate existing data to NAS
rsync -av --progress /old/storage/ nas.homelab.local:/srv/nas/media/

# Migrate with preserved permissions
sudo rsync -avX --progress /source/ /srv/nas/destination/
```

### Service Updates

```bash
# Update NAS configuration
nixos-rebuild switch --target-host sandmhan@nas-ip --flake .#nas --sudo

# Backup configuration before updates
sudo cp -r /etc/exports /etc/samba/smb.conf /backup/nas-config-$(date +%Y%m%d)/
```

### Disaster Recovery

```bash
# Backup NAS configuration
sudo tar czf nas-config-backup.tar.gz /etc/exports /etc/samba/ /srv/nas/

# Document recovery procedures
# 1. Rebuild NAS server with same configuration
# 2. Restore storage volumes
# 3. Deploy NixOS configuration  
# 4. Restore data from backups
# 5. Verify services and client access
```

This comprehensive NAS setup provides reliable, scalable storage infrastructure for the entire homelab with appropriate monitoring, security, and maintenance procedures.