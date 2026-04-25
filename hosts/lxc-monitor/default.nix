# Monitoring Stack LXC Container Configuration
# Resource-efficient alternative to VM deployment
{ config, lib, pkgs, userSettings, systemSettings, ... }: {
  imports = [
    ../lxc-base/default.nix
    ../../systemModules/monitoring.nix
    # SOPS module provides option schema; secrets are force-emptied below until bootstrapped
    # ../../systemModules/sops.nix  # homelab.sops wrapper disabled; sops-nix loaded via flake
  ];

  # System identification
  networking.hostName = systemSettings.hostname;

  # Enable monitoring stack optimized for container environment
  homelab.monitoring = {
    enable = true;
    deploymentType = "container";
    resourceProfile = "minimal";

    # Container-specific overrides only where needed
    prometheus.staticTargets = {
      # Override only the node exporters to include self
      "node-exporters" = [
        "10.0.0.6:9100"     # matrix server
        "10.0.0.5:9100"     # agent-sandbox
        "10.0.0.7:9100"     # nixos-builder
        "localhost:9100"    # self (lxc-monitor @ 10.0.0.10)
      ];
      # Keep other target defaults from module
      "wireguard" = [];
      "homelab-services" = [];
      "matrix-services" = [
        "10.0.0.6:8008"   # Matrix Synapse metrics endpoint
      ];
    };

    grafana.domain = "grafana.homelab.local";

    # Container-optimized node exporter collectors
    nodeExporter.enabledCollectors = [
      "systemd"
      "processes"
      "meminfo_numa"
      "mountstats"
      "tcpstat"
      "network_route"
    ];

    # Loki and alerting automatically disabled for container deployment
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

  # Packages provided by monitoring systemModule

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

  # SOPS secrets management - disabled until age keys are bootstrapped
  # TODO: Enable once SOPS is set up across the homelab
  # homelab.sops = {
  #   enable = true;
  #   deploymentType = "container";
  #   resourceProfile = "minimal";
  # };

  # Temporary: Grafana admin password via plain file until SOPS is bootstrapped
  # Change this password after first login
  homelab.monitoring.grafana.adminPasswordFile = lib.mkForce (
    pkgs.writeText "grafana-admin-pw" "homelabmonitor2026"
  );

  # Disable SOPS secret declarations from monitoring module (SOPS not yet bootstrapped)
  sops.secrets = lib.mkForce {};
}