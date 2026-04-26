# Git Server (Forgejo) VM Host Configuration
# Full-featured Forgejo deployment on dedicated Proxmox VM
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
    ../server/default.nix
    ../server/hardware-configuration.nix
    ../../systemModules/forgejo.nix
    ../../systemModules/sops.nix
  ];

  # System identification
  networking.hostName = systemSettings.hostname;

  # Enable comprehensive Forgejo with VM-optimized settings
  homelab.forgejo = {
    enable = true;
    deploymentType = "vm";
    resourceProfile = "standard";

    domain = "git.homelab.local";

    lfs.enable = true;
    registration.enable = false;
    mirroring.enable = true;
    actions.enable = false; # Enable when CI/CD runner is needed
  };

  # VM-specific: additional firewall rules for VLAN access
  networking.firewall.extraCommands = ''
    # Allow Forgejo web access from management and services VLANs
    iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 443 -j ACCEPT
    iptables -A INPUT -s 10.0.20.0/24 -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -s 10.0.20.0/24 -p tcp --dport 443 -j ACCEPT

    # Allow Git SSH from all homelab networks
    iptables -A INPUT -s 10.0.0.0/16 -p tcp --dport 3022 -j ACCEPT
  '';

  # System tuning for Git workload
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 256;
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
  };
}
