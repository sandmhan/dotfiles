# NAS Services LXC Container Configuration
# Network File System and backup services in a lightweight container
{
  config,
  lib,
  pkgs,
  userSettings,
  systemSettings,
  ...
}:
{
  imports = [
    ../lxc-base
  ];

  # Container-specific hostname
  networking.hostName = "lxc-nas";

  # NAS-specific firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22    # SSH management
      111   # NFS portmapper
      2049  # NFS server
      4001  # NFS status
      4002  # NFS lock manager
      445   # SMB/CIFS
      139   # NetBIOS
      9100  # Prometheus metrics
    ];
    allowedUDPPorts = [
      111   # NFS portmapper UDP
      2049  # NFS server UDP
      4001  # NFS status UDP
      4002  # NFS lock manager UDP
    ];
  };

  # NFS server for media and backup storage
  services.nfs.server = {
    enable = true;
    exports = ''
      # Media storage for Jellyfin
      /srv/media         10.0.0.0/24(rw,sync,no_subtree_check,no_root_squash)

      # Recording storage for Frigate
      /srv/recordings    10.0.0.0/24(rw,sync,no_subtree_check,no_root_squash)

      # Backup storage
      /srv/backups       10.0.0.0/24(rw,sync,no_subtree_check,no_root_squash)

      # Download staging for *arr apps
      /srv/downloads     10.0.0.0/24(rw,sync,no_subtree_check,no_root_squash)
    '';
  };

  # Samba server for Windows/macOS access
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "HOMELAB";
        "server string" = "Homelab NAS";
        "security" = "user";
        "map to guest" = "bad user";
      };

      "media" = {
        "path" = "/srv/media";
        "browseable" = "yes";
        "writable" = "yes";
        "guest ok" = "yes";
        "read only" = "no";
      };

      "backups" = {
        "path" = "/srv/backups";
        "browseable" = "yes";
        "writable" = "yes";
        "guest ok" = "no";
        "valid users" = userSettings.username;
      };
    };
  };

  # Create storage directories
  systemd.tmpfiles.rules = [
    "d /srv/media 0755 nobody nobody -"
    "d /srv/media/movies 0755 nobody nobody -"
    "d /srv/media/tv 0755 nobody nobody -"
    "d /srv/media/music 0755 nobody nobody -"
    "d /srv/recordings 0755 nobody nobody -"
    "d /srv/backups 0755 root root -"
    "d /srv/downloads 0755 nobody nobody -"
  ];

  # Backup services
  services.borgbackup.jobs.homelab = {
    paths = [ "/srv/backups" ];
    repo = "/srv/backups/borg";
    compression = "zlib,6";
    startAt = "daily";
    prune.keep = {
      daily = 7;
      weekly = 4;
      monthly = 6;
    };
    encryption.mode = "none"; # Homelab only - add encryption in production
  };

  # Disk health monitoring
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications = {
      wall.enable = true;
      mail.enable = false; # No mail server in homelab yet
    };
  };

  # SMART metrics for Prometheus
  services.prometheus.exporters.smartctl = {
    enable = true;
    port = 9633;
    devices = [ "/dev/sda" ]; # Adjust for actual devices
  };

  # Additional NAS tools
  environment.systemPackages = with pkgs; [
    nfs-utils      # NFS utilities
    cifs-utils     # SMB/CIFS utilities
    borgbackup     # Backup tool
    smartmontools  # Disk health monitoring
    ncdu           # Disk usage analyzer
    tree           # Directory tree visualization
  ];

  # Automatic filesystem checks
  systemd.services.nas-health-check = {
    description = "NAS Health Check";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "nas-health" ''
        #!/bin/bash
        # Check filesystem usage
        df -h | grep -E "(9[0-9]%|100%)" && {
          echo "WARNING: High disk usage detected"
        }

        # Check NFS exports
        exportfs -v >/dev/null || {
          echo "ERROR: NFS exports check failed"
          exit 1
        }

        # Check Samba status
        systemctl is-active samba >/dev/null || {
          echo "ERROR: Samba service not running"
          exit 1
        }

        echo "NAS container healthy"
      '';
    };
    startAt = "*:0/10"; # Every 10 minutes
  };

  # Container resource optimization
  systemd.services = {
    nfs-server.serviceConfig = {
      MemoryMax = "128M";
      CPUQuota = "25%";
    };

    samba.serviceConfig = {
      MemoryMax = "128M";
      CPUQuota = "25%";
    };
  };

  # Network optimizations for file serving
  boot.kernel.sysctl = {
    # Optimize for file serving
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
  };
}