# wger Fitness Tracking Module
# Provides self-hosted fitness tracking with OCI containers (Django, PostgreSQL, Redis, Celery)
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  servicePackages = import ./packages.nix { inherit pkgs lib; };
  cfg = config.homelab.wger;
in
{
  options.homelab.wger = {
    enable = mkEnableOption "Homelab wger fitness tracking application";

    deploymentType = mkOption {
      type = types.enum [
        "vm"
        "container"
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
      default = "fitness.homelab.local";
      description = "Domain name for the wger web interface";
    };

    httpPort = mkOption {
      type = types.port;
      default = 8000;
      description = "HTTP port for the wger Django application";
    };

    # Nginx reverse proxy
    reverseProxy = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Nginx reverse proxy in front of wger";
      };
    };

    # Container image versions
    images = {
      wger = mkOption {
        type = types.str;
        default = "wger/server:latest";
        description = "OCI image for the wger Django application";
      };

      postgres = mkOption {
        type = types.str;
        default = "docker.io/library/postgres:15-alpine";
        description = "OCI image for PostgreSQL database";
      };

      redis = mkOption {
        type = types.str;
        default = "docker.io/library/redis:7-alpine";
        description = "OCI image for Redis cache";
      };
    };

    # Database configuration
    database = {
      name = mkOption {
        type = types.str;
        default = "wger";
        description = "PostgreSQL database name";
      };

      user = mkOption {
        type = types.str;
        default = "wger";
        description = "PostgreSQL database user";
      };
    };

    # Monitoring integration
    monitoring = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Prometheus monitoring (node exporter and wger /metrics endpoint)";
      };
    };
  };

  config = mkMerge [
    # OCI container stack
    (mkIf cfg.enable {
      # SOPS secrets for wger
      sops.secrets = {
        "wger/django-secret-key" = {
          mode = "0644";
        };
        "wger/postgres-password" = {
          mode = "0644";
        };
      };

      # Use podman as OCI runtime
      virtualisation.oci-containers.backend = "podman";
      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };

      # PostgreSQL container
      virtualisation.oci-containers.containers.wger-db = {
        image = cfg.images.postgres;
        environment = {
          POSTGRES_DB = cfg.database.name;
          POSTGRES_USER = cfg.database.user;
          POSTGRES_PASSWORD = "wger_db_password"; # Overridden at runtime via env file
        };
        volumes = [
          "wger-postgres-data:/var/lib/postgresql/data"
        ];
        extraOptions = [
          "--network=wger-net"
          "--health-cmd=pg_isready -U ${cfg.database.user}"
          "--health-interval=10s"
          "--health-timeout=5s"
          "--health-retries=5"
        ];
      };

      # Redis container
      virtualisation.oci-containers.containers.wger-redis = {
        image = cfg.images.redis;
        extraOptions = [
          "--network=wger-net"
          "--health-cmd=redis-cli ping"
          "--health-interval=10s"
          "--health-timeout=5s"
          "--health-retries=5"
        ];
      };

      # wger Django application container
      virtualisation.oci-containers.containers.wger = {
        image = cfg.images.wger;
        ports = [ "${toString cfg.httpPort}:80" ];
        environment = {
          # Django settings
          DJANGO_DB_ENGINE = "django.db.backends.postgresql";
          DJANGO_DB_DATABASE = cfg.database.name;
          DJANGO_DB_USER = cfg.database.user;
          DJANGO_DB_PASSWORD = "wger_db_password"; # Overridden at runtime via env file
          DJANGO_DB_HOST = "wger-db";
          DJANGO_DB_PORT = "5432";
          DJANGO_CACHE_BACKEND = "django_redis.cache.RedisCache";
          DJANGO_CACHE_LOCATION = "redis://wger-redis:6379/1";
          SITE_URL = "http://${cfg.domain}";
          DJANGO_MEDIA_ROOT = "/home/wger/media";
          DJANGO_STATIC_ROOT = "/home/wger/static";
          TIME_ZONE = "America/New_York";
          # Enable Prometheus metrics endpoint
          ENABLE_PROMETHEUS = if cfg.monitoring.enable then "True" else "False";
          # Celery broker
          CELERY_BROKER = "redis://wger-redis:6379/2";
          CELERY_BACKEND = "redis://wger-redis:6379/2";
        };
        volumes = [
          "wger-media:/home/wger/media"
          "wger-static:/home/wger/static"
        ];
        dependsOn = [
          "wger-db"
          "wger-redis"
        ];
        extraOptions = [
          "--network=wger-net"
        ];
      };

      # Celery worker container
      virtualisation.oci-containers.containers.wger-celery = {
        image = cfg.images.wger;
        cmd = [
          "/start-celery"
        ];
        environment = {
          DJANGO_DB_ENGINE = "django.db.backends.postgresql";
          DJANGO_DB_DATABASE = cfg.database.name;
          DJANGO_DB_USER = cfg.database.user;
          DJANGO_DB_PASSWORD = "wger_db_password"; # Overridden at runtime via env file
          DJANGO_DB_HOST = "wger-db";
          DJANGO_DB_PORT = "5432";
          DJANGO_CACHE_BACKEND = "django_redis.cache.RedisCache";
          DJANGO_CACHE_LOCATION = "redis://wger-redis:6379/1";
          CELERY_BROKER = "redis://wger-redis:6379/2";
          CELERY_BACKEND = "redis://wger-redis:6379/2";
          TIME_ZONE = "America/New_York";
        };
        volumes = [
          "wger-media:/home/wger/media"
        ];
        dependsOn = [
          "wger-db"
          "wger-redis"
        ];
        extraOptions = [
          "--network=wger-net"
        ];
      };

      # Create podman network for wger stack
      systemd.services.wger-network = {
        description = "Create podman network for wger stack";
        wantedBy = [ "multi-user.target" ];
        before = [
          "podman-wger-db.service"
          "podman-wger-redis.service"
          "podman-wger.service"
          "podman-wger-celery.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.podman}/bin/podman network create wger-net --ignore";
        };
      };

      # Packages from centralized registry
      environment.systemPackages = servicePackages.base;
    })

    # Nginx reverse proxy
    (mkIf (cfg.enable && cfg.reverseProxy.enable) {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;

        virtualHosts.${cfg.domain} = {
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
          ];

          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString cfg.httpPort}";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header X-Forwarded-Proto $scheme;
              client_max_body_size 20M;
            '';
          };

          # Serve static files directly if volume is mounted locally
          locations."/static/" = {
            proxyPass = "http://127.0.0.1:${toString cfg.httpPort}/static/";
          };

          locations."/media/" = {
            proxyPass = "http://127.0.0.1:${toString cfg.httpPort}/media/";
          };
        };
      };
    })

    # Node exporter for Prometheus monitoring
    (mkIf (cfg.enable && cfg.monitoring.enable) {
      services.prometheus.exporters.node = {
        enable = true;
        port = 9100;
        enabledCollectors = [
          "systemd"
          "processes"
        ]
        ++ optionals (cfg.deploymentType == "vm") [
          "interrupts"
          "logind"
        ];
      };

      networking.firewall.allowedTCPPorts = [ 9100 ];
    })

    # Firewall configuration
    (mkIf cfg.enable {
      networking.firewall.allowedTCPPorts = [
        22
      ]
      ++ (optionals cfg.reverseProxy.enable [ 80 ])
      ++ (optionals (!cfg.reverseProxy.enable) [ cfg.httpPort ]);
    })

    # Systemd resource limits based on deployment type
    (mkIf (cfg.enable && cfg.deploymentType == "container") {
      systemd.services.podman-wger.serviceConfig = {
        MemoryMax = "512M";
        CPUQuota = "50%";
      };
      systemd.services.podman-wger-db.serviceConfig = {
        MemoryMax = "256M";
        CPUQuota = "25%";
      };
      systemd.services.podman-wger-redis.serviceConfig = {
        MemoryMax = "64M";
        CPUQuota = "10%";
      };
      systemd.services.podman-wger-celery.serviceConfig = {
        MemoryMax = "256M";
        CPUQuota = "25%";
      };
    })

    (mkIf (cfg.enable && cfg.deploymentType != "container" && cfg.resourceProfile == "minimal") {
      systemd.services.podman-wger.serviceConfig = {
        MemoryMax = "768M";
        CPUQuota = "75%";
      };
      systemd.services.podman-wger-db.serviceConfig = {
        MemoryMax = "512M";
        CPUQuota = "50%";
      };
    })

    # Health check service
    (mkIf cfg.enable {
      systemd.services.wger-health-check = {
        description = "wger Fitness Tracker Health Check";
        wantedBy = [ "multi-user.target" ];
        after = [
          "podman-wger.service"
          "podman-wger-db.service"
          "podman-wger-redis.service"
        ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "wger-health-check" ''
            sleep 30

            echo "Checking wger services..."

            # Check wger web interface
            if ${pkgs.curl}/bin/curl -sf http://localhost:${toString cfg.httpPort}/api/v2/ >/dev/null 2>&1; then
              echo "wger web interface is ready"
            else
              echo "Warning: wger web interface not responding"
            fi

            # Check Nginx (if enabled)
            ${optionalString cfg.reverseProxy.enable ''
              if ${pkgs.curl}/bin/curl -sf http://localhost:80/ >/dev/null 2>&1; then
                echo "Nginx reverse proxy is ready"
              else
                echo "Warning: Nginx not responding"
              fi
            ''}

            # Check container health
            for container in wger-db wger-redis wger wger-celery; do
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
