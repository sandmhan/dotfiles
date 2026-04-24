# WireGuard VPN Server Module
# Provides secure remote access to homelab services
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.homelab.wireguard;
in
{
  options.homelab.wireguard = {
    enable = mkEnableOption "WireGuard VPN server for homelab remote access";

    interface = mkOption {
      type = types.str;
      default = "wg0";
      description = "WireGuard interface name";
    };

    serverPort = mkOption {
      type = types.port;
      default = 51820;
      description = "UDP port for WireGuard server";
    };

    vpnSubnet = mkOption {
      type = types.str;
      default = "10.100.0.0/24";
      description = "VPN subnet for WireGuard clients";
    };

    serverIP = mkOption {
      type = types.str;
      default = "10.100.0.1/24";
      description = "Server IP within VPN subnet";
    };

    allowedSubnets = mkOption {
      type = types.listOf types.str;
      default = [
        "10.0.0.0/24"    # Management VLAN
        "10.0.20.0/24"   # Services VLAN
      ];
      description = "Homelab subnets accessible via VPN";
    };

    # Client configurations will be managed via sops-nix secrets
    clientsSecretFile = mkOption {
      type = types.path;
      default = config.sops.secrets."wireguard/clients".path;
      description = "Path to sops-encrypted client configurations";
    };

    privateKeyFile = mkOption {
      type = types.path;
      default = config.sops.secrets."wireguard/server-private-key".path;
      description = "Path to server private key (sops-encrypted)";
    };

    publicKey = mkOption {
      type = types.str;
      description = "Server public key (safe to be in git)";
      example = "server_public_key_here";
    };
  };

  config = mkIf cfg.enable {
    # Ensure sops secrets are defined
    sops.secrets = {
      "wireguard/server-private-key" = {
        mode = "0600";
        owner = "root";
        group = "root";
      };
      "wireguard/clients" = {
        mode = "0600";
        owner = "root";
        group = "root";
      };
    };

    # Enable IP forwarding for VPN routing
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    # Configure NAT for VPN clients to access homelab subnets
    networking.nat = {
      enable = true;
      externalInterface = "ens18";  # Proxmox VM default interface
      internalInterfaces = [ cfg.interface ];
    };

    # Firewall configuration
    networking.firewall = {
      allowedUDPPorts = [ cfg.serverPort ];

      # Allow VPN subnet access to homelab services
      extraCommands = ''
        # Allow VPN clients to access homelab subnets
        ${concatMapStringsSep "\n" (subnet:
          "iptables -A FORWARD -s ${cfg.vpnSubnet} -d ${subnet} -j ACCEPT"
        ) cfg.allowedSubnets}

        # Allow return traffic
        iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

        # Allow VPN interface traffic
        iptables -A INPUT -i ${cfg.interface} -j ACCEPT
        iptables -A OUTPUT -o ${cfg.interface} -j ACCEPT
      '';

      extraStopCommands = ''
        # Cleanup rules on firewall stop
        ${concatMapStringsSep "\n" (subnet:
          "iptables -D FORWARD -s ${cfg.vpnSubnet} -d ${subnet} -j ACCEPT 2>/dev/null || true"
        ) cfg.allowedSubnets}

        iptables -D FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
        iptables -D INPUT -i ${cfg.interface} -j ACCEPT 2>/dev/null || true
        iptables -D OUTPUT -o ${cfg.interface} -j ACCEPT 2>/dev/null || true
      '';
    };

    # WireGuard interface configuration
    networking.wireguard.interfaces.${cfg.interface} = {
      ips = [ cfg.serverIP ];
      listenPort = cfg.serverPort;
      privateKeyFile = cfg.privateKeyFile;

      # Note: Client peers will be managed via NixOS config generation
      # Dynamic peer loading from encrypted file will be handled via
      # systemd service instead of postSetup (which conflicts with networkd)
    };

    # Monitoring integration
    services.prometheus.exporters.wireguard = mkIf config.services.prometheus.enable {
      enable = true;
      port = 9586;
      wireguardConfig = "/etc/wireguard/${cfg.interface}.conf";
    };

    # Systemd service for client management
    systemd.services.wireguard-client-manager = {
      description = "WireGuard Client Configuration Manager";
      wantedBy = [ "multi-user.target" ];
      after = [ "wireguard-${cfg.interface}.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "wg-client-manager" ''
          # Script to reload client configs from sops when secrets change
          echo "WireGuard client manager started"
          # Future: watch for changes to client secret file and reload
        '';
      };
    };

    # Include useful WireGuard management tools
    environment.systemPackages = with pkgs; [
      wireguard-tools  # wg, wg-quick commands
      qrencode         # Generate QR codes for mobile clients
    ];
  };
}