# Minimal Proxmox VM Base Configuration
# This is the foundation that all Proxmox VMs extend from.
# PRINCIPLE: Boot first, add features second.
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
    ./networking.nix
    ./ssh.nix
  ];

  # System identification
  networking.hostName = lib.mkDefault systemSettings.hostname;

  # Locale and time
  time.timeZone = systemSettings.timezone;
  i18n.defaultLocale = systemSettings.locale;

  # Essential packages only - no heavy tools that could cause boot issues
  environment.systemPackages = with pkgs; [
    vim
    htop
    curl
    git
  ];

  # Nix configuration
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" userSettings.username ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nixpkgs.config.allowUnfree = true;

  # Primary user with SSH access
  users.users.${userSettings.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # Framework laptop SSH key for immediate access
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3neihyMjSxDeNGI3rrrfEK2xltJ5fF8bmpU4IKqJWC framework"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIu3inxdaYkvuXPa3acucpVYNmWrQ7e1H5LCMyKqextU android-termux"
    ];
  };

  # Passwordless sudo for homelab convenience
  security.sudo.wheelNeedsPassword = false;

  # Boot configuration - GRUB on /dev/vda for Proxmox VMs
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
  };

  # QEMU guest agent for Proxmox integration
  services.qemuGuest.enable = true;

  # Prometheus node exporter for monitoring (lightweight, stable)
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [ "systemd" ];
  };

  # Keep firewall simple - SSH + monitoring only
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 9100 ];
  };

  system.stateVersion = "26.05";
}