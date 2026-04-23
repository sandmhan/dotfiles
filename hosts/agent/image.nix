# Agent VM Image Configuration - Proxmox VMA Build
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-image.nix")
    ./default.nix
  ];

  # Proxmox-specific configuration
  proxmox = {
    # QEMU configuration for the VM
    qemuConf = {
      # Resource allocation for agent VM
      cores = 4;
      memory = 8192;  # 8GB RAM for development tasks

      # BIOS — SeaBIOS (proxmox-image module installs grub for legacy boot)
      bios = "seabios";

      # Network configuration
      net0 = "virtio=00:00:00:00:00:00,bridge=vmbr0,firewall=1";

      # Additional VM settings
      ostype = "l26";  # Linux kernel

      # Boot order
      boot = "order=scsi0";
    };
  };

  # Let proxmox-image module use its default disk size (auto-sized to closure + additionalSpace).
  # Disk can be resized after deployment with `qm resize <vmid> scsi0 +30G`.

  # Override filesystem config from hardware-configuration.nix
  # — the proxmox-image module provides its own filesystem layout
  fileSystems = lib.mkForce {
    "/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
  };
  swapDevices = lib.mkForce [ ];

  # Image optimization settings
  nix = {
    # Optimize store for smaller image size
    optimise.automatic = true;

    # Enable flakes for the image
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };

    # Garbage collection to minimize image size
    gc = {
      automatic = true;
      dates = "weekly";
      options = lib.mkForce "--delete-older-than 7d";
    };
  };

  # Disable GUI components to reduce image size
  services.xserver.enable = lib.mkForce false;
  fonts.packages = lib.mkForce [ ];

  # Minimal documentation
  documentation = {
    enable = true;
    nixos.enable = false;
    man.enable = true;
    info.enable = false;
    doc.enable = false;
  };

  # Network time synchronization
  services.timesyncd = {
    enable = true;
    servers = [ "pool.ntp.org" ];
  };

  # Essential services for VM
  services.resolved = {
    enable = true;
    dnssec = "false";
    fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
  };


  # Image build optimization
  system.activationScripts.cleanup = lib.stringAfter [ "etc" ] ''
    # Clean up unnecessary files to reduce image size
    rm -rf /tmp/* /var/tmp/* || true
    rm -rf /var/log/* || true
    rm -rf /root/.bash_history || true

    # Clear SSH host keys (will be regenerated on first boot)
    rm -f /etc/ssh/ssh_host_* || true

    # Ensure proper permissions
    chmod 755 /home/agent || true
    chown agent:agent /home/agent || true
  '';

  boot.tmp.useTmpfs = lib.mkDefault true;
}