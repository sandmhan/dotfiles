# Network Attached Storage (NAS) VM Host Configuration
# Full-featured NAS deployment with NFS, SMB, and backup services
{ config, lib, pkgs, userSettings, systemSettings, ... }:
with lib;
{
  imports = [
    ../server/default.nix
    ../server/hardware-configuration.nix
    ../../systemModules/nas.nix
    ../../systemModules/sops.nix
  ];

  # System identification
  networking.hostName = systemSettings.hostname;

  # Enable comprehensive NAS stack
  homelab.nas = {
    enable = true;
    deploymentType = "vm";
    resourceProfile = "standard";

    # Storage configuration
    storage = {
      basePath = "/srv/nas";

      # Configure shares for homelab services
      shares = {
        "media" = {
          path = "/srv/nas/media";
          description = "Media files for Jellyfin and Frigate";
          readOnly = false;
          allowedUsers = [ "@users" "jellyfin" "frigate" ];
          allowedHosts = [ "10.0.0.0/16" ];
        };

        "backups" = {
          path = "/srv/nas/backups";
          description = "Backup storage for homelab services";
          readOnly = false;
          allowedUsers = [ "@users" "backup" ];
          allowedHosts = [ "10.0.0.0/16" ];
        };

        "documents" = {
          path = "/srv/nas/documents";
          description = "Document and file storage";
          readOnly = false;
          allowedUsers = [ "@users" ];
          allowedHosts = [ "10.0.0.0/16" ];
        };

        "archives" = {
          path = "/srv/nas/archives";
          description = "Long-term archive storage";
          readOnly = false;
          allowedUsers = [ "@users" ];
          allowedHosts = [ "10.0.0.0/16" ];
        };

        "config" = {
          path = "/srv/nas/config";
          description = "Configuration backups and templates";
          readOnly = false;
          allowedUsers = [ "@users" ];
          allowedHosts = [ "10.0.0.0/16" ];
        };
      };
    };

    # NFS configuration
    nfs = {
      enable = true;
      version = 4;
      # Additional exports for specific services
      exports = [
        "/srv/nas/media 10.0.20.108(rw,sync,no_subtree_check) 10.0.20.105(rw,sync,no_subtree_check)"  # AI and NVR
      ];
    };

    # SMB configuration for Windows compatibility
    smb = {
      enable = true;
      workgroup = "HOMELAB";
      netbiosName = "nas";
      security = "user";
    };

    # Comprehensive backup configuration
    backup = {
      enable = true;

      borgbackup = {
        enable = true;
        repositoryPath = "/srv/nas/borg-repos";
        schedule = "daily";
        retention = "keep-daily=7 keep-weekly=4 keep-monthly=6 keep-yearly=2";
      };

      rclone = {
        enable = true;  # For cloud backup sync
      };
    };

    # Full monitoring for VM deployment
    monitoring = {
      enable = true;
      diskHealth = true;
    };
  };

  # Additional firewall rules for NAS services
  networking.firewall = {
    # Standard NAS ports configured by module
    # Custom rules for specific access patterns
    extraCommands = ''
      # Allow full NAS access from management VLAN
      iptables -A INPUT -s 10.0.0.0/24 -p tcp -m multiport --dports 111,2049,139,445 -j ACCEPT
      iptables -A INPUT -s 10.0.0.0/24 -p udp -m multiport --dports 111,137,138 -j ACCEPT

      # Allow NAS access from services VLAN
      iptables -A INPUT -s 10.0.20.0/24 -p tcp -m multiport --dports 111,2049 -j ACCEPT
      iptables -A INPUT -s 10.0.20.0/24 -p udp --dport 111 -j ACCEPT

      # Backup access (SSH for Borg)
      iptables -A INPUT -s 10.0.0.0/16 -p tcp --dport 22 -j ACCEPT
    '';
  };

  # Network performance for file sharing (VM sysctl set by systemModules/nas.nix)
  boot.kernel.sysctl = {
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 87380 134217728";
    "net.ipv4.tcp_wmem" = "4096 65536 134217728";
  };

  # Resource allocation for NAS VM
  # Configure at Proxmox level:
  # qm set <vmid> --cores 4 --memory 8192
  # qm set <vmid> --scsi1 local-zfs:500,size=500G  # Main storage
  # qm set <vmid> --scsi2 local-zfs:100,size=100G  # Backup storage

  # Additional NAS management tools
  environment.systemPackages = with pkgs; [
    # Network file system tools (provided by module)
    # Additional utilities for NAS management
    testdisk      # Disk recovery utilities
    gparted       # Partition management
    btrfs-progs   # Btrfs utilities (if using btrfs)
    zfs           # ZFS utilities (if using ZFS)
  ];

  # Automated cleanup and maintenance
  systemd.services.nas-maintenance = {
    description = "NAS Maintenance and Cleanup";
    startAt = "weekly";

    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "nas-maintenance" ''
        # Clean up old log files
        find /var/log -name "*.log" -mtime +30 -delete

        # Clean up temporary files
        find /tmp -type f -mtime +7 -delete

        # Update file database
        updatedb

        # SMART disk check (if enabled)
        ${optionalString config.homelab.nas.monitoring.diskHealth ''
          smartctl -a /dev/sda || true
        ''}

        echo "NAS maintenance completed at $(date)"
      '';
    };
  };

  # Backup verification service
  systemd.services.backup-verification = mkIf config.homelab.nas.backup.borgbackup.enable {
    description = "Verify Borg Backup Integrity";
    startAt = "monthly";

    serviceConfig = {
      Type = "oneshot";
      User = "backup";
      Group = "backup";
      ExecStart = pkgs.writeShellScript "backup-verify" ''
        cd ${config.homelab.nas.backup.borgbackup.repositoryPath}

        for repo in */; do
          echo "Verifying repository: $repo"
          borg check --progress "$repo" || echo "Warning: Issues found in $repo"
        done

        echo "Backup verification completed at $(date)"
      '';
    };
  };

  # SOPS integration for NAS secrets
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  # Ensure important directories are created with proper permissions
  systemd.tmpfiles.rules = [
    "d /srv/nas 0755 nas nas -"
    "d /srv/nas/media 0755 nas nas -"
    "d /srv/nas/media/movies 0755 nas nas -"
    "d /srv/nas/media/tv 0755 nas nas -"
    "d /srv/nas/media/music 0755 nas nas -"
    "d /srv/nas/media/photos 0755 nas nas -"
    "d /srv/nas/backups 0750 backup backup -"
    "d /srv/nas/documents 0755 nas nas -"
    "d /srv/nas/archives 0755 nas nas -"
    "d /srv/nas/config 0755 nas nas -"
  ];
}