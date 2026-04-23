# Agent VM - Autonomous Infrastructure Development Sandbox
# Safe environment for Claude Code to operate with --dangerously-accept-permissions
{ config, lib, pkgs, systemSettings, ... }:

{
  imports = [
    ../server/default.nix  # Extend base Proxmox VM config
    ./hardware-configuration.nix  # Hardware configuration
    ./networking.nix       # Isolated network configuration
    ./ssh.nix             # SSH access and hardening
    ./agent-tools.nix     # Agent-specific tooling
  ];

  # System identification
  networking.hostName = "agent-sandbox";

  # Additional resource limits are configured in hardware-configuration.nix

  # Container runtime for service testing
  virtualisation = {
    docker.enable = true;
  };

  # Agent user configuration - full permissions for autonomous operation
  users.users.agent = {
    isNormalUser = true;
    description = "Autonomous Agent User";
    extraGroups = [ "wheel" "docker" "root" ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3neihyMjSxDeNGI3rrrfEK2xltJ5fF8bmpU4IKqJWC framework"
    ];
    # Agent should have passwordless sudo for autonomous operations
    hashedPassword = null; # No password required
  };

  # Keep sandmhan user for manual access and debugging
  users.users.${userSettings.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3neihyMjSxDeNGI3rrrfEK2xltJ5fF8bmpU4IKqJWC framework"
    ];
  };

  # Workspace directory structure and Home Manager profile setup
  systemd.tmpfiles.rules = [
    "d /home/agent/workspace 0755 agent agent -"
    "d /home/agent/workspace/homelab 0755 agent agent -"
    "d /home/agent/workspace/testing 0755 agent agent -"
    "d /home/agent/workspace/deployments 0755 agent agent -"
    "d /home/agent/templates 0755 agent agent -"
    "d /home/agent/scripts 0755 agent agent -"
    "d /home/agent/logs 0755 agent agent -"
    # Home Manager profile directories
    "d /home/agent/.local 0755 agent agent -"
    "d /home/agent/.local/state 0755 agent agent -"
    "d /home/agent/.local/state/nix 0755 agent agent -"
    "d /home/agent/.local/state/nix/profiles 0755 agent agent -"
    "d /nix/var/nix/profiles/per-user/agent 0755 agent agent -"
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
      # Relaxed host key checking for sandbox environment
      StrictModes = false;
    };
  };

  # Ensure proper permissions for autonomous agent operations
  security.sudo.extraRules = [
    {
      users = [ "agent" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Environment etc files for SSH authorized keys
  environment.etc = {
    "ssh/authorized_keys.d/agent".text = ''
      ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3neihyMjSxDeNGI3rrrfEK2xltJ5fF8bmpU4IKqJWC framework
    '';
    "ssh/authorized_keys.d/sandmhan".text = ''
      ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID3neihyMjSxDeNGI3rrrfEK2xltJ5fF8bmpU4IKqJWC framework
    '';
  };
}