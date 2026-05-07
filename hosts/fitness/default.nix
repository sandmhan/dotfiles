# Fitness Tracking (wger) VM Host Configuration
# Self-hosted fitness tracking with exercise, nutrition, and biometrics
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
    ../server/default.nix
    ../server/hardware-configuration.nix
    ../../systemModules/wger.nix
    ../../systemModules/sops.nix
  ];

  # System identification
  networking.hostName = systemSettings.hostname;

  # Enable wger with VM-optimized settings
  homelab.wger = {
    enable = true;
    deploymentType = "vm";
    resourceProfile = "standard";

    # Domain for reverse proxy access
    domain = "fitness.homelab.local";

    # Nginx reverse proxy
    reverseProxy.enable = true;

    # Prometheus monitoring
    monitoring.enable = true;
  };

  # Additional firewall rules for fitness VM access
  # All services on flat 10.0.0.0/24 network
  # TODO: Add services VLAN (10.0.20.0/24) rules once VLANs are deployed
  networking.firewall.extraCommands = ''
    # Allow wger web access from homelab network
    iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 8000 -j ACCEPT

    # Allow Prometheus scraping from homelab network
    iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 9100 -j ACCEPT
    iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 9101 -j ACCEPT
  '';

  # VM resource recommendations (configure on Proxmox host):
  # qm set 107 --cores 2 --memory 2048
  # qm set 107 --balloon 1024  # Allow memory ballooning from 1GB to 2GB
}
