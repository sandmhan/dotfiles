# Agent VM - Autonomous Infrastructure Development Sandbox
# Safe environment for Claude Code to operate with --dangerously-accept-permissions
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
    ../server/default.nix # Extend base Proxmox VM config
    ./hardware-configuration.nix # Hardware configuration
    ./networking.nix # Isolated network configuration
    ./ssh.nix # SSH access and hardening
    ./agent-tools.nix # Agent-specific tooling
  ];

  # System identification
  networking.hostName = "agent-sandbox";

  # Additional resource limits are configured in hardware-configuration.nix

  # Container runtime for service testing
  virtualisation = {
    docker.enable = true;
  };

  # Agent user configuration - full permissions for autonomous operation
  users.users.${userSettings.username} = {
    isNormalUser = true;
    description = "Autonomous Agent User";
    extraGroups = [
      "wheel"
      "docker"
      "root"
    ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3neihyMjSxDeNGI3rrrfEK2xltJ5fF8bmpU4IKqJWC framework"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIu3inxdaYkvuXPa3acucpVYNmWrQ7e1H5LCMyKqextU android-termux"
    ];
    # Agent should have passwordless sudo for autonomous operations
    hashedPassword = null; # No password required
  };

  # Keep sandmhan user for manual access and debugging (fallback user)
  users.users.sandmhan = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3neihyMjSxDeNGI3rrrfEK2xltJ5fF8bmpU4IKqJWC framework"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIu3inxdaYkvuXPa3acucpVYNmWrQ7e1H5LCMyKqextU android-termux"
    ];
  };

  # Workspace directory structure and Home Manager profile setup
  systemd.tmpfiles.rules = [
    "d /home/${userSettings.username}/workspace 0755 ${userSettings.username} ${userSettings.username} -"
    "d /home/${userSettings.username}/workspace/homelab 0755 ${userSettings.username} ${userSettings.username} -"
    "d /home/${userSettings.username}/workspace/testing 0755 ${userSettings.username} ${userSettings.username} -"
    "d /home/${userSettings.username}/workspace/deployments 0755 ${userSettings.username} ${userSettings.username} -"
    "d /home/${userSettings.username}/templates 0755 ${userSettings.username} ${userSettings.username} -"
    "d /home/${userSettings.username}/scripts 0755 ${userSettings.username} ${userSettings.username} -"
    "d /home/${userSettings.username}/logs 0755 ${userSettings.username} ${userSettings.username} -"
    # Home Manager profile directories
    "d /home/${userSettings.username}/.local 0755 ${userSettings.username} ${userSettings.username} -"
    "d /home/${userSettings.username}/.local/state 0755 ${userSettings.username} ${userSettings.username} -"
    "d /home/${userSettings.username}/.local/state/nix 0755 ${userSettings.username} ${userSettings.username} -"
    "d /home/${userSettings.username}/.local/state/nix/profiles 0755 ${userSettings.username} ${userSettings.username} -"
    "d /nix/var/nix/profiles/per-user/${userSettings.username} 0755 ${userSettings.username} ${userSettings.username} -"
  ];

  # System monitoring for agent activity
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [ "systemd" ];
  };

  # Agent sandbox security configuration - permissive for autonomous operation
  services.openssh = {
    settings = {
      StrictModes = false;
    };
  };

  # Ensure proper permissions for autonomous agent operations
  security.sudo.extraRules = [
    {
      users = [ userSettings.username ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
