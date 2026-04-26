# Minimal Agent VM Configuration - Extends Proxmox Base
# This boots reliably, then we push the full agent config via nixos-rebuild --target-host
{
  config,
  lib,
  pkgs,
  userSettings,
  systemSettings,
  ...
}:
{
  imports = [
    ../proxmox-base/default.nix
  ];

  # System identification
  networking.hostName = "agent-sandbox";

  # Agent user (minimal - no complex config yet)
  users.users.agent = {
    isNormalUser = true;
    description = "Autonomous Agent User";
    extraGroups = [ "wheel" ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      # Framework laptop SSH key for immediate access
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3neihyMjSxDeNGI3rrrfEK2xltJ5fF8bmpU4IKqJWC framework"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIu3inxdaYkvuXPa3acucpVYNmWrQ7e1H5LCMyKqextU android-termux"
    ];
  };

  # Essential additional packages for debugging
  environment.systemPackages = with pkgs; [
    # Add to proxmox-base essentials
    wget
    tmux
    lsof
    ncdu
    ripgrep
  ];

  # Basic workspace directory
  systemd.tmpfiles.rules = [
    "d /home/agent/workspace 0755 agent agent -"
  ];
}