# Tailscale VPN Module
# Provides zero-config remote access to homelab services via Tailscale mesh VPN
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.homelab.tailscale;
in
{
  options.homelab.tailscale = {
    enable = mkEnableOption "Tailscale mesh VPN for homelab remote access";

    authKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to Tailscale auth key file. If null, uses sops secret at tailscale/auth-key";
    };

    exitNode = mkOption {
      type = types.bool;
      default = false;
      description = "Advertise this node as a Tailscale exit node";
    };

    advertiseRoutes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "10.0.0.0/24"
        "10.0.20.0/24"
      ];
      description = "Subnets to advertise to the Tailscale network (subnet router)";
    };

    acceptRoutes = mkOption {
      type = types.bool;
      default = true;
      description = "Accept routes advertised by other Tailscale nodes";
    };

    useRoutingFeatures = mkOption {
      type = types.enum [
        "none"
        "client"
        "server"
        "both"
      ];
      default = if cfg.advertiseRoutes != [ ] || cfg.exitNode then "server" else "client";
      description = "Enable routing features (server needed for subnet router / exit node)";
    };
  };

  config = mkIf cfg.enable {
    # Tailscale auth key from sops (optional — can also auth interactively)
    sops.secrets = mkIf (cfg.authKeyFile == null) {
      "tailscale/auth-key" = {
        sopsFile = ../secrets/tailscale/secrets.yaml;
        mode = "0600";
        owner = "root";
        group = "root";
      };
    };

    # Enable Tailscale daemon
    services.tailscale = {
      enable = true;
      useRoutingFeatures = cfg.useRoutingFeatures;
      authKeyFile =
        if cfg.authKeyFile != null then cfg.authKeyFile else config.sops.secrets."tailscale/auth-key".path;
      extraUpFlags =
        optionals (cfg.advertiseRoutes != [ ]) [
          "--advertise-routes=${concatStringsSep "," cfg.advertiseRoutes}"
        ]
        ++ optionals cfg.exitNode [
          "--advertise-exit-node"
        ]
        ++ optionals cfg.acceptRoutes [
          "--accept-routes"
        ];
    };

    # IP forwarding for subnet routing / exit node
    boot.kernel.sysctl = mkIf (cfg.advertiseRoutes != [ ] || cfg.exitNode) {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    # Allow Tailscale traffic through firewall
    networking.firewall = {
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };

    environment.systemPackages = [ pkgs.tailscale ];
  };
}
