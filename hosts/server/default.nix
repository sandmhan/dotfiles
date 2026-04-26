{
  config,
  pkgs,
  lib,
  userSettings,
  systemSettings,
  ...
}:
let
  # Default disk size for VMs if not specified
  defaultDiskSize = 20 * 1024; # 20GB in MB
in
{
  imports = [
    ./ssh.nix
    # ./hardware-configuration.nix
    # ./security.nix
    ./networking.nix
    # ./monitoring.nix
  ];

  # Locale and time
  time.timeZone = systemSettings.timezone;
  i18n.defaultLocale = systemSettings.locale;

  # Trusted users for uploading nix store paths
  nix.settings.trusted-users = [
    "root"
    userSettings.username
  ];

  # Basic CLI tools you'll always want when SSHing in
  environment.systemPackages = with pkgs; [
    htop
    btop
    curl
    wget
    git
    vim
    tmux
    lsof
    ncdu # disk usage explorer
    ripgrep
    fd
    jq
    unzip
    rsync
  ];

  # Nix settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nixpkgs.config.allowUnfree = true;

  # Primary user
  users.users.${userSettings.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # Set this to your public key so you can SSH in immediately after install
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3neihyMjSxDeNGI3rrrfEK2xltJ5fF8bmpU4IKqJWC framework"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIu3inxdaYkvuXPa3acucpVYNmWrQ7e1H5LCMyKqextU android-termux"
    ];
  };

  # Passwordless sudo for wheel — fine for a homelab, tighten if exposed
  security.sudo.wheelNeedsPassword = false;

  # Enable GRUB Bootloader
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
  };

  # Enable QEMU Guest to access IP
  services.qemuGuest.enable = true;

  # Configure VM disk size (for image builds)
  virtualisation.diskSize =
    if (systemSettings ? diskSize) then
      systemSettings.diskSize
    else
      defaultDiskSize;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
