{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../../systemModules/llama.nix
  ];

  # GPU passthrough and performance optimizations
  boot = {
    # Kernel modules for GPU passthrough
    initrd.kernelModules = [ "vfio-pci" ];
    kernelModules = [ "vfio-pci" ];

    # GPU passthrough kernel parameters
    kernelParams = [
      # Enable IOMMU (uncomment based on CPU)
      "intel_iommu=on" # For Intel CPUs
      # "amd_iommu=on"  # For AMD CPUs

      # Bind GPU to VFIO (replace with your GPU's vendor:device ID)
      # Find with: lspci -nn | grep -i nvidia
      # "vfio-pci.ids=10de:2204"
      "video=efifb:off"
      "video=vesa:off"
    ];

    # Blacklist GPU drivers to allow VFIO binding
    blacklistedKernelModules = [ "nouveau" ];
  };

  # Enable llama.cpp service (custom module under homelab.llama namespace)
  homelab.llama = {
    enable = true;
    host = "0.0.0.0"; # Listen on all interfaces for API access
    port = 8080;
    models = {
      # Default models directory
      modelsPath = "/var/lib/llama-cpp/models";
    };
    # GPU acceleration
    acceleration = "cuda"; # or "opencl" depending on GPU
  };

  # Additional GPU-related packages
  environment.systemPackages = with pkgs; [
    cudatoolkit # For NVIDIA GPU support
    # opencl-info  # For OpenCL GPU info
    # clinfo       # OpenCL platform info
    nvtopPackages.full # GPU monitoring
    lshw # Hardware information
  ];

  # Enable CUDA support
  nixpkgs.config.cudaSupport = true;

  # Networking for API access
  networking.firewall = {
    allowedTCPPorts = [ 8080 ];
    interfaces.enp1s0.allowedTCPPorts = [ 8080 ];
  };

  # Increase file limits for AI workloads
  systemd.settings.Manager.DefaultLimitNOFILE = 65536;

  # Optimize for AI workloads
  boot.kernel.sysctl = {
    # Increase shared memory for large models
    "kernel.shmmax" = 68719476736; # 64GB
    "kernel.shmall" = 4294967296;
  };
}
