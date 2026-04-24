# Agent VM Network Configuration - Isolated and Restricted
{ config, lib, pkgs, ... }:

{
  networking = {
    # Use DHCP for initial setup, can be made static later
    useDHCP = lib.mkDefault true;

    # Firewall configuration for security
    firewall = {
      enable = true;

      # SSH and monitoring
      allowedTCPPorts = [ 22 9100 ];

      # Mosh UDP ports
      allowedUDPPortRanges = [ { from = 60000; to = 61000; } ];

      # Outbound restrictions - only allow necessary connections
      extraCommands = ''
        # Allow established connections
        iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

        # Allow loopback
        iptables -A OUTPUT -o lo -j ACCEPT

        # Allow DNS
        iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
        iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

        # Allow HTTP/HTTPS for Nix cache, GitHub, etc.
        iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
        iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

        # Allow SSH outbound (for git operations)
        iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT

        # Allow NTP
        iptables -A OUTPUT -p udp --dport 123 -j ACCEPT

        # Drop everything else by default
        iptables -A OUTPUT -j LOG --log-prefix "AGENT-BLOCKED: "
        iptables -A OUTPUT -j DROP
      '';
    };

    # Network namespace for container isolation
    networkmanager.enable = false;

    # DNS configuration
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };

  # Container network configuration
  systemd.services.setup-container-network = {
    description = "Setup isolated container network";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      # Create isolated bridge for containers
      ${pkgs.iproute2}/bin/ip link add name agent-br0 type bridge || true
      ${pkgs.iproute2}/bin/ip addr add 172.20.0.1/24 dev agent-br0 || true
      ${pkgs.iproute2}/bin/ip link set dev agent-br0 up || true

      # Configure iptables for container isolation
      ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 172.20.0.0/24 -o enp1s0 -j MASQUERADE || true
      ${pkgs.iptables}/bin/iptables -A FORWARD -i agent-br0 -o enp1s0 -j ACCEPT || true
      ${pkgs.iptables}/bin/iptables -A FORWARD -i enp1s0 -o agent-br0 -m state --state RELATED,ESTABLISHED -j ACCEPT || true
    '';
  };
}