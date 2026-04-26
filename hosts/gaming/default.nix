# Gaming VM Host Configuration
# Headless Sunshine game streaming server with GPU passthrough
# VM ID 108, 6 cores, 12GB RAM, 200GB disk
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
    ../../systemModules/sunshine-server.nix
    ../../systemModules/sops.nix
  ];

  # System identification
  networking.hostName = systemSettings.hostname;

  # Enable Sunshine with high-performance VM settings
  homelab.sunshine = {
    enable = true;
    deploymentType = "vm";
    resourceProfile = "high";

    # GPU passthrough configuration
    # PLACEHOLDER: Update PCI IDs after GPU passthrough is configured on Proxmox
    # On Proxmox host, find GPU PCI IDs with:
    #   lspci -nn | grep -i nvidia
    #   # Example output: 01:00.0 VGA compatible controller [0300]: NVIDIA Corporation ... [10de:2504]
    # Then configure passthrough in Proxmox VM config:
    #   qm set 108 --hostpci0 01:00.0,pcie=1,x-vga=1
    gpu = {
      pciId = "0000:01:00.0"; # PLACEHOLDER - update after passthrough setup
      driver = "nvidia";
      model = "RTX 3060"; # Or "GTX 1080 Ti" depending on available GPU
    };

    # Display configuration for streaming
    display = {
      resolution = "1920x1080";
      refreshRate = 60;
    };

    # Audio via PipeWire for game audio capture
    audio.backend = "pipewire";

    # Network defaults (Sunshine control and streaming ports)
    network = {
      upnp = false; # Homelab — no UPnP needed
    };
  };

  # GPU passthrough kernel configuration
  # PLACEHOLDER: These IOMMU and VFIO settings need to match the actual hardware
  boot = {
    kernelParams = [
      "intel_iommu=on" # PLACEHOLDER: Use "amd_iommu=on" for AMD host CPU
      "iommu=pt"
      # PLACEHOLDER: Add vfio-pci.ids for GPU passthrough
      # "vfio-pci.ids=10de:2504,10de:228e"  # NVIDIA GPU + Audio device IDs
    ];

    initrd.kernelModules = [
      # PLACEHOLDER: Enable vfio modules for GPU passthrough
      # "vfio_pci"
      # "vfio"
      # "vfio_iommu_type1"
    ];
  };

  # High-resource kernel tuning for gaming workload
  # 6 cores, 12GB RAM — optimize for low latency
  boot.kernel.sysctl = {
    # Huge pages for GPU memory management
    "vm.nr_hugepages" = 4096; # PLACEHOLDER: Tune based on actual RAM allocation

    # Reduce latency
    "kernel.sched_min_granularity_ns" = 1000000; # 1ms
    "kernel.sched_wakeup_granularity_ns" = 500000; # 0.5ms
    "kernel.sched_migration_cost_ns" = 5000000; # 5ms
  };

  # Additional firewall rules for gaming network access
  networking.firewall.extraCommands = ''
    # Allow Sunshine/Moonlight from local network
    iptables -A INPUT -s 10.0.0.0/16 -p tcp --dport 47984:47990 -j ACCEPT
    iptables -A INPUT -s 10.0.0.0/16 -p udp --dport 47998:48010 -j ACCEPT

    # Allow Sunshine web UI from management VLAN only
    iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 47990 -j ACCEPT

    # Allow Prometheus scraping from monitoring server
    iptables -A INPUT -s 10.0.20.0/24 -p tcp --dport 9100 -j ACCEPT
  '';

  # VM resource recommendations (configure on Proxmox host):
  # qm set 108 --cores 6 --memory 12288
  # qm set 108 --balloon 0  # Disable ballooning for gaming (consistent performance)
  # qm set 108 --cpu host    # CPU passthrough for best performance
  # qm set 108 --hostpci0 01:00.0,pcie=1,x-vga=1  # GPU passthrough

  # Looking Glass shared memory device (for local + remote simultaneous use)
  # PLACEHOLDER: Enable when Looking Glass is needed
  # qm set 108 --args '-device ivshmem-plain,memdev=ivshmem,bus=pci.0 -object memory-backend-file,id=ivshmem,share=on,mem-path=/dev/shm/looking-glass,size=128M'
}
