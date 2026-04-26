# Minimal networking for Proxmox VMs
{ config, lib, systemSettings, ... }:
{
  networking = {
    hostName = systemSettings.hostname;

    # Use systemd-networkd for reliable VM networking
    useNetworkd = true;

    # Simple DHCP configuration
    useDHCP = lib.mkDefault true;
  };

  # Minimal systemd-networkd config - DHCP on all interfaces
  systemd.network = {
    enable = true;
    networks."10-ethernet" = {
      matchConfig.Name = "en* eth*";
      networkConfig.DHCP = "yes";
    };
  };

  # DNS fallback
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
}