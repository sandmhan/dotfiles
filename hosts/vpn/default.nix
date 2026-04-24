# WireGuard VPN Server Host Configuration
# Dedicated VM or service for homelab remote access
{ config, lib, pkgs, userSettings, systemSettings, ... }: {
  imports = [
    ../server/default.nix
    ../../systemModules/wireguard.nix
    ../../systemModules/sops.nix
  ];

  # System identification
  networking.hostName = systemSettings.hostname;

  # Enable WireGuard VPN server
  homelab.wireguard = {
    enable = true;

    # Standard configuration for homelab
    interface = "wg0";
    serverPort = 51820;
    vpnSubnet = "10.100.0.0/24";
    serverIP = "10.100.0.1/24";

    # Server public key (safe to store in git)
    # Generate with: echo $SERVER_PRIVATE_KEY | wg pubkey
    publicKey = "YOUR_SERVER_PUBLIC_KEY_HERE";

    # Homelab subnets accessible via VPN
    allowedSubnets = [
      "10.0.0.0/24"    # Management VLAN - Proxmox, SSH access
      "10.0.20.0/24"   # Services VLAN - Matrix, Grafana, etc.
      # "10.0.10.0/24" # IoT VLAN - Only if needed for camera access
    ];
  };

  # Additional firewall rules for VPN server
  networking.firewall = {
    # Allow SSH access from VPN clients
    extraCommands = ''
      # Allow SSH from VPN subnet
      iptables -A INPUT -s 10.100.0.0/24 -p tcp --dport 22 -j ACCEPT
    '';
  };

  # Resource allocation for VPN server
  # This can run on minimal resources
  virtualisation.memorySize = lib.mkDefault 1024;  # 1GB RAM
  virtualisation.cores = lib.mkDefault 1;          # 1 CPU core

  # Optional: Enable monitoring for VPN metrics
  services.prometheus.enable = true;
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [ "systemd" "network" ];
  };

  # Useful packages for VPN management
  environment.systemPackages = with pkgs; [
    wireguard-tools
    qrencode
    jq  # For parsing client JSON configs
  ];

  # Ensure sops age key exists
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
}