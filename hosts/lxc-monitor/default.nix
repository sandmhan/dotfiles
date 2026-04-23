# Monitoring Stack LXC Container Configuration
# Prometheus + Grafana + lightweight monitoring in a container
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
  networking.hostName = "lxc-monitor";

  # Monitoring-specific firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22    # SSH management
      3000  # Grafana web UI
      9090  # Prometheus web UI
      9100  # Node exporter (self)
    ];
  };

  # Prometheus monitoring server
  services.prometheus = {
    enable = true;
    port = 9090;

    # Scrape configuration for all homelab services
    scrapeConfigs = [
      {
        job_name = "node-exporters";
        static_configs = [
          {
            # Add all VM/container node exporters here
            targets = [
              "lxc-monitor:9100"    # Self
              "lxc-matrix:9100"     # Matrix container
              "lxc-git:9100"        # Git container
              "lxc-nas:9100"        # NAS container
              "agent-sandbox:9100"  # Agent VM
              "10.0.0.126:9100"     # Proxmox host
            ];
          }
        ];
      }

      {
        job_name = "postgres-exporters";
        static_configs = [
          {
            targets = [
              "lxc-matrix:9187"  # Matrix PostgreSQL
              "lxc-git:9187"     # Forgejo PostgreSQL
            ];
          }
        ];
      }

      {
        job_name = "matrix-synapse";
        static_configs = [
          {
            targets = [
              "lxc-matrix:8008"  # Matrix Synapse metrics
            ];
          }
        ];
      }
    ];

    # Retention and storage optimization for containers
    extraFlags = [
      "--storage.tsdb.retention.time=30d"
      "--storage.tsdb.retention.size=2GB"
      "--web.enable-lifecycle"
    ];
  };

  # Grafana dashboard server
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
        domain = "monitor.homelab.local";
      };

      # Container-optimized settings
      database = {
        type = "sqlite3";
        path = "/var/lib/grafana/grafana.db";
      };

      # Authentication
      security = {
        admin_user = "admin";
        admin_password = "admin"; # Change this in production with sops-nix
      };

      # Enable anonymous access for homelab
      auth.anonymous = {
        enabled = true;
        org_role = "Viewer";
      };
    };

    # Provision Prometheus datasource
    provision = {
      enable = true;
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://localhost:9090";
            isDefault = true;
          }
        ];
      };

      # Pre-built dashboards
      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "homelab";
            type = "file";
            folder = "Homelab";
            path = "/var/lib/grafana/dashboards";
          }
        ];
      };
    };
  };

  # Create dashboard directory and add basic dashboards
  systemd.tmpfiles.rules = [
    "d /var/lib/grafana/dashboards 0755 grafana grafana -"
  ];

  # Basic Node Exporter dashboard
  environment.etc."grafana/dashboards/node-exporter.json".source = pkgs.writeText "node-exporter-dashboard.json" ''
    {
      "dashboard": {
        "id": null,
        "title": "Node Exporter Full",
        "tags": ["node-exporter"],
        "timezone": "browser",
        "panels": [
          {
            "title": "CPU Usage",
            "type": "graph",
            "targets": [
              {
                "expr": "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
              }
            ]
          },
          {
            "title": "Memory Usage",
            "type": "graph",
            "targets": [
              {
                "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100"
              }
            ]
          },
          {
            "title": "Disk Usage",
            "type": "graph",
            "targets": [
              {
                "expr": "100 - ((node_filesystem_avail_bytes{mountpoint=\"/\"} * 100) / node_filesystem_size_bytes{mountpoint=\"/\"})"
              }
            ]
          }
        ],
        "time": {
          "from": "now-1h",
          "to": "now"
        },
        "refresh": "30s"
      }
    }
  '';

  # Container resource optimization
  systemd.services = {
    prometheus.serviceConfig = {
      MemoryMax = "512M";
      CPUQuota = "50%";
    };

    grafana.serviceConfig = {
      MemoryMax = "256M";
      CPUQuota = "25%";
    };
  };
}