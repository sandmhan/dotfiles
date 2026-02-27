{ config, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_scsi" "ahci" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];  # kvm-intel or amd depending on your CPU
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/vda";
    fsType = "vfat";
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
}
