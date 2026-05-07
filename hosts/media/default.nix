# Media Server VM Host Configuration
# Jellyfin, *arr stack, download clients with GPU passthrough for hardware transcoding
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
    ../server/default.nix
    ../server/hardware-configuration.nix
    ../../systemModules/media.nix
    ../../systemModules/sops.nix
  ];

  # System identification
  networking.hostName = systemSettings.hostname;

  # Enable media stack with VM-optimized high-resource settings
  homelab.media = {
    enable = true;
    deploymentType = "vm";
    resourceProfile = "high";

    domain = "media.homelab.local";

    # NAS storage configuration
    # PLACEHOLDER: Update nasAddress with actual NAS VM IP after deployment
    storage = {
      nasAddress = "10.0.0.TBD"; # PLACEHOLDER — set after NAS VM is deployed on 10.0.0.0/24
      mediaPath = "/data/media";
      downloadsPath = "/data/downloads";
    };

    # Jellyfin with GPU hardware transcoding
    jellyfin = {
      enable = true;
      gpu.enable = true;
    };

    # *arr stack for automated media management
    sonarr.enable = true;
    radarr.enable = true;
    prowlarr.enable = true;

    # Download clients
    downloadClients = {
      qbittorrent = {
        enable = true;
        vpnKillSwitch = false; # PLACEHOLDER: Enable when VPN provider is configured
      };
      sabnzbd.enable = true;
    };

    # Recyclarr for TRaSH Guides quality profiles
    recyclarr.enable = true;

    # Nginx reverse proxy for unified access
    reverseProxy.enable = true;

    # Prometheus monitoring
    monitoring.enable = true;
  };

  # GPU Passthrough Configuration
  # PLACEHOLDER: Configure on Proxmox host after GPU is installed
  #
  # Prerequisites on Proxmox host:
  #   1. Enable IOMMU in BIOS
  #   2. Add to /etc/default/grub: GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"
  #   3. Add to /etc/modules: vfio vfio_iommu_type1 vfio_pci vfio_virqfd
  #   4. Blacklist nouveau: echo "blacklist nouveau" > /etc/modprobe.d/blacklist-nouveau.conf
  #   5. Find GPU PCI IDs: lspci -nn | grep -i nvidia
  #      Example 1080 Ti: 01:00.0 (GPU), 01:00.1 (Audio)
  #   6. Add to /etc/modprobe.d/vfio.conf: options vfio-pci ids=XXXX:XXXX,XXXX:XXXX
  #   7. Pass to VM: qm set <vmid> --hostpci0 01:00,pcie=1
  #
  # After GPU passthrough is working, uncomment in systemModules/media.nix:
  #   boot.kernelModules, hardware.nvidia settings

  # Additional firewall rules for media access
  networking.firewall = {
    allowedTCPPorts = [
      80 # Nginx reverse proxy
      443 # HTTPS (future)
      8096 # Jellyfin direct
      8989 # Sonarr
      7878 # Radarr
      9696 # Prowlarr
      8080 # qBittorrent
      8085 # SABnzbd
      9100 # Node exporter
    ];

    # TODO: Add services VLAN (10.0.20.0/24) rules once VLANs are deployed
    extraCommands = ''
      # Allow media access from homelab network
      iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 80 -j ACCEPT
      iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 8096 -j ACCEPT

      # Allow Prometheus scraping from homelab network
      iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 9100 -j ACCEPT

      # Allow *arr services access from homelab network (inter-service communication)
      iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 8989 -j ACCEPT
      iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 7878 -j ACCEPT
      iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 9696 -j ACCEPT
    '';
  };

  # Kernel tuning for media workload
  boot.kernel.sysctl = {
    # Increase inotify limits for media file monitoring
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 256;

    # Network tuning for media streaming
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.core.netdev_max_backlog" = 5000;

    # Increase file handle limits for many open media files
    "fs.file-max" = 2097152;

    # VM memory management tuning for large media files
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
  };

  # VM resource recommendations (configure on Proxmox host):
  # For 1080 Ti GPU passthrough + media stack:
  # qm set <vmid> --cores 8 --memory 16384
  # qm set <vmid> --hostpci0 01:00,pcie=1  # PLACEHOLDER PCI ID
  # qm set <vmid> --balloon 0  # Disable ballooning for GPU passthrough

}
