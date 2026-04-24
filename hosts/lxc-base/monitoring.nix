# LXC Container Monitoring Configuration
# Lightweight monitoring setup for resource-constrained containers
{ config, lib, pkgs, ... }:
{
  # Prometheus node exporter for container metrics
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;

    # Container-optimized collectors - avoid hardware-specific ones
    # Use mkDefault so the monitoring module can override without duplication
    enabledCollectors = lib.mkDefault [
      "systemd"
      "filesystem"
      "loadavg"
      "meminfo"
      "netdev"
      "stat"
      "time"
      "uname"
    ];

    # Disable collectors that don't work well in containers
    disabledCollectors = lib.mkDefault [
      "arp"
      "hwmon"
      "ipvs"
      "mdadm"
      "powersupplyclass"
      "thermal_zone"
      "wifi"
    ];
  };

  # Basic log management for containers
  services.journald.extraConfig = ''
    # Limit log size in containers
    SystemMaxUse=100M
    SystemMaxFileSize=10M
    SystemMaxFiles=10
    MaxRetentionSec=7day
  '';

  # Open monitoring port in firewall
  networking.firewall.allowedTCPPorts = [ 9100 ];

  # Minimal systemd services health monitoring
  systemd.services.container-health-check = {
    description = "Container Health Check";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --failed --no-legend";
      User = "nobody";
    };
    # Run every 5 minutes
    startAt = "*:0/5";
  };

  # Container resource monitoring script
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "container-stats" ''
      #!/bin/bash
      echo "=== Container Resource Usage ==="
      echo "CPU Usage:"
      ${htop}/bin/htop -n 1 | head -5
      echo
      echo "Memory Usage:"
      free -h
      echo
      echo "Disk Usage:"
      df -h /
      echo
      echo "Network Stats:"
      cat /proc/net/dev | head -3
    '')
  ];
}