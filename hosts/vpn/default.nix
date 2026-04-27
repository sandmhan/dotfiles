# Tailscale Subnet Router VM
# Dedicated always-on VM for phone/remote access into homelab subnets
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
    ../../systemModules/sops.nix
    ../../systemModules/tailscale.nix
  ];

  # System identification
  networking.hostName = systemSettings.hostname;

  # Tailscale subnet router — advertises homelab subnets for remote access
  homelab.tailscale = {
    enable = true;
    advertiseRoutes = [
      "10.0.0.0/24" # Management VLAN - Proxmox, SSH access
      "10.0.20.0/24" # Services VLAN - Matrix, Grafana, etc.
    ];
  };

  # Resource allocation — this is a lightweight relay, minimal resources needed
  # Configure at Proxmox VM level: qm set <vmid> --cores 1 --memory 1024

  # Optional: monitoring for network metrics
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [
      "systemd"
      "network"
    ];
  };
}
