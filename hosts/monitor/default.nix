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

  # Enable comprehensive monitoring stack with VM-optimized settings
  homelab.monitoring = {
    enable = true;
    deploymentType = "vm";
    resourceProfile = "standard";

    # Override defaults only where VM deployment differs
    prometheus.staticTargets = {
      # Extend defaults with self-monitoring
      "node-exporters" = [
        "10.0.0.6:9100"     # matrix server
        "10.0.0.163:9100"   # agent-sandbox
        "10.0.0.200:9100"   # nixos-builder
        "localhost:9100"    # self (monitor)
        # Future targets will be added as services deploy
      ];

      # Keep other target defaults from module
      "wireguard" = [];
      "homelab-services" = [];
      "matrix-services" = [
        "10.0.0.6:8008"   # Matrix Synapse metrics endpoint
      ];
    };

    grafana.domain = "grafana.homelab.local";

    # VM-specific: Enable Loki for log aggregation (default based on deployment type)
    # loki.enable = true;  # Automatically enabled for VM deployments

    # VM-specific: Future alerting configuration
    # alerting.enable = true;  # Enable when notification channels configured
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

  # Monitoring packages provided by systemModule

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