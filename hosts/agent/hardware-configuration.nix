# Agent VM Hardware Configuration - Proxmox VM Environment
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Boot loader configuration
  boot = {
    initrd = {
      availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
        "sr_mod"
      ];
      kernelModules = [ ];
    };

    kernelModules = [
      "kvm-intel"
      "kvm-amd"
    ];
    extraModulePackages = [ ];

    # Use GRUB for compatibility with base server config
    loader.grub = {
      enable = true;
      device = "/dev/vda";
    };

    # Kernel parameters for VM optimization
    kernelParams = [
      "console=tty0"
      "console=ttyS0,115200"
      "earlyprintk=ttyS0,115200"
      "consoleblank=0"
    ];

    # Additional virtio support is included in availableKernelModules above

    # Clean temporary files on boot
    tmp.cleanOnBoot = true;
  };

  # File systems configuration - Generic for VMA images
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [
      "defaults"
      "noatime"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [ "defaults" ];
  };

  # Tmpfs for better performance
  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "defaults"
      "noatime"
      "mode=1777"
      "size=2G"
    ];
  };

  # Swap configuration
  swapDevices = [
    {
      device = "/var/swapfile";
      size = 2048; # 2GB swap
    }
  ];

  # Hardware-specific settings
  hardware = {
    # Enable all firmware
    enableAllFirmware = true;

    # CPU microcode updates
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };

  # VM-specific services
  services = {
    # QEMU guest agent for Proxmox integration
    qemuGuest.enable = true;

    # Spice agent for better VM integration
    spice-vdagentd.enable = true;

    # Automatic filesystem checking
    fstrim = {
      enable = true;
      interval = "weekly";
    };
  };

  # Virtualization settings
  virtualisation = {
    # Enable nested virtualization for container testing
    kvmgt.enable = false; # Not needed for this use case

    # Container runtime configuration
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };
      storageDriver = "overlay2";
      daemon.settings = {
        live-restore = false;
        userland-proxy = false;
        experimental = false;
        metrics-addr = "127.0.0.1:9323";
        log-driver = "journald";
        log-opts = {
          max-size = "10m";
          max-file = "3";
        };
        default-ulimits = {
          nofile = {
            hard = 64000;
            soft = 64000;
          };
        };
      };
    };

    # OCI container backend
    oci-containers.backend = "docker";
  };

  # Resource management and optimization
  systemd.services = {
    # Automatic memory management
    systemd-oomd = {
      enable = true;
    };

    # VM performance tuning
    vm-tune = {
      description = "VM performance tuning";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # I/O scheduler optimization for VMs
        echo mq-deadline > /sys/block/vda/queue/scheduler 2>/dev/null || true

        # VM-specific kernel parameters
        echo 1 > /proc/sys/vm/swappiness
        echo 10 > /proc/sys/vm/dirty_ratio
        echo 5 > /proc/sys/vm/dirty_background_ratio

        # Network optimizations
        echo 1 > /proc/sys/net/core/netdev_max_backlog
        echo 1 > /proc/sys/net/ipv4/tcp_window_scaling
        echo 1 > /proc/sys/net/ipv4/tcp_timestamps
      '';
    };
  };

  # Power management for VMs
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "ondemand";
  };

  # Kernel configuration
  boot.kernel.sysctl = {
    # Memory management
    "vm.swappiness" = 10;
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
    "vm.vfs_cache_pressure" = 50;
    "vm.min_free_kbytes" = 65536;

    # Network optimization
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.core.netdev_max_backlog" = 5000;
    "net.ipv4.tcp_window_scaling" = 1;
    "net.ipv4.tcp_rmem" = "4096 65536 134217728";
    "net.ipv4.tcp_wmem" = "4096 65536 134217728";

    # Security settings
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
  };

  # Platform detection
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
