# Monitoring Stack Module
# Provides comprehensive observability for homelab infrastructure
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  servicePackages = import ./packages.nix { inherit pkgs lib; };
  cfg = config.homelab.monitoring;

  # Build per-target static_configs with friendly instance labels
  # Extracts the host portion from "host:port" and looks it up in targetLabels
  labeledTargets =
    targets:
    map (
      addr:
      let
        host = builtins.head (lib.splitString ":" addr);
        label = cfg.prometheus.targetLabels.${host} or host;
      in
      {
        targets = [ addr ];
        labels.instance = label;
      }
    ) targets;

  # Provisioned dashboard JSON files
  dashboardsDir = pkgs.runCommand "grafana-homelab-dashboards" { } ''
    mkdir -p $out
    cp ${./grafana-dashboards/fleet-overview.json} $out/fleet-overview.json
    cp ${./grafana-dashboards/node-overview.json} $out/node-overview.json
    cp ${./grafana-dashboards/prometheus-stats.json} $out/prometheus-stats.json
    cp ${./grafana-dashboards/infrastructure-health.json} $out/infrastructure-health.json
  '';
in
{
  options.homelab.monitoring = {
    enable = mkEnableOption "Homelab monitoring stack (Prometheus + Grafana + Exporters)";

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

    prometheus = {
      enable = mkOption {
        type = types.bool;
        default = cfg.enable;
        description = "Enable Prometheus metrics collection";
      };

      port = mkOption {
        type = types.port;
        default = 9090;
        description = "Prometheus web interface port";
      };

      retention = mkOption {
        type = types.str;
        default =
          if cfg.deploymentType == "container" then
            "180d"
          else if cfg.resourceProfile == "minimal" then
            "90d"
          else
            "365d";
        description = "Prometheus data retention period";
      };

      scrapeInterval = mkOption {
        type = types.str;
        default = "15s";
        description = "Default scrape interval for targets";
      };

      # Static scrape targets for known homelab services
      staticTargets = mkOption {
        type = types.attrsOf (types.listOf types.str);
        default = {
          # Default homelab infrastructure targets
          "node-exporters" = [
            "10.0.0.6:9100" # matrix server
            "10.0.0.5:9100" # agent-sandbox
            "10.0.0.7:9100" # nixos-builder
            # PLACEHOLDER IPs — update after DHCP reservations are created
            "10.0.20.109:9100" # git (forgejo VM) — provisional IP
            "10.0.20.103:9100" # homeassistant VM — provisional IP
            "10.0.20.206:9100" # lxc-git — provisional IP
            "10.0.20.203:9100" # lxc-homeassistant — provisional IP
            "10.0.20.107:9100" # fitness (wger VM) — provisional IP
            "10.0.20.111:9100" # gaming (Sunshine VM) — provisional IP
            "10.0.20.110:9100" # media VM — provisional IP, needs DHCP assignment
            # "10.0.20.TBD:9100" # nvr (frigate) — add when static IP is assigned
          ];

          # Service-specific targets (populated by deployment type)
          "wireguard" = [ ];
          # PLACEHOLDER IPs — update after DHCP reservations are created
          "homelab-services" = [
            "10.0.20.109:9187" # git postgres exporter — provisional IP
            "10.0.20.103:8123" # homeassistant prometheus endpoint — provisional IP
          ];
          "matrix-services" = [
            "10.0.0.6:8008" # Matrix Synapse metrics endpoint
          ];
        };
        description = "Static scrape targets by job name";
      };

      # Friendly hostname labels for scrape targets
      # TODO: Remove when a DNS service is deployed — use hostname targets directly
      # and this mapping becomes unnecessary.
      targetLabels = mkOption {
        type = types.attrsOf types.str;
        default = {
          "10.0.0.5" = "agent-sandbox";
          "10.0.0.6" = "matrix";
          "10.0.0.7" = "nixos-builder";
          "10.0.0.10" = "lxc-monitor";
          # PLACEHOLDER IPs — update after DHCP reservations are created
          "10.0.20.109" = "git";
          "10.0.20.103" = "homeassistant";
          "10.0.20.206" = "lxc-git";
          "10.0.20.203" = "lxc-homeassistant";
          "10.0.20.107" = "fitness"; # provisional IP
          "10.0.20.111" = "gaming"; # provisional IP
          "10.0.20.110" = "media"; # provisional IP
          "localhost" = "lxc-monitor";
        };
        description = ''
          Map of IP/host to friendly instance name. Applied as the "instance"
          label on scrape targets. Temporary workaround until DNS is available.
        '';
      };

      # Additional scrape configs for specific services
      additionalScrapeConfigs = mkOption {
        type = types.listOf types.attrs;
        default = [
          # Default Matrix Synapse metrics configuration
          {
            job_name = "matrix-synapse";
            static_configs = [
              {
                targets = [ "10.0.0.6:8008" ];
                labels = {
                  service = "matrix-synapse";
                  instance = "matrix";
                };
              }
            ];
            metrics_path = "/_synapse/metrics";
            scrape_interval = "30s";
          }
        ];
        description = "Additional Prometheus scrape configurations";
      };
    };

    grafana = {
      enable = mkOption {
        type = types.bool;
        default = cfg.enable;
        description = "Enable Grafana visualization";
      };

      port = mkOption {
        type = types.port;
        default = 3000;
        description = "Grafana web interface port";
      };

      domain = mkOption {
        type = types.str;
        default = "grafana.homelab.local";
        description = "Grafana domain name";
      };

      # Admin credentials via sops
      adminPasswordFile = mkOption {
        type = types.path;
        default = config.sops.secrets."monitoring/grafana-admin-password".path;
        description = "Path to Grafana admin password file (sops-encrypted)";
      };

      # Default dashboards to provision
      enableDefaultDashboards = mkOption {
        type = types.bool;
        default = true;
        description = "Enable default homelab dashboards";
      };

      # SMTP settings for alerts (optional)
      smtp = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable SMTP for Grafana notifications";
        };

        host = mkOption {
          type = types.str;
          default = "";
          description = "SMTP server host";
        };

        user = mkOption {
          type = types.str;
          default = "";
          description = "SMTP username";
        };

        passwordFile = mkOption {
          type = types.path;
          default = config.sops.secrets."monitoring/smtp-password".path;
          description = "Path to SMTP password file";
        };
      };
    };

    # Node exporter is enabled by default on all homelab hosts
    nodeExporter = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable node exporter on this host";
      };

      port = mkOption {
        type = types.port;
        default = 9100;
        description = "Node exporter port";
      };

      enabledCollectors = mkOption {
        type = types.listOf types.str;
        default = [
          "systemd" # Systemd service metrics
          "processes" # Process information
          "interrupts" # Hardware interrupts
          "ksmd" # Kernel memory deduplication
          "logind" # Login session metrics
          "meminfo_numa" # NUMA memory info
          "mountstats" # Filesystem mount statistics
          "network_route" # Network routing table
          "tcpstat" # TCP connection statistics
          "wifi" # WiFi metrics (if applicable)
        ];
        description = "Enabled node exporter collectors";
      };
    };

    # Alerting configuration (future enhancement)
    alerting = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Prometheus alerting";
      };
    };

    # Loki for log aggregation (optional)
    loki = {
      enable = mkOption {
        type = types.bool;
        default = cfg.deploymentType == "vm" && cfg.resourceProfile != "minimal";
        description = "Enable Loki log aggregation";
      };

      port = mkOption {
        type = types.port;
        default = 3100;
        description = "Loki API port";
      };
    };
  };

  config = mkMerge [
    # Node Exporter Configuration (enabled on all hosts)
    (mkIf cfg.nodeExporter.enable {
      services.prometheus.exporters.node = {
        enable = true;
        port = cfg.nodeExporter.port;
        enabledCollectors = lib.unique cfg.nodeExporter.enabledCollectors;

        # Disable collectors that might not work in VMs/containers
        disabledCollectors = lib.unique [
          "edac" # Hardware error detection (not relevant in VMs)
          "hwmon" # Hardware monitoring (limited in VMs)
          "infiniband" # InfiniBand metrics (not applicable)
          "ipvs" # IPVS load balancer (not used)
          "mdadm" # Software RAID (not used)
          "nfsd" # NFS server metrics (only on NAS)
          "powersupplyclass" # Power supply info (not in VMs)
          "rapl" # Power capping (not in VMs)
          "thermal_zone" # Thermal information (limited in VMs)
          "xfs" # XFS filesystem (using ext4/btrfs)
          "zfs" # ZFS filesystem (not used currently)
        ];
      };

      # Open firewall for node exporter
      networking.firewall.allowedTCPPorts = [ cfg.nodeExporter.port ];
    })

    # Prometheus Configuration
    (mkIf cfg.prometheus.enable {

      services.prometheus = {
        enable = true;
        port = cfg.prometheus.port;
        listenAddress = "0.0.0.0"; # Allow access from other VLANs

        # Data retention and storage
        retentionTime = cfg.prometheus.retention;
        extraFlags = [
          "--storage.tsdb.retention.size=15GB" # Limit storage size
          "--web.enable-lifecycle" # Enable config reload API
          "--web.enable-admin-api" # Enable admin API
        ];

        globalConfig = {
          scrape_interval = cfg.prometheus.scrapeInterval;
          evaluation_interval = "15s";
          external_labels = {
            monitor = "homelab";
            replica = config.networking.hostName;
          };
        };

        # Scrape configurations
        scrapeConfigs = [
          # Self-monitoring
          {
            job_name = "prometheus";
            static_configs = [
              {
                targets = [ "localhost:${toString cfg.prometheus.port}" ];
                labels = {
                  instance = config.networking.hostName;
                  service = "prometheus";
                };
              }
            ];
          }

          # Node exporters on all homelab hosts
          # NOTE: Instance labels are set via targetLabels option (IP → hostname map).
          # TODO: When DNS is deployed, use hostname targets directly and remove targetLabels.
          {
            job_name = "node-exporter";
            static_configs = labeledTargets cfg.prometheus.staticTargets.node-exporters;
          }

          # WireGuard metrics (when VPN server is deployed)
          {
            job_name = "wireguard";
            static_configs = [
              {
                targets = cfg.prometheus.staticTargets.wireguard;
              }
            ];
          }

          # Homelab service metrics
          {
            job_name = "homelab-services";
            static_configs = [
              {
                targets = cfg.prometheus.staticTargets.homelab-services;
              }
            ];
          }
        ]
        ++ cfg.prometheus.additionalScrapeConfigs;
      };

      # Open firewall for Prometheus
      networking.firewall.allowedTCPPorts = [ cfg.prometheus.port ];

      # Monitoring packages from centralized registry
      environment.systemPackages =
        servicePackages.monitoring
        ++ (optionals (cfg.deploymentType == "vm") servicePackages.monitoringUtils)
        ++ servicePackages.base;
    })

    # Grafana Configuration
    (mkIf cfg.grafana.enable {
      # Ensure sops secrets exist when using encrypted admin password
      sops.secrets = {
        "monitoring/grafana-admin-password" = {
          mode = "0600";
          owner = "grafana";
          group = "grafana";
        };
      };

      services.grafana = {
        enable = true;

        settings = {
          server = {
            http_port = cfg.grafana.port;
            http_addr = "0.0.0.0"; # Allow external access
            domain = cfg.grafana.domain;
            root_url = "http://${cfg.grafana.domain}:${toString cfg.grafana.port}/";
            enable_gzip = true;
          };

          security = {
            admin_user = "admin";
            admin_password = "$__file{${cfg.grafana.adminPasswordFile}}";
            secret_key = "$__file{${cfg.grafana.adminPasswordFile}}"; # Use same for simplicity
            disable_gravatar = true;
            allow_embedding = false;
            cookie_samesite = "strict";
          };

          database = {
            type = "sqlite3";
            path = "/var/lib/grafana/grafana.db";
          };

          analytics = {
            reporting_enabled = false;
            check_for_updates = false;
          };

          log = {
            mode = "console file";
            level = "info";
            format = "text";
          };

          # SMTP configuration (if enabled)
          smtp = mkIf cfg.grafana.smtp.enable {
            enabled = true;
            host = "${cfg.grafana.smtp.host}:587";
            user = cfg.grafana.smtp.user;
            password = "$__file{${cfg.grafana.smtp.passwordFile}}";
            from_address = cfg.grafana.smtp.user;
            from_name = "Homelab Grafana";
            startTLS_policy = "MandatoryStartTLS";
          };
        };

        # Provision datasources
        provision = {
          enable = true;
          datasources.settings = {
            apiVersion = 1;
            datasources = [
              {
                name = "Prometheus";
                type = "prometheus";
                access = "proxy";
                url = "http://localhost:${toString cfg.prometheus.port}";
                isDefault = true;
                jsonData = {
                  timeInterval = "15s";
                  queryTimeout = "60s";
                  httpMethod = "POST";
                };
              }
            ]
            ++ optionals cfg.loki.enable [
              {
                name = "Loki";
                type = "loki";
                access = "proxy";
                url = "http://localhost:${toString cfg.loki.port}";
                jsonData = {
                  maxLines = 1000;
                  derivedFields = [
                    {
                      datasourceUid = "prometheus";
                      matcherRegex = "traceID=(\\w+)";
                      name = "TraceID";
                      url = "$${__value.raw}";
                    }
                  ];
                };
              }
            ];
          };

          # Default dashboards for homelab monitoring
          dashboards.settings = mkIf cfg.grafana.enableDefaultDashboards {
            apiVersion = 1;
            providers = [
              {
                name = "homelab";
                type = "file";
                folder = "Homelab";
                folderUid = "homelab";
                options.path = dashboardsDir;
                updateIntervalSeconds = 60;
                allowUiUpdates = true;
              }
            ];
          };
        };
      };

      # Open firewall for Grafana
      networking.firewall.allowedTCPPorts = [ cfg.grafana.port ];

      # Grafana packages already included in monitoring packages
    })

    # Loki Configuration (optional)
    (mkIf cfg.loki.enable {
      services.loki = {
        enable = true;

        configuration = {
          auth_enabled = false;

          server = {
            http_listen_port = cfg.loki.port;
            http_listen_address = "0.0.0.0";
          };

          common = {
            path_prefix = "/var/lib/loki";
            storage.filesystem = {
              chunks_directory = "/var/lib/loki/chunks";
              rules_directory = "/var/lib/loki/rules";
            };
            replication_factor = 1;
          };

          schema_config = {
            configs = [
              {
                from = "2024-01-01";
                store = "boltdb-shipper";
                object_store = "filesystem";
                schema = "v11";
                index = {
                  prefix = "index_";
                  period = "24h";
                };
              }
            ];
          };

          limits_config = {
            retention_period = "672h"; # 28 days
            ingestion_rate_mb = 4;
            ingestion_burst_size_mb = 6;
          };
        };
      };

      # Open firewall for Loki
      networking.firewall.allowedTCPPorts = [ cfg.loki.port ];
    })
  ];
}
