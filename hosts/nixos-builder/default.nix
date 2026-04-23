{
  config,
  pkgs,
  lib,
  userSettings,
  systemSettings,
  ...
}:
{
  imports = [
    ../server/default.nix
  ];

  networking.hostName = "nixos-builder";

  # Basic filesystem configuration for Proxmox VM deployment
  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };

  # Optimize for building
  nix.settings = {
    max-jobs = "auto";          # Use all available cores
    cores = 6;                  # All VM cores for single builds
    builders-use-substitutes = true;

    # Large build sandbox and parallel builds
    sandbox-paths = [
      "/tmp"
      "/var/tmp"
    ];

    # Optimize for build performance
    keep-going = true;
    keep-failed = true;
    log-lines = 50;
  };

  # Large temporary storage for builds
  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "size=8G" ];     # Large tmpfs for build artifacts
  };

  # Builder-specific services
  services = {
    # Git daemon for receiving configuration updates
    gitDaemon = {
      enable = true;
      basePath = "/srv/git";
      user = "git";
      group = "git";
    };
  };

  # Git user for repository management
  users.users.git = {
    isSystemUser = true;
    group = "git";
    home = "/srv/git";
    createHome = true;
  };
  users.groups.git = {};

  # Deployment and build tools
  environment.systemPackages = with pkgs; [
    nixos-rebuild
    git
    nix
    curl
    wget
    rsync
    jq
    # Build optimization tools
    ccache
    distcc
  ];

  # Firewall for git daemon
  networking.firewall = {
    allowedTCPPorts = [ 9418 ];  # Git daemon
  };

  # Ensure main user can build and deploy
  users.users.${userSettings.username} = {
    extraGroups = [ "git" ];
  };
}