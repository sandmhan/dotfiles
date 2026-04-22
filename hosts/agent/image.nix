# Agent VM Image Configuration - Proxmox VMA Build
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

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
      memory = 8192; # 8GB RAM for development tasks

      # BIOS configuration
      bios = "ovmf"; # UEFI boot

      # Network configuration
      net0 = "virtio=00:00:00:00:00:00,bridge=vmbr0,firewall=1";

      # Additional VM settings
      ostype = "l26"; # Linux kernel
      onboot = "0"; # Don't auto-start

      # Boot order
      boot = "order=scsi0";
    };
  };

  # Image-specific overrides
  system.build.proximoxImage = lib.mkForce (
    pkgs.callPackage (modulesPath + "/virtualisation/proxmox-image.nix") {
      inherit config lib pkgs;

      # Custom image settings
      imageFormat = "qcow2";
      imageName = "nixos-agent-vm";
      imageSize = "40G";

      # Additional packages for the image
      extraPackages = with pkgs; [
        # Ensure cloud-init is available for initial setup
        cloud-init

        # Network tools for connectivity
        iproute2
        iptables

        # SSH for remote access
        openssh

        # Basic utilities
        coreutils
        util-linux

        # Filesystem tools
        e2fsprogs
        dosfstools
      ];
    }
  );

  # Cloud-init configuration for initial setup
  services.cloud-init = {
    enable = true;
    settings = {
      # Disable unwanted modules
      cloud_config_modules = [
        "migrator"
        "seed_random"
        "bootcmd"
        "write-files"
        "growpart"
        "resizefs"
        "disk_setup"
        "mounts"
        "set_hostname"
        "update_hostname"
        "update_etc_hosts"
        "ca-certs"
        "rsyslog"
        "users-groups"
        "ssh"
      ];

      cloud_final_modules = [
        "package-update-upgrade-install"
        "puppet"
        "chef"
        "mcollective"
        "salt-minion"
        "reset_rmc"
        "refresh_rmc_and_interface"
        "rightscale_userdata"
        "scripts-vendor"
        "scripts-per-once"
        "scripts-per-boot"
        "scripts-per-instance"
        "scripts-user"
        "ssh-authkey-fingerprints"
        "keys-to-console"
        "final-message"
      ];

      # System configuration
      system_info = {
        default_user = {
          name = "agent";
          groups = [
            "wheel"
            "docker"
            "podman"
          ];
          sudo = [ "ALL=(ALL) NOPASSWD:ALL" ];
          shell = "/bin/bash";
        };
      };

      # SSH configuration
      ssh_pwauth = false;
      ssh_authorized_keys = [
        # Placeholder - will be replaced during deployment
        # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... agent-vm-access"
      ];

      # Timezone and locale
      timezone = "UTC";
      locale = "en_US.UTF-8";

      # Package management
      package_update = true;
      package_upgrade = false;
      package_reboot_if_required = false;

      # Network configuration
      network = {
        version = 2;
        ethernets = {
          enp1s0 = {
            dhcp4 = true;
            dhcp6 = false;
          };
        };
      };

      # Disk configuration
      growpart = {
        mode = "auto";
        devices = [ "/" ];
        ignore_growroot_disabled = false;
      };
    };
  };

  # Image optimization settings
  nix = {
    # Optimize store for smaller image size
    optimise.automatic = true;

    # Enable flakes for the image
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };

    # Garbage collection to minimize image size
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Disable GUI components to reduce image size
  services.xserver.enable = lib.mkForce false;
  fonts.packages = lib.mkForce [ ];
  sound.enable = lib.mkForce false;

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
    fallbackDns = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  # Systemd-networkd for reliable networking
  systemd.network = {
    enable = true;
    networks."10-ethernet" = {
      matchConfig.Name = "enp*";
      networkConfig = {
        DHCP = "ipv4";
        IPV6AcceptRA = true;
      };
      dhcpV4Config = {
        UseDNS = true;
        UseRoutes = true;
      };
    };
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

  # Ensure the image has a proper filesystem layout
  boot.initrd.systemd.enable = true;
  boot.tmp.useTmpfs = lib.mkDefault true;
}
