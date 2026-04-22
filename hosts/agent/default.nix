# Agent VM - Autonomous Infrastructure Development Sandbox
# Safe environment for Claude Code to operate with --dangerously-accept-permissions
{
  config,
  lib,
  pkgs,
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

  # Agent user configuration
  users.users.agent = {
    isNormalUser = true;
    description = "Autonomous Agent User";
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      # SSH key will be configured in ssh.nix
    ];
  };

  # Workspace directory structure
  systemd.tmpfiles.rules = [
    "d /home/agent/workspace 0755 agent agent -"
    "d /home/agent/workspace/homelab 0755 agent agent -"
    "d /home/agent/workspace/testing 0755 agent agent -"
    "d /home/agent/workspace/deployments 0755 agent agent -"
    "d /home/agent/templates 0755 agent agent -"
    "d /home/agent/scripts 0755 agent agent -"
    "d /home/agent/logs 0755 agent agent -"
  ];

  # System monitoring for agent activity
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [ "systemd" ];
  };
}
