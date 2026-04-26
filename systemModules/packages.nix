# Centralized Package Registry for systemModules
# Provides consistent package definitions across all homelab services
{ pkgs, lib, ... }:

with lib;

rec {
  # Base packages for all homelab systems
  base = with pkgs; [
    # System administration
    htop
    iotop
    sysstat

    # Network tools
    curl
    dig
    nmap
    tcpdump

    # Text processing
    jq
    yq-go

    # File utilities
    ncdu
    ripgrep
  ];

  # Monitoring stack packages
  monitoring = with pkgs; [
    prometheus
    grafana
    # Note: promtool and grafana-cli are included with their respective packages
  ];

  # Monitoring utilities (for monitoring hosts)
  monitoringUtils = with pkgs; [
    # Performance monitoring
    nethogs
    iftop

    # Network diagnostics
    nmap
    tcpdump
  ];

  # WireGuard VPN packages
  wireguard = with pkgs; [
    wireguard-tools # wg, wg-quick commands
    qrencode # Generate QR codes for mobile clients
  ];

  # WireGuard management utilities (for VPN hosts)
  wireguardUtils = with pkgs; [
    jq # For parsing client JSON configs
  ];

  # NAS/Storage packages
  nas = with pkgs; [
    nfs-utils # NFS server and client utilities
    samba # SMB/CIFS file sharing
    rsync # File synchronization
    rclone # Cloud storage sync
    borgbackup # Deduplicating backup program
  ];

  # NAS utilities (for VM deployments)
  nasUtils = with pkgs; [
    smartmontools # Disk monitoring
    hdparm # Hard disk utilities
    lsof # List open files
    tree # Directory tree display
    fzf # Fuzzy finder for navigation
    ncdu # Disk usage analyzer (already in base, but relevant)
  ];

  # Git server packages
  git = [
    pkgs.git
    pkgs.git-lfs
  ];

  # AI/ML packages
  ai = with pkgs; [
    # Will be populated when AI modules are created
  ];

  # Media server packages
  media = with pkgs; [
    ffmpeg
    imagemagick
  ];

  # Development tools (for development-focused hosts)
  development = [
    pkgs.git
    pkgs.vim
    pkgs.tmux
    pkgs.screen
  ];

  # Function to get packages for a specific service
  getServicePackages =
    service:
    if
      builtins.hasAttr service (
        builtins.removeAttrs finalPackages [
          "base"
          "getServicePackages"
        ]
      )
    then
      base ++ (builtins.getAttr service finalPackages)
    else
      base;

  # Function to get packages for multiple services
  getCombinedPackages =
    services:
    base
    ++ (lib.lists.flatten (
      map (
        service:
        if
          builtins.hasAttr service (
            builtins.removeAttrs finalPackages [
              "base"
              "getServicePackages"
              "getCombinedPackages"
            ]
          )
        then
          builtins.getAttr service finalPackages
        else
          [ ]
      ) services
    ));

  # Final package collection with all sets and utility functions
  finalPackages = {
    inherit
      base
      monitoring
      monitoringUtils
      wireguard
      wireguardUtils
      nas
      nasUtils
      git
      ai
      media
      development
      ;
    inherit getServicePackages getCombinedPackages;
  };
}
