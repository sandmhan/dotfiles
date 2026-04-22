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

  # Resource limits for safety
  boot.kernel.sysctl = {
    # Memory limits
    "vm.max_map_count" = 262144;
    # Network security
    "net.ipv4.ip_forward" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
  };

  # Container runtime for service testing
  virtualisation = {
    docker.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Agent user configuration
  users.users.agent = {
    isNormalUser = true;
    description = "Autonomous Agent User";
    extraGroups = [ "wheel" "docker" "podman" ];
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

  system.stateVersion = "24.11";
}