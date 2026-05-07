# Media Server Module
# Provides Jellyfin media server, *arr stack (Sonarr, Radarr, Prowlarr),
# download clients (qBittorrent, SABnzbd), and Nginx reverse proxy
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  servicePackages = import ./packages.nix { inherit pkgs lib; };
  cfg = config.homelab.media;
in
{
  options.homelab.media = {
    enable = mkEnableOption "Homelab media server stack (Jellyfin + *arr + download clients)";

    deploymentType = mkOption {
      type = types.enum [
        "vm"
        "container"
        "hybrid"
      ];
      default = "vm";
      description = "Deployment type - affects resource allocation and feature set";
    };

    resourceProfile = mkOption {
      type = types.enum [
        "minimal"
        "standard"
        "high"
      ];
      default = "standard";
      description = "Resource profile for automatic configuration optimization";
    };

    domain = mkOption {
      type = types.str;
      default = "media.homelab.local";
      description = "Base domain name for media services";
    };

    # NAS storage configuration
    storage = {
      nasAddress = mkOption {
        type = types.str;
        default = "10.0.0.TBD"; # PLACEHOLDER - update with actual NAS IP when deployed
        description = "IP address of the NAS VM providing NFS shares";
      };

      mediaPath = mkOption {
        type = types.str;
        default = "/data/media";
        description = "NFS mount path for media library (movies, TV shows, music)";
      };

      downloadsPath = mkOption {
        type = types.str;
        default = "/data/downloads";
        description = "NFS mount path for download staging area";
      };
    };

    # Jellyfin media server
    jellyfin = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Jellyfin media server with hardware transcoding";
      };

      port = mkOption {
        type = types.port;
        default = 8096;
        description = "Jellyfin HTTP port";
      };

      gpu = {
        enable = mkOption {
          type = types.bool;
          default = cfg.deploymentType == "vm";
          description = ''
            Enable GPU passthrough for hardware transcoding (NVENC/NVDEC).
            Requires PCI passthrough configured on the Proxmox host.
          '';
        };
      };
    };

    # Sonarr - TV show management
    sonarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Sonarr TV show management and automation";
      };

      port = mkOption {
        type = types.port;
        default = 8989;
        description = "Sonarr HTTP port";
      };
    };

    # Radarr - Movie management
    radarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Radarr movie management and automation";
      };

      port = mkOption {
        type = types.port;
        default = 7878;
        description = "Radarr HTTP port";
      };
    };

    # Prowlarr - Indexer management
    prowlarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Prowlarr indexer manager for Sonarr/Radarr";
      };

      port = mkOption {
        type = types.port;
        default = 9696;
        description = "Prowlarr HTTP port";
      };
    };

    # Download clients
    downloadClients = {
      qbittorrent = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable qBittorrent torrent client via OCI container";
        };

        port = mkOption {
          type = types.port;
          default = 8080;
          description = "qBittorrent web UI port";
        };

        image = mkOption {
          type = types.str;
          default = "lscr.io/linuxserver/qbittorrent:latest";
          description = "qBittorrent OCI container image";
        };

        vpnKillSwitch = mkOption {
          type = types.bool;
          default = false;
          description = ''
            PLACEHOLDER: Enable WireGuard VPN kill switch for qBittorrent.
            When enabled, all torrent traffic routes through a VPN tunnel.
            Requires VPN provider credentials in sops secrets.
          '';
        };
      };

      sabnzbd = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable SABnzbd Usenet download client";
        };

        port = mkOption {
          type = types.port;
          default = 8085;
          description = "SABnzbd web UI port";
        };
      };
    };

    # Recyclarr - TRaSH Guides sync for quality profiles
    recyclarr = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Recyclarr for automatic quality profile management via TRaSH Guides";
      };

      image = mkOption {
        type = types.str;
        default = "ghcr.io/recyclarr/recyclarr:latest";
        description = "Recyclarr OCI container image";
      };
    };

    # Nginx reverse proxy
    reverseProxy = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Nginx reverse proxy for unified access to all media services";
      };
    };

    # Monitoring
    monitoring = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Prometheus node exporter for monitoring integration";
      };
    };
  };

  config = mkMerge [
    # NFS mount units for NAS storage
    (mkIf cfg.enable {
      # Create mount point directories
      systemd.tmpfiles.rules = [
        "d /data 0755 root root -"
        "d /data/media 0755 root root -"
        "d /data/downloads 0755 root root -"
      ];

      # NFS mount for media library
      fileSystems.${cfg.storage.mediaPath} = {
        device = "${cfg.storage.nasAddress}:/export/media";
        fsType = "nfs";
        options = [
          "nfsvers=4.2"
          "soft"
          "timeo=150"
          "retrans=3"
          "x-systemd.automount"
          "x-systemd.idle-timeout=600"
          "noatime"
        ];
      };

      # NFS mount for downloads staging
      fileSystems.${cfg.storage.downloadsPath} = {
        device = "${cfg.storage.nasAddress}:/export/downloads";
        fsType = "nfs";
        options = [
          "nfsvers=4.2"
          "soft"
          "timeo=150"
          "retrans=3"
          "x-systemd.automount"
          "x-systemd.idle-timeout=600"
          "noatime"
        ];
      };

      # NFS client packages
      environment.systemPackages = servicePackages.media ++ servicePackages.base ++ [ pkgs.nfs-utils ];
    })

    # Jellyfin media server
    (mkIf (cfg.enable && cfg.jellyfin.enable) {
      services.jellyfin = {
        enable = true;
        openFirewall = true;
      };

      # GPU hardware transcoding support
      hardware.graphics = mkIf cfg.jellyfin.gpu.enable {
        enable = true;
      };

      # PLACEHOLDER: NVIDIA GPU passthrough for hardware transcoding
      # Requires on Proxmox host:
      #   1. Enable IOMMU in BIOS and kernel (intel_iommu=on / amd_iommu=on)
      #   2. Blacklist nouveau driver on host
      #   3. Pass GPU to VM: qm set <vmid> --hostpci0 <PCI_ID>,pcie=1
      #
      # Find PCI ID with: lspci -nn | grep -i nvidia
      # Example for 1080 Ti: 01:00.0 (GPU) and 01:00.1 (Audio)
      #
      # Uncomment and update PCI IDs after GPU passthrough is configured:
      # boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
      # hardware.nvidia = {
      #   modesetting.enable = true;
      #   open = false;
      #   package = config.boot.kernelPackages.nvidiaPackages.production;
      # };

      # Add jellyfin user to video/render groups for GPU access
      users.users.jellyfin = mkIf cfg.jellyfin.gpu.enable {
        extraGroups = [
          "video"
          "render"
        ];
      };

      # Jellyfin firewall
      networking.firewall.allowedTCPPorts = [ cfg.jellyfin.port ];
    })

    # Sonarr - TV show management
    (mkIf (cfg.enable && cfg.sonarr.enable) {
      services.sonarr = {
        enable = true;
        openFirewall = true;
      };

      networking.firewall.allowedTCPPorts = [ cfg.sonarr.port ];
    })

    # Radarr - Movie management
    (mkIf (cfg.enable && cfg.radarr.enable) {
      services.radarr = {
        enable = true;
        openFirewall = true;
      };

      networking.firewall.allowedTCPPorts = [ cfg.radarr.port ];
    })

    # Prowlarr - Indexer management
    (mkIf (cfg.enable && cfg.prowlarr.enable) {
      services.prowlarr = {
        enable = true;
        openFirewall = true;
      };

      networking.firewall.allowedTCPPorts = [ cfg.prowlarr.port ];
    })

    # SABnzbd - Usenet download client
    (mkIf (cfg.enable && cfg.downloadClients.sabnzbd.enable) {
      services.sabnzbd = {
        enable = true;
      };

      networking.firewall.allowedTCPPorts = [ cfg.downloadClients.sabnzbd.port ];
    })

    # qBittorrent - Torrent client via OCI container
    (mkIf (cfg.enable && cfg.downloadClients.qbittorrent.enable) {
      virtualisation.oci-containers = {
        backend = "podman";
        containers.qbittorrent = {
          image = cfg.downloadClients.qbittorrent.image;
          ports = [
            "${toString cfg.downloadClients.qbittorrent.port}:${toString cfg.downloadClients.qbittorrent.port}"
            "6881:6881"
            "6881:6881/udp"
          ];
          volumes = [
            "/var/lib/qbittorrent:/config"
            "${cfg.storage.downloadsPath}:/downloads"
          ];
          environment = {
            PUID = "1000";
            PGID = "1000";
            TZ = "America/New_York";
            WEBUI_PORT = toString cfg.downloadClients.qbittorrent.port;
          };
          extraOptions = [ "--network=host" ];
        };
      };

      # PLACEHOLDER: WireGuard VPN kill switch for qBittorrent
      # When cfg.downloadClients.qbittorrent.vpnKillSwitch is enabled,
      # configure the container to route through a VPN tunnel:
      # 1. Add WireGuard config from sops secrets
      # 2. Use gluetun sidecar container or network namespace
      # 3. Bind qBittorrent to VPN interface only

      networking.firewall.allowedTCPPorts = [
        cfg.downloadClients.qbittorrent.port
        6881
      ];
      networking.firewall.allowedUDPPorts = [ 6881 ];
    })

    # Recyclarr - TRaSH Guides quality profile sync
    (mkIf (cfg.enable && cfg.recyclarr.enable) {
      virtualisation.oci-containers = {
        backend = "podman";
        containers.recyclarr = {
          image = cfg.recyclarr.image;
          volumes = [
            "/var/lib/recyclarr:/config"
          ];
          environment = {
            TZ = "America/New_York";
            RECYCLARR_CREATE_CONFIG = "true";
          };
          # Recyclarr runs as a cron job inside the container
          # Configure /var/lib/recyclarr/recyclarr.yml after first run
        };
      };
    })

    # Nginx reverse proxy for unified access
    (mkIf (cfg.enable && cfg.reverseProxy.enable) {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;

        # Jellyfin
        virtualHosts."jellyfin.${cfg.domain}" = mkIf cfg.jellyfin.enable {
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
          ];
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString cfg.jellyfin.port}";
            proxyWebsockets = true;
          };
        };

        # Sonarr
        virtualHosts."sonarr.${cfg.domain}" = mkIf cfg.sonarr.enable {
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
          ];
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString cfg.sonarr.port}";
          };
        };

        # Radarr
        virtualHosts."radarr.${cfg.domain}" = mkIf cfg.radarr.enable {
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
          ];
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString cfg.radarr.port}";
          };
        };

        # Prowlarr
        virtualHosts."prowlarr.${cfg.domain}" = mkIf cfg.prowlarr.enable {
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
          ];
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString cfg.prowlarr.port}";
          };
        };

        # qBittorrent
        virtualHosts."qbt.${cfg.domain}" = mkIf cfg.downloadClients.qbittorrent.enable {
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
          ];
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString cfg.downloadClients.qbittorrent.port}";
          };
        };

        # SABnzbd
        virtualHosts."sabnzbd.${cfg.domain}" = mkIf cfg.downloadClients.sabnzbd.enable {
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
          ];
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString cfg.downloadClients.sabnzbd.port}";
          };
        };
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    })

    # Prometheus node exporter for monitoring
    (mkIf (cfg.enable && cfg.monitoring.enable) {
      services.prometheus.exporters.node = {
        enable = true;
        port = 9100;
        enabledCollectors = [
          "systemd"
          "processes"
          "tcpstat"
          "network_route"
        ]
        ++ optionals (cfg.deploymentType == "vm") [
          "interrupts"
          "logind"
          "meminfo_numa"
          "mountstats"
        ];
      };

      networking.firewall.allowedTCPPorts = [ 9100 ];
    })

    # SOPS secrets for API keys and service credentials
    (mkIf cfg.enable {
      sops.secrets = {
        "media/jellyfin-api-key" = mkIf cfg.jellyfin.enable {
          mode = "0600";
          owner = "jellyfin";
          group = "jellyfin";
        };
        "media/sonarr-api-key" = mkIf cfg.sonarr.enable {
          mode = "0600";
          owner = "sonarr";
          group = "sonarr";
        };
        "media/radarr-api-key" = mkIf cfg.radarr.enable {
          mode = "0600";
          owner = "radarr";
          group = "radarr";
        };
        "media/prowlarr-api-key" = mkIf cfg.prowlarr.enable {
          mode = "0600";
          owner = "root";
          group = "root";
        };
        "media/sabnzbd-api-key" = mkIf cfg.downloadClients.sabnzbd.enable {
          mode = "0600";
          owner = "sabnzbd";
          group = "sabnzbd";
        };
        "media/qbittorrent-password" = mkIf cfg.downloadClients.qbittorrent.enable {
          mode = "0600";
        };
      };
    })

    # Firewall - common rules
    (mkIf cfg.enable {
      networking.firewall.allowedTCPPorts = [ 22 ];

      # Allow access from homelab VLANs
      networking.firewall.extraCommands = ''
        # Allow media services access from management VLAN
        iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 80 -j ACCEPT
        iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 443 -j ACCEPT

        # Allow media services access from local network
        # TODO: Restrict to services VLAN (10.0.20.0/24) once VLANs are deployed
        iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 80 -j ACCEPT

        # Allow Prometheus scraping from monitoring server
        # TODO: Restrict to services VLAN (10.0.20.0/24) once VLANs are deployed
        iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 9100 -j ACCEPT
      '';
    })

    # Systemd resource limits based on deployment type
    (mkIf (cfg.enable && cfg.deploymentType == "container") {
      systemd.services.jellyfin = mkIf cfg.jellyfin.enable {
        serviceConfig = {
          MemoryMax = "1G";
          CPUQuota = "100%";
        };
      };
    })

    (mkIf (cfg.enable && cfg.deploymentType != "container" && cfg.resourceProfile == "minimal") {
      systemd.services.jellyfin = mkIf cfg.jellyfin.enable {
        serviceConfig = {
          MemoryMax = "2G";
          CPUQuota = "150%";
        };
      };
    })

    (mkIf (cfg.enable && cfg.deploymentType != "container" && cfg.resourceProfile == "high") {
      systemd.services.jellyfin = mkIf cfg.jellyfin.enable {
        serviceConfig = {
          MemoryMax = "8G";
        };
      };
    })

    # Health check service
    (mkIf cfg.enable {
      systemd.services.media-health-check = {
        description = "Media Stack Health Check";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "media-health-check" ''
            sleep 30

            echo "Checking media stack services..."

            ${optionalString cfg.jellyfin.enable ''
              if ${pkgs.curl}/bin/curl -sf http://localhost:${toString cfg.jellyfin.port}/health >/dev/null 2>&1; then
                echo "Jellyfin is ready"
              else
                echo "Warning: Jellyfin not responding on port ${toString cfg.jellyfin.port}"
              fi
            ''}

            ${optionalString cfg.sonarr.enable ''
              if ${pkgs.curl}/bin/curl -sf http://localhost:${toString cfg.sonarr.port}/ping >/dev/null 2>&1; then
                echo "Sonarr is ready"
              else
                echo "Warning: Sonarr not responding on port ${toString cfg.sonarr.port}"
              fi
            ''}

            ${optionalString cfg.radarr.enable ''
              if ${pkgs.curl}/bin/curl -sf http://localhost:${toString cfg.radarr.port}/ping >/dev/null 2>&1; then
                echo "Radarr is ready"
              else
                echo "Warning: Radarr not responding on port ${toString cfg.radarr.port}"
              fi
            ''}

            ${optionalString cfg.prowlarr.enable ''
              if ${pkgs.curl}/bin/curl -sf http://localhost:${toString cfg.prowlarr.port}/ping >/dev/null 2>&1; then
                echo "Prowlarr is ready"
              else
                echo "Warning: Prowlarr not responding on port ${toString cfg.prowlarr.port}"
              fi
            ''}

            ${optionalString cfg.downloadClients.sabnzbd.enable ''
              if ${pkgs.curl}/bin/curl -sf http://localhost:${toString cfg.downloadClients.sabnzbd.port}/ >/dev/null 2>&1; then
                echo "SABnzbd is ready"
              else
                echo "Warning: SABnzbd not responding on port ${toString cfg.downloadClients.sabnzbd.port}"
              fi
            ''}

            ${optionalString cfg.downloadClients.qbittorrent.enable ''
              if ${pkgs.curl}/bin/curl -sf http://localhost:${toString cfg.downloadClients.qbittorrent.port}/ >/dev/null 2>&1; then
                echo "qBittorrent is ready"
              else
                echo "Warning: qBittorrent not responding on port ${toString cfg.downloadClients.qbittorrent.port}"
              fi
            ''}

            # Check NFS mounts
            if mountpoint -q ${cfg.storage.mediaPath} 2>/dev/null; then
              echo "NFS media mount is available"
            else
              echo "Warning: NFS media mount not available at ${cfg.storage.mediaPath}"
            fi

            if mountpoint -q ${cfg.storage.downloadsPath} 2>/dev/null; then
              echo "NFS downloads mount is available"
            else
              echo "Warning: NFS downloads mount not available at ${cfg.storage.downloadsPath}"
            fi
          '';
        };

        startAt = "hourly";
      };
    })
  ];
}
