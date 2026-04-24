# Monitoring Stack LXC Container Configuration
# Resource-efficient alternative to VM deployment
{ config, lib, pkgs, userSettings, systemSettings, ... }: {
  imports = [
    ../lxc-base/default.nix
    ../../systemModules/monitoring.nix
    ../../systemModules/sops.nix
  ];

  # System identification
  networking.hostName = systemSettings.hostname;

  # Enable monitoring stack optimized for container environment
  homelab.monitoring = {
    enable = true;

    prometheus = {
      enable = true;
      port = 9090;
      retention = "180d";  # Reduced retention for container deployment
      scrapeInterval = "15s";

      # Same target configuration as VM version
      staticTargets = {
        "node-exporters" = [
          "10.0.0.6:9100"     # matrix server
          "10.0.0.163:9100"   # agent-sandbox
          "10.0.0.200:9100"   # nixos-builder
          "localhost:9100"    # self (lxc-monitor)
        ];

        "wireguard" = [
          # VPN metrics when deployed
        ];

        "homelab-services" = [
          "10.0.0.6:8008"     # Matrix Synapse metrics
        ];
      };

      # Additional scrape configs
      additionalScrapeConfigs = [
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

      # SMTP disabled for container deployment
      smtp.enable = false;
    };

    # Node exporter for container self-monitoring
    nodeExporter = {
      enable = true;
      port = 9100;
      # Container-optimized collectors
      enabledCollectors = [
        "systemd"
        "processes"
        "meminfo_numa"
        "mountstats"
        "tcpstat"
        "network_route"
      ];
    };

    # Disable Loki in container to save resources
    loki.enable = false;
    alerting.enable = false;
  };

  # Override firewall to add monitoring ports
  networking.firewall.allowedTCPPorts = [
    22    # SSH (from lxc-base)
    3000  # Grafana
    9090  # Prometheus
    9100  # Node exporter (already in lxc-base)
  ];

  # Container-specific firewall rules for monitoring access
  networking.firewall.extraCommands = ''
    # Allow access from all homelab networks
    iptables -A INPUT -s 10.0.0.0/16 -p tcp -m multiport --dports 3000,9090 -j ACCEPT
  '';

  # Essential packages for container monitoring (extend base packages)
  environment.systemPackages = with pkgs; [
    prometheus
    # promtool is included with prometheus
    grafana
    # grafana-cli is included with grafana
    # Base packages already include: vim, htop, curl, wget, git, jq, ncdu, ripgrep
  ];

  # Container resource optimization
  boot.kernel.sysctl = {
    # Reduced limits for container (extend base sysctl)
    "fs.inotify.max_user_watches" = 131072;
    "fs.inotify.max_user_instances" = 128;
  };

  # Simplified health check for container
  systemd.services.monitoring-health-check = {
    description = "Container Monitoring Health Check";
    wantedBy = [ "multi-user.target" ];
    after = [ "prometheus.service" "grafana.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "container-health-check" ''
        sleep 10

        echo "Checking monitoring services in container..."

        # Quick health checks
        curl -f http://localhost:9090/-/ready && echo "✓ Prometheus ready"
        curl -f http://localhost:3000/api/health && echo "✓ Grafana ready"
        curl -f http://localhost:9100/metrics >/dev/null && echo "✓ Node exporter ready"
      '';
    };

    startAt = "hourly";
  };

  # Ensure sops integration
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
}