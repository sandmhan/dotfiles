# Base LXC Container Configuration
# Foundation for all Proxmox LXC containers - optimized for resource efficiency
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
    ./monitoring.nix
  ];

  # System identification
  networking.hostName = lib.mkDefault systemSettings.hostname;

  # Locale and time
  time.timeZone = systemSettings.timezone;
  i18n.defaultLocale = systemSettings.locale;

  # Essential packages for LXC containers - lighter than VM equivalents
  environment.systemPackages = with pkgs; [
    vim
    htop
    curl
    wget
    git
    jq
    ncdu
    ripgrep
  ];

  # Nix configuration optimized for containers
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" userSettings.username ];
  };

  # More aggressive garbage collection for containers (limited storage)
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 14d";
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

  # LXC container filesystem configuration
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # LXC-specific optimizations
  boot = {
    # No bootloader needed in containers
    loader.grub.enable = lib.mkForce false;
    isContainer = true;

    # Optimize for container environment
    specialFileSystems = {
      "/proc" = { device = "proc"; fsType = "proc"; };
      "/sys" = { device = "sysfs"; fsType = "sysfs"; };
    };

    # Container-optimized kernel parameters
    kernel.sysctl = {
      # Reduce memory pressure in containers
      "vm.swappiness" = 10;
      "vm.dirty_ratio" = 15;
      "vm.dirty_background_ratio" = 5;
    };
  };

  # Enable SSH for remote management
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      PubkeyAuthentication = true;
    };
  };

  # Minimal systemd services for containers
  systemd.services = {
    # Disable services not needed in containers
    systemd-networkd-wait-online.enable = lib.mkForce false;
    NetworkManager-wait-online.enable = lib.mkForce false;
  };

  # Container-optimized networking
  networking = {
    # Use systemd-networkd for reliable container networking
    useNetworkd = true;
    useDHCP = lib.mkDefault true;

    # Disable systemd-resolved in containers to avoid conflicts
    useHostResolvConf = lib.mkForce false;

    # Simple firewall for containers
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 9100 ]; # SSH + monitoring
    };
  };

  # Disable systemd-resolved in containers
  services.resolved.enable = lib.mkForce false;

  # Enable systemd container detection
  environment.etc."machine-info".text = ''
    DEPLOYMENT=container
    CONTAINER=lxc
  '';

  # Container state version
  system.stateVersion = "26.05";
}