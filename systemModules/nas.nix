# Network Attached Storage (NAS) Module
# Provides file sharing, backup, and storage services for homelab infrastructure
{ config, lib, pkgs, ... }:

with lib;

let
  servicePackages = import ./packages.nix { inherit pkgs lib; };
  cfg = config.homelab.nas;
in {
  options.homelab.nas = {
    enable = mkEnableOption "Network Attached Storage services for homelab";

    # Standard deployment options
    deploymentType = mkOption {
      type = types.enum [ "vm" "container" "hybrid" ];
      default = "vm";
      description = "Deployment type - affects storage features and performance optimization";
    };

    resourceProfile = mkOption {
      type = types.enum [ "minimal" "standard" "high" ];
      default = "standard";
      description = "Resource profile for automatic configuration optimization";
    };

    # Storage configuration
    storage = {
      basePath = mkOption {
        type = types.str;
        default = "/srv/nas";
        description = "Base path for NAS storage";
      };

      shares = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            path = mkOption {
              type = types.str;
              description = "Share directory path";
            };
            description = mkOption {
              type = types.str;
              default = "";
              description = "Share description";
            };
            readOnly = mkOption {
              type = types.bool;
              default = false;
              description = "Whether the share is read-only";
            };
            allowedUsers = mkOption {
              type = types.listOf types.str;
              default = [ "@users" ];
              description = "Users/groups allowed to access this share";
            };
            allowedHosts = mkOption {
              type = types.listOf types.str;
              default = [ "10.0.0.0/16" ];
              description = "Network ranges allowed to access this share";
            };
          };
        });
        default = {
          "media" = {
            path = "${cfg.storage.basePath}/media";
            description = "Media files for Jellyfin and other services";
            readOnly = false;
            allowedUsers = [ "@users" "jellyfin" "frigate" ];
          };
          "backups" = {
            path = "${cfg.storage.basePath}/backups";
            description = "Backup storage for homelab services";
            readOnly = false;
            allowedUsers = [ "@users" ];
          };
          "documents" = {
            path = "${cfg.storage.basePath}/documents";
            description = "Document storage";
            readOnly = false;
            allowedUsers = [ "@users" ];
          };
        };
        description = "NFS and SMB shares configuration";
      };
    };

    # NFS configuration
    nfs = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable NFS server";
      };

      version = mkOption {
        type = types.enum [ 3 4 ];
        default = 4;
        description = "NFS protocol version";
      };

      exports = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional NFS exports (auto-generated from shares by default)";
      };
    };

    # SMB/CIFS configuration
    smb = {
      enable = mkOption {
        type = types.bool;
        default = cfg.deploymentType == "vm";
        description = "Enable SMB/CIFS server";
      };

      workgroup = mkOption {
        type = types.str;
        default = "HOMELAB";
        description = "SMB workgroup name";
      };

      netbiosName = mkOption {
        type = types.str;
        default = config.networking.hostName;
        description = "NetBIOS name";
      };

      security = mkOption {
        type = types.enum [ "user" "share" ];
        default = "user";
        description = "SMB security mode";
      };
    };

    # Backup configuration
    backup = {
      enable = mkOption {
        type = types.bool;
        default = cfg.resourceProfile != "minimal";
        description = "Enable automated backup services";
      };

      borgbackup = {
        enable = mkOption {
          type = types.bool;
          default = cfg.backup.enable && cfg.deploymentType == "vm";
          description = "Enable BorgBackup for deduplicating backups";
        };

        repositoryPath = mkOption {
          type = types.str;
          default = "${cfg.storage.basePath}/borg-repos";
          description = "Path for Borg repositories";
        };

        authorizedKeys = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "SSH public keys authorized to access the Borg repository";
          example = [ "ssh-ed25519 AAAA..." ];
        };

        schedule = mkOption {
          type = types.str;
          default = "daily";
          description = "Backup schedule";
        };

        retention = mkOption {
          type = types.str;
          default = "keep-daily=7 keep-weekly=4 keep-monthly=3";
          description = "Backup retention policy";
        };
      };

      rclone = {
        enable = mkOption {
          type = types.bool;
          default = cfg.backup.enable && cfg.resourceProfile == "high";
          description = "Enable rclone for cloud backup synchronization";
        };
      };
    };

    # Monitoring integration
    monitoring = {
      enable = mkOption {
        type = types.bool;
        default = cfg.deploymentType == "vm";
        description = "Enable storage monitoring";
      };

      diskHealth = mkOption {
        type = types.bool;
        default = cfg.monitoring.enable && cfg.deploymentType == "vm";
        description = "Enable disk health monitoring with smartmontools";
      };
    };
  };

  config = mkMerge [
    # Base NAS configuration
    (mkIf cfg.enable {
      # Create NAS user and group
      users.groups.nas = {};
      users.users.nas = {
        isSystemUser = true;
        group = "nas";
        home = cfg.storage.basePath;
        createHome = true;
        homeMode = "755";
      };

      # Create share directories
      systemd.tmpfiles.rules =
        let
          shareRules = mapAttrsToList (name: share:
            "d ${share.path} 0755 nas nas -"
          ) cfg.storage.shares;
        in [
          "d ${cfg.storage.basePath} 0755 nas nas -"
        ] ++ shareRules;

      # Packages from centralized registry
      environment.systemPackages = servicePackages.nas ++
        (optionals (cfg.deploymentType == "vm") servicePackages.nasUtils) ++
        servicePackages.base;

      # Firewall base rules
      networking.firewall.allowedTCPPorts = mkMerge [
        (mkIf cfg.nfs.enable [ 111 2049 ])  # NFS ports
        (mkIf cfg.smb.enable [ 139 445 ])   # SMB ports
      ];

      networking.firewall.allowedUDPPorts = mkMerge [
        (mkIf cfg.nfs.enable [ 111 ])       # NFS portmapper
        (mkIf cfg.smb.enable [ 137 138 ])   # NetBIOS
      ];
    })

    # NFS server configuration
    (mkIf (cfg.enable && cfg.nfs.enable) {
      services.nfs.server = {
        enable = true;
        lockdPort = 4001;
        mountdPort = 4002;
        statdPort = 4000;

        # Auto-generate exports from shares
        exports =
          let
            shareExports = mapAttrsToList (name: share:
              "${share.path} ${concatStringsSep " " (map (host:
                "${host}(${if share.readOnly then "ro" else "rw"},sync,no_subtree_check,no_root_squash)"
              ) share.allowedHosts)}"
            ) cfg.storage.shares;
          in
          concatStringsSep "\n" (shareExports ++ cfg.nfs.exports);
      };

      # NFS client support
      services.rpcbind.enable = true;

      # Firewall rules for NFS
      networking.firewall.extraCommands = ''
        # Allow NFS traffic from homelab networks
        iptables -A INPUT -s 10.0.0.0/16 -p tcp --dport 111 -j ACCEPT
        iptables -A INPUT -s 10.0.0.0/16 -p tcp --dport 2049 -j ACCEPT
        iptables -A INPUT -s 10.0.0.0/16 -p tcp --dport 4000:4002 -j ACCEPT
        iptables -A INPUT -s 10.0.0.0/16 -p udp --dport 111 -j ACCEPT
      '';
    })

    # SMB/CIFS server configuration
    (mkIf (cfg.enable && cfg.smb.enable) {
      services.samba = {
        enable = true;

        settings.global = {
          workgroup = cfg.smb.workgroup;
          "netbios name" = cfg.smb.netbiosName;
          "server string" = "${config.networking.hostName} NAS";
          security = cfg.smb.security;
          "encrypt passwords" = true;
          "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072";
          "read raw" = true;
          "write raw" = true;
          "max xmit" = 65535;
          "log level" = 1;
          "log file" = "/var/log/samba/%m.log";
          "max log size" = 50;
        };

        # Auto-generate shares from configuration
        shares = mapAttrs (name: share: {
          path = share.path;
          comment = share.description;
          "read only" = share.readOnly;
          browseable = "yes";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          "valid users" = concatStringsSep " " share.allowedUsers;
          "hosts allow" = concatStringsSep " " share.allowedHosts;
        }) cfg.storage.shares;
      };

      # Samba-related services
      services.samba-wsdd.enable = true;  # Web Service Discovery

      # Firewall rules for SMB
      networking.firewall.extraCommands = ''
        # Allow SMB/CIFS traffic from homelab networks
        iptables -A INPUT -s 10.0.0.0/16 -p tcp --dport 139 -j ACCEPT
        iptables -A INPUT -s 10.0.0.0/16 -p tcp --dport 445 -j ACCEPT
        iptables -A INPUT -s 10.0.0.0/16 -p udp --dport 137:138 -j ACCEPT
      '';
    })

    # Backup configuration
    (mkIf (cfg.enable && cfg.backup.enable) {
      # Create backup user
      users.users.backup = {
        isSystemUser = true;
        group = "backup";
        home = "${cfg.storage.basePath}/backups";
      };
      users.groups.backup = {};

      # Backup directory permissions
      systemd.tmpfiles.rules = [
        "d ${cfg.storage.basePath}/backups 0750 backup backup -"
      ];
    })

    # BorgBackup configuration
    (mkIf (cfg.enable && cfg.backup.borgbackup.enable && cfg.backup.borgbackup.authorizedKeys != []) {
      services.borgbackup.repos = {
        homelab = {
          path = "${cfg.backup.borgbackup.repositoryPath}/homelab";
          allowSubRepos = true;
          user = "backup";
          group = "backup";
          authorizedKeys = cfg.backup.borgbackup.authorizedKeys;
        };
      };

      # Create Borg repository directory
      systemd.tmpfiles.rules = [
        "d ${cfg.backup.borgbackup.repositoryPath} 0750 backup backup -"
      ];
    })

    # Monitoring configuration
    (mkIf (cfg.enable && cfg.monitoring.enable) {
      # Prometheus node exporter with filesystem metrics
      services.prometheus.exporters.node = {
        enable = true;
        port = 9100;
        enabledCollectors = [
          "filesystem"
          "diskstats"
        ] ++ (optionals cfg.monitoring.diskHealth [ "smartmon" ]);
      };

      # SMART monitoring
      services.smartd = mkIf cfg.monitoring.diskHealth {
        enable = true;
        autodetect = true;
        notifications = {
          mail = {
            enable = false;  # Configure if email notifications needed
          };
        };
      };
    })

    # VM-specific configuration
    (mkIf (cfg.enable && cfg.deploymentType == "vm") {
      # VM storage optimizations
      boot.kernel.sysctl = {
        "vm.dirty_background_ratio" = 5;
        "vm.dirty_ratio" = 10;
        "vm.vfs_cache_pressure" = 50;
      };

      # Enhanced file system support
      boot.supportedFilesystems = [ "ntfs" "exfat" "ext4" "btrfs" "xfs" ];

      # Additional storage utilities for VM
      services.udisks2.enable = true;
    })

    # Container-specific configuration
    (mkIf (cfg.enable && cfg.deploymentType == "container") {
      # Container optimizations
      boot.isContainer = true;

      # Simplified configuration for containers
      services.samba.enable = mkForce false;  # Disable SMB in containers

      # Container-specific storage limits
      systemd.services.nfs-server.serviceConfig = mkIf cfg.nfs.enable {
        MemoryLimit = "256M";
      };
    })
  ];
}