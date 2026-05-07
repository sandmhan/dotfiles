# Komga — Manga/Comics Library Server
# Serves local CBZ/CBR/PDF/EPUB files with OPDS v1+v2 and Mihon integration
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.homelab.manga;
  komga = cfg.komga;
in
{
  options.homelab.manga.komga = {
    enable = mkOption {
      type = types.bool;
      default = cfg.enable;
      description = "Enable Komga manga library server";
    };

    port = mkOption {
      type = types.port;
      default = 25600;
      description = "Komga web interface and OPDS port";
    };

    image = mkOption {
      type = types.str;
      default = "gotson/komga:latest";
      description = "OCI image for Komga";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/komga";
      description = "Host path for Komga configuration and database";
    };

    libraryDir = mkOption {
      type = types.str;
      default = "/var/lib/komga/library";
      description = "Host path for manga/comics library files";
    };

    javaMemory = mkOption {
      type = types.str;
      default =
        if cfg.resourceProfile == "minimal" then
          "512m"
        else if cfg.resourceProfile == "high" then
          "2g"
        else
          "1g";
      description = "JVM max heap size for Komga";
    };

    reverseProxy = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Nginx reverse proxy for Komga";
      };

      domain = mkOption {
        type = types.str;
        default = "komga.homelab.local";
        description = "Domain name for Komga web interface";
      };
    };
  };

  config = mkMerge [
    # Komga OCI container
    (mkIf komga.enable {
      # Persistent storage directories
      systemd.tmpfiles.rules = [
        "d ${komga.dataDir} 0755 root root -"
        "d ${komga.dataDir}/config 0755 root root -"
        "d ${komga.libraryDir} 0755 root root -"
      ];

      virtualisation.oci-containers.containers.komga = {
        image = komga.image;
        ports = [ "${toString komga.port}:25600" ];
        environment = {
          JAVA_TOOL_OPTIONS = "-Xmx${komga.javaMemory}";
          TZ = "America/New_York";
        };
        volumes = [
          "${komga.dataDir}/config:/config"
          "${komga.libraryDir}:/data"
        ];
        extraOptions = [
          "--network=manga-net"
          "--health-cmd=curl -sf http://localhost:25600/api/v1/libraries || exit 1"
          "--health-interval=30s"
          "--health-timeout=10s"
          "--health-retries=3"
        ];
      };

      # Ensure network exists before Komga starts
      systemd.services.podman-komga = {
        after = [ "manga-network.service" ];
        requires = [ "manga-network.service" ];
      };

      # Open Komga port when not behind reverse proxy
      networking.firewall.allowedTCPPorts = optionals (!komga.reverseProxy.enable) [
        komga.port
      ];
    })

    # Nginx reverse proxy for Komga
    (mkIf (komga.enable && komga.reverseProxy.enable) {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;

        virtualHosts.${komga.reverseProxy.domain} = {
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
          ];

          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString komga.port}";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header X-Forwarded-Proto $scheme;
              client_max_body_size 100M;
            '';
          };
        };
      };

      networking.firewall.allowedTCPPorts = [ 80 ];
    })

    # Resource limits
    (mkIf (komga.enable && cfg.deploymentType == "container") {
      systemd.services.podman-komga.serviceConfig = {
        MemoryMax = "768M";
        CPUQuota = "50%";
      };
    })

    (mkIf (komga.enable && cfg.deploymentType != "container" && cfg.resourceProfile == "minimal") {
      systemd.services.podman-komga.serviceConfig = {
        MemoryMax = "1G";
        CPUQuota = "75%";
      };
    })
  ];
}
