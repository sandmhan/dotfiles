# Manga Stack Module
# Provides self-hosted manga reading with Komga (library server) and
# Suwayomi (source aggregator), both sourcing into Mihon on Android.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.homelab.manga;
in
{
  imports = [
    ./komga.nix
    ./suwayomi.nix
    ./monitoring.nix
  ];

  options.homelab.manga = {
    enable = mkEnableOption "Homelab manga stack (Komga + Suwayomi)";

    deploymentType = mkOption {
      type = types.enum [
        "vm"
        "container"
      ];
      default = "vm";
      description = "Deployment type - affects resource allocation and feature set";
    };

    resourceProfile = mkOption {
      type = types.enum [
        "minimal"
        "standard"
        "high"
      ];
      default = "standard";
      description = "Resource profile for automatic configuration optimization";
    };

    monitoring = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Prometheus node exporter and log forwarding for manga services";
      };
    };
  };

  config = mkIf cfg.enable {
    # Use podman as OCI runtime (shared by both services)
    virtualisation.oci-containers.backend = "podman";
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    # Create shared podman network for the manga stack
    systemd.services.manga-network = {
      description = "Create podman network for manga stack";
      wantedBy = [ "multi-user.target" ];
      before = [
        "podman-komga.service"
        "podman-suwayomi.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.podman}/bin/podman network create manga-net --ignore";
      };
    };

    # Base packages
    environment.systemPackages =
      let
        servicePackages = import ../packages.nix { inherit pkgs lib; };
      in
      servicePackages.base;

    # Firewall: SSH always open
    networking.firewall.allowedTCPPorts = [ 22 ];
  };
}
