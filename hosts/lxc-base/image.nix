# LXC Container Tarball Image for Proxmox
# Builds a .tar.xz that can be restored as a Proxmox LXC container
#
# Build:  nix build .#nixosConfigurations.initialLXC.config.system.build.tarball
# Result: result/tarball/nixos-system-x86_64-linux.tar.xz
#
# Restore on Proxmox:
#   pct create <CTID> /var/lib/vz/template/cache/<tarball>.tar.xz \
#     --hostname <name> --cores 1 --memory 1024 --storage local-zfs \
#     --net0 name=eth0,bridge=vmbr0,ip=dhcp,firewall=1 \
#     --features nesting=1 --unprivileged 1
{ config, lib, pkgs, modulesPath, userSettings, systemSettings, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  # proxmox-lxc module settings
  proxmoxLXC = {
    enable = true;
    privileged = false;
    manageNetwork = false; # Let Proxmox manage networking via DHCP/static
    manageHostName = false; # Hostname set by Proxmox at creation time
  };

  # Locale and time
  time.timeZone = systemSettings.timezone;
  i18n.defaultLocale = systemSettings.locale;

  # Nix configuration
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" userSettings.username ];
  };

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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3neihyMjSxDeNGI3rrrfEK2xltJ5fF8bmpU4IKqJWC framework"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIu3inxdaYkvuXPa3acucpVYNmWrQ7e1H5LCMyKqextU android-termux"
    ];
  };

  # Also allow root SSH for initial setup (nixos-rebuild --target-host needs this or sudo)
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3neihyMjSxDeNGI3rrrfEK2xltJ5fF8bmpU4IKqJWC framework"
  ];

  security.sudo.wheelNeedsPassword = false;

  # Essential packages
  environment.systemPackages = with pkgs; [
    vim
    htop
    curl
    wget
    git
    jq
  ];

  # SSH enabled by proxmox-lxc module defaults, but ensure key-only auth
  services.openssh.settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "prohibit-password";
    PubkeyAuthentication = true;
  };

  # Minimal journald for containers
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    SystemMaxFileSize=10M
    MaxRetentionSec=7day
  '';

  # Container-optimized kernel parameters
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.dirty_ratio" = 15;
    "vm.dirty_background_ratio" = 5;
  };

  system.stateVersion = "26.05";
}
