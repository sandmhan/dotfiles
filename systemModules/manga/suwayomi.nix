# Suwayomi-Server — Mihon/Tachiyomi Extension Runner
# Runs Mihon extensions server-side to browse and download manga from online sources.
# Complements Komga by fetching content; Komga serves the local library.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.homelab.manga;
  suwayomi = cfg.suwayomi;
in
{
  options.homelab.manga.suwayomi = {
    enable = mkOption {
      type = types.bool;
      default = cfg.enable;
      description = "Enable Suwayomi-Server manga source aggregator";
    };

    port = mkOption {
      type = types.port;
      default = 4567;
      description = "Suwayomi web interface port";
    };

    image = mkOption {
      type = types.str;
      default = "ghcr.io/suwayomi/tachidesk:latest";
      description = "OCI image for Suwayomi-Server";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/suwayomi";
      description = "Host path for Suwayomi data (library, extensions, thumbnails)";
    };

    downloadDir = mkOption {
      type = types.str;
      default = "/var/lib/suwayomi/downloads";
      description = "Host path for downloaded manga chapters";
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
      description = "JVM max heap size for Suwayomi";
    };

    # Suwayomi can auto-download to a directory that Komga watches
    komgaIntegration = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Download manga into Komga's library directory for unified access";
      };
    };

    reverseProxy = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Nginx reverse proxy for Suwayomi";
      };

      domain = mkOption {
        type = types.str;
        default = "suwayomi.homelab.local";
        description = "Domain name for Suwayomi web interface";
      };
    };

    flaresolverr = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable FlareSolverr for bypassing Cloudflare protection on sources";
      };

      image = mkOption {
        type = types.str;
        default = "ghcr.io/flaresolverr/flaresolverr:latest";
        description = "OCI image for FlareSolverr";
      };
    };
  };

  config = mkMerge [
    # Suwayomi OCI container
    (mkIf suwayomi.enable {
      # Persistent storage directories
      systemd.tmpfiles.rules = [
        "d ${suwayomi.dataDir} 0755 root root -"
        "d ${suwayomi.downloadDir} 0755 root root -"
      ];

      virtualisation.oci-containers.containers.suwayomi = {
        image = suwayomi.image;
        ports = [ "${toString suwayomi.port}:4567" ];
        environment =
          {
            JAVA_TOOL_OPTIONS = "-Xmx${suwayomi.javaMemory}";
            TZ = "America/New_York";
            # Auto-download settings
            DOWNLOAD_AS_CBZ = "true";
          }
          // optionalAttrs suwayomi.flaresolverr.enable {
            FLARESOLVERR_URL = "http://flaresolverr:8191";
          };
        volumes =
          [
            "${suwayomi.dataDir}:/home/suwayomi/.local/share/Tachidesk"
          ]
          ++ optionals (suwayomi.komgaIntegration.enable && config.homelab.manga.komga.enable) [
            "${config.homelab.manga.komga.libraryDir}:/home/suwayomi/.local/share/Tachidesk/downloads"
          ]
          ++ optionals (!suwayomi.komgaIntegration.enable || !config.homelab.manga.komga.enable) [
            "${suwayomi.downloadDir}:/home/suwayomi/.local/share/Tachidesk/downloads"
          ];
        extraOptions = [
          "--network=manga-net"
          "--health-cmd=curl -sf http://localhost:4567/api/v1/settings/about || exit 1"
          "--health-interval=30s"
          "--health-timeout=10s"
          "--health-retries=3"
        ];
      };

      # Ensure network exists before Suwayomi starts
      systemd.services.podman-suwayomi = {
        after = [ "manga-network.service" ];
        requires = [ "manga-network.service" ];
      };

      # Open Suwayomi port when not behind reverse proxy
      networking.firewall.allowedTCPPorts = optionals (!suwayomi.reverseProxy.enable) [
        suwayomi.port
      ];
    })

    # FlareSolverr sidecar
    (mkIf (suwayomi.enable && suwayomi.flaresolverr.enable) {
      virtualisation.oci-containers.containers.flaresolverr = {
        image = suwayomi.flaresolverr.image;
        environment = {
          LOG_LEVEL = "info";
          TZ = "America/New_York";
        };
        extraOptions = [
          "--network=manga-net"
        ];
      };

      systemd.services.podman-flaresolverr = {
        after = [ "manga-network.service" ];
        requires = [ "manga-network.service" ];
      };
    })

    # Nginx reverse proxy for Suwayomi
    (mkIf (suwayomi.enable && suwayomi.reverseProxy.enable) {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;

        virtualHosts.${suwayomi.reverseProxy.domain} = {
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
          ];

          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString suwayomi.port}";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header X-Forwarded-Proto $scheme;
              client_max_body_size 50M;
            '';
          };
        };
      };

      networking.firewall.allowedTCPPorts = [ 80 ];
    })

    # Resource limits
    (mkIf (suwayomi.enable && cfg.deploymentType == "container") {
      systemd.services.podman-suwayomi.serviceConfig = {
        MemoryMax = "768M";
        CPUQuota = "50%";
      };
    })

    (mkIf (suwayomi.enable && cfg.deploymentType != "container" && cfg.resourceProfile == "minimal") {
      systemd.services.podman-suwayomi.serviceConfig = {
        MemoryMax = "1G";
        CPUQuota = "75%";
      };
    })

    # Health check service for the manga stack
    (mkIf suwayomi.enable {
      systemd.services.manga-health-check = {
        description = "Manga Stack Health Check";
        wantedBy = [ "multi-user.target" ];
        after = [
          "podman-komga.service"
          "podman-suwayomi.service"
        ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "manga-health-check" ''
            sleep 30

            echo "Checking manga stack services..."

            # Check Komga
            ${optionalString config.homelab.manga.komga.enable ''
              if ${pkgs.curl}/bin/curl -sf http://localhost:${toString config.homelab.manga.komga.port}/api/v1/libraries >/dev/null 2>&1; then
                echo "Komga is ready"
              else
                echo "Warning: Komga not responding"
              fi
            ''}

            # Check Suwayomi
            if ${pkgs.curl}/bin/curl -sf http://localhost:${toString suwayomi.port}/api/v1/settings/about >/dev/null 2>&1; then
              echo "Suwayomi is ready"
            else
              echo "Warning: Suwayomi not responding"
            fi

            # Check container health
            for container in komga suwayomi${optionalString suwayomi.flaresolverr.enable " flaresolverr"}; do
              if ${pkgs.podman}/bin/podman ps --filter "name=$container" --format "{{.Status}}" | grep -q "Up"; then
                echo "$container container is running"
              else
                echo "Warning: $container container is not running"
              fi
            done
          '';
        };

        startAt = "hourly";
      };
    })
  ];
}
