# Monitoring Stack VM Host Configuration
# Provides comprehensive observability for homelab infrastructure
{ config, lib, pkgs, userSettings, systemSettings, ... }: {
  imports = [
    ../server/default.nix
    ../server/hardware-configuration.nix
    ../../systemModules/monitoring.nix
    ../../systemModules/sops.nix
  ];

  # System identification
  networking.hostName = systemSettings.hostname;

  # Enable comprehensive monitoring stack
  homelab.monitoring = {
    enable = true;

    prometheus = {
      enable = true;
      port = 9090;
      retention = "365d";  # Keep metrics for 1 year
      scrapeInterval = "15s";

      # Configure targets for all known homelab services
      staticTargets = {
        "node-exporters" = [
          "10.0.0.6:9100"     # matrix server
          "10.0.0.163:9100"   # agent-sandbox
          "10.0.0.200:9100"   # nixos-builder
          "localhost:9100"    # self (monitor)
          # Add more as services are deployed:
          # "10.0.20.101:9100" # nas server
          # "10.0.20.102:9100" # vpn server
          # "10.0.20.103:9100" # git server
        ];

        "wireguard" = [
          # "10.0.20.102:9586"  # VPN server wireguard metrics (when deployed)
        ];

        "homelab-services" = [
          "10.0.0.6:8008"     # Matrix Synapse metrics endpoint (if enabled)
          # Add service-specific metrics endpoints as they're deployed
        ];
      };

      # Additional scrape configs for future services
      additionalScrapeConfigs = [
        # Example: Matrix Synapse metrics (when configured)
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
    };

    grafana = {
      enable = true;
      port = 3000;
      domain = "grafana.homelab.local";
      enableDefaultDashboards = true;

      # SMTP configuration (optional - disabled by default)
      smtp = {
        enable = false;
        # host = "smtp.gmail.com";
        # user = "homelab@yourdomain.com";
        # Configure via sops secrets when needed
      };
    };

    # Enable node exporter for self-monitoring
    nodeExporter = {
      enable = true;
      port = 9100;
    };

    # Optional: Enable Loki for log aggregation
    loki = {
      enable = false;  # Enable when log aggregation is needed
      port = 3100;
    };

    # Future: Enable alerting when notification channels are configured
    alerting = {
      enable = false;
    };
  };

  # Additional firewall rules for monitoring access
  networking.firewall = {
    allowedTCPPorts = [
      3000  # Grafana web interface
      9090  # Prometheus web interface
      9100  # Node exporter metrics
      # 3100  # Loki (if enabled)
    ];

    # Allow monitoring access from all homelab VLANs
    extraCommands = ''
      # Allow Grafana access from management and services VLANs
      iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 3000 -j ACCEPT
      iptables -A INPUT -s 10.0.20.0/24 -p tcp --dport 3000 -j ACCEPT

      # Allow Prometheus access from services VLAN (for federation)
      iptables -A INPUT -s 10.0.20.0/24 -p tcp --dport 9090 -j ACCEPT

      # Allow scraping from monitoring server to all networks
      iptables -A OUTPUT -d 10.0.0.0/16 -p tcp --dport 9100 -j ACCEPT
    '';
  };

  # Optimize for monitoring workload
  # VM should be configured at Proxmox level:
  # qm set <vmid> --cores 2 --memory 4096

  # Additional monitoring tools and utilities
  environment.systemPackages = with pkgs; [
    # Prometheus tools
    prometheus
    promtool

    # Grafana tools
    grafana-cli

    # Monitoring utilities
    htop
    iotop
    nethogs
    iftop

    # Network diagnostics
    curl
    dig
    nmap

    # Log analysis
    jq
    yq-go

    # Performance monitoring
    sysstat
    tcpdump
  ];

  # System tuning for monitoring workload
  boot.kernel.sysctl = {
    # Increase inotify limits for file watching
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 256;

    # Network tuning for metrics collection
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.core.netdev_max_backlog" = 5000;
  };

  # Backup configuration for monitoring data (future enhancement)
  # systemd.timers.monitoring-backup = {
  #   wantedBy = [ "timers.target" ];
  #   timerConfig = {
  #     OnCalendar = "daily";
  #     Persistent = true;
  #   };
  # };

  # Ensure sops age key exists for secrets management
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  # Custom services for monitoring health checks
  systemd.services.monitoring-health-check = {
    description = "Monitoring Stack Health Check";
    wantedBy = [ "multi-user.target" ];
    after = [ "prometheus.service" "grafana.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "monitoring-health-check" ''
        # Wait for services to be ready
        sleep 30

        # Check Prometheus is responding
        if curl -f http://localhost:9090/-/ready >/dev/null 2>&1; then
          echo "Prometheus is ready"
        else
          echo "Warning: Prometheus not responding"
        fi

        # Check Grafana is responding
        if curl -f http://localhost:3000/api/health >/dev/null 2>&1; then
          echo "Grafana is ready"
        else
          echo "Warning: Grafana not responding"
        fi

        # Check node exporter is responding
        if curl -f http://localhost:9100/metrics >/dev/null 2>&1; then
          echo "Node exporter is ready"
        else
          echo "Warning: Node exporter not responding"
        fi
      '';
    };

    # Run health check periodically
    startAt = "hourly";
  };
}