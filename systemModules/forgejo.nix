# Forgejo Git Server Module
# Provides self-hosted Git service with PostgreSQL, Nginx, and monitoring integration
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  servicePackages = import ./packages.nix { inherit pkgs lib; };
  cfg = config.homelab.forgejo;
in
{
  options.homelab.forgejo = {
    enable = mkEnableOption "Homelab Forgejo Git server";

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
      default = "git.homelab.local";
      description = "Domain name for the Forgejo instance";
    };

    sshPort = mkOption {
      type = types.port;
      default = 3022;
      description = "SSH port for Git operations";
    };

    httpPort = mkOption {
      type = types.port;
      default = 3000;
      description = "HTTP port for Forgejo web interface";
    };

    lfs = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Git Large File Storage support";
      };
    };

    registration = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable open user registration (disabled for homelab)";
      };
    };

    mirroring = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable repository mirroring (e.g., GitHub mirror support)";
      };
    };

    actions = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Forgejo Actions CI/CD runner";
      };
    };

    # Nginx reverse proxy
    nginx = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Nginx reverse proxy in front of Forgejo";
      };

      forceSSL = mkOption {
        type = types.bool;
        default = false;
        description = "Force SSL (set to true if using real certificates)";
      };
    };

    # PostgreSQL exporter for monitoring integration
    postgresExporter = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Prometheus PostgreSQL exporter for monitoring";
      };

      port = mkOption {
        type = types.port;
        default = 9187;
        description = "PostgreSQL exporter metrics port";
      };
    };
  };

  config = mkMerge [
    # PostgreSQL backend
    (mkIf cfg.enable {
      services.postgresql = {
        enable = true;
        ensureDatabases = [ "forgejo" ];
        ensureUsers = [
          {
            name = "forgejo";
            ensureDBOwnership = true;
          }
        ];

        # Deployment-type-aware tuning
        settings = mkMerge [
          (mkIf (cfg.deploymentType == "container") {
            shared_buffers = "64MB";
            effective_cache_size = "256MB";
            maintenance_work_mem = "32MB";
            work_mem = "4MB";
          })
          (mkIf (cfg.deploymentType != "container" && cfg.resourceProfile == "minimal") {
            shared_buffers = "128MB";
            effective_cache_size = "512MB";
            maintenance_work_mem = "64MB";
            work_mem = "8MB";
          })
          (mkIf (cfg.deploymentType != "container" && cfg.resourceProfile == "high") {
            shared_buffers = "512MB";
            effective_cache_size = "2GB";
            maintenance_work_mem = "256MB";
            work_mem = "32MB";
            max_connections = "200";
          })
          (mkIf (cfg.deploymentType != "container" && cfg.resourceProfile == "standard") {
            shared_buffers = "256MB";
            effective_cache_size = "1GB";
            maintenance_work_mem = "128MB";
            work_mem = "16MB";
          })
        ];
      };
    })

    # Forgejo service
    (mkIf cfg.enable {
      # SOPS secrets for admin password and secret key
      sops.secrets = {
        "forgejo-admin-password" = {
          mode = "0600";
          owner = "forgejo";
          group = "forgejo";
        };
        "forgejo-secret-key" = {
          mode = "0600";
          owner = "forgejo";
          group = "forgejo";
        };
      };

      services.forgejo = {
        enable = true;
        database = {
          type = "postgres";
          host = "/run/postgresql";
          name = "forgejo";
          user = "forgejo";
        };

        settings = {
          server = {
            DOMAIN = cfg.domain;
            ROOT_URL = "https://${cfg.domain}/";
            HTTP_PORT = cfg.httpPort;
            SSH_PORT = cfg.sshPort;
            DISABLE_SSH = false;
            START_SSH_SERVER = true;
            LFS_START_SERVER = cfg.lfs.enable;
          };

          service = {
            REGISTER_EMAIL_CONFIRM = false;
            ENABLE_NOTIFY_MAIL = false;
            DISABLE_REGISTRATION = !cfg.registration.enable;
          };

          mirror = mkIf cfg.mirroring.enable {
            ENABLED = true;
            DEFAULT_INTERVAL = "8h";
          };

          actions = mkIf cfg.actions.enable {
            ENABLED = true;
          };

          security = {
            SECRET_KEY = "$__file{${config.sops.secrets."forgejo-secret-key".path}}";
            INSTALL_LOCK = true;
          };

          # Cache and session configuration based on deployment type
          cache = {
            ENABLED = true;
            ADAPTER = if cfg.deploymentType == "container" then "memory" else "memory";
          };

          session = {
            PROVIDER = if cfg.deploymentType == "container" then "memory" else "db";
          };

          log = {
            LEVEL = if cfg.resourceProfile == "high" then "Debug" else "Info";
          };

          # Repository settings
          repository = {
            DEFAULT_BRANCH = "main";
            ENABLE_PUSH_CREATE_USER = true;
            ENABLE_PUSH_CREATE_ORG = true;
          };
        };
      };

      # Packages from centralized registry
      environment.systemPackages =
        servicePackages.git
        ++ (optionals (cfg.deploymentType == "vm") [ pkgs.postgresql ])
        ++ servicePackages.base;
    })

    # Nginx reverse proxy
    (mkIf (cfg.enable && cfg.nginx.enable) {
      services.nginx = {
        enable = true;
        recommendedTlsSettings = true;
        recommendedOptimisation = true;
        recommendedGzipSettings = true;
        recommendedProxySettings = true;

        virtualHosts.${cfg.domain} = {
          forceSSL = cfg.nginx.forceSSL;
          locations."/" = {
            proxyPass = "http://localhost:${toString cfg.httpPort}";
            proxyWebsockets = true;
          };
        };
      };
    })

    # PostgreSQL exporter for monitoring integration
    (mkIf (cfg.enable && cfg.postgresExporter.enable) {
      services.prometheus.exporters.postgres = {
        enable = true;
        port = cfg.postgresExporter.port;
        dataSourceName = "postgresql:///forgejo?host=/run/postgresql&user=forgejo";
      };
    })

    # Node exporter for Prometheus monitoring
    (mkIf cfg.enable {
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
    })

    # Firewall configuration
    (mkIf cfg.enable {
      networking.firewall.allowedTCPPorts = [
        22
        cfg.sshPort
      ]
      ++ (optionals cfg.nginx.enable [
        80
        443
      ])
      ++ (optionals (!cfg.nginx.enable) [ cfg.httpPort ])
      ++ [ 9100 ] # Node exporter
      ++ (optionals cfg.postgresExporter.enable [ cfg.postgresExporter.port ]);
    })

    # Systemd resource limits based on deployment type
    (mkIf (cfg.enable && cfg.deploymentType == "container") {
      systemd.services.forgejo.serviceConfig = {
        MemoryMax = "512M";
        CPUQuota = "50%";
      };
      systemd.services.postgresql.serviceConfig = {
        MemoryMax = "256M";
        CPUQuota = "25%";
      };
      systemd.services.nginx = mkIf cfg.nginx.enable {
        serviceConfig = {
          MemoryMax = "64M";
          CPUQuota = "10%";
        };
      };
    })

    (mkIf (cfg.enable && cfg.deploymentType != "container" && cfg.resourceProfile == "minimal") {
      systemd.services.forgejo.serviceConfig = {
        MemoryMax = "768M";
        CPUQuota = "75%";
      };
      systemd.services.postgresql.serviceConfig = {
        MemoryMax = "512M";
        CPUQuota = "50%";
      };
    })

    # Health check service
    (mkIf cfg.enable {
      systemd.services.forgejo-health-check = {
        description = "Forgejo Health Check";
        wantedBy = [ "multi-user.target" ];
        after = [
          "forgejo.service"
          "postgresql.service"
        ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "forgejo-health-check" ''
            sleep 15

            echo "Checking Forgejo services..."

            # Check PostgreSQL
            if ${pkgs.postgresql}/bin/pg_isready -q; then
              echo "PostgreSQL is ready"
            else
              echo "Warning: PostgreSQL not responding"
            fi

            # Check Forgejo web interface
            if ${pkgs.curl}/bin/curl -sf http://localhost:${toString cfg.httpPort}/api/v1/version >/dev/null 2>&1; then
              echo "Forgejo web interface is ready"
            else
              echo "Warning: Forgejo web interface not responding"
            fi

            # Check Nginx (if enabled)
            ${optionalString cfg.nginx.enable ''
              if ${pkgs.curl}/bin/curl -sf http://localhost:80/ >/dev/null 2>&1; then
                echo "Nginx reverse proxy is ready"
              else
                echo "Warning: Nginx not responding"
              fi
            ''}
          '';
        };

        startAt = "hourly";
      };
    })
  ];
}
