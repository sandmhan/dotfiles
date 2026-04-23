# LXC Container Networking Configuration
{ config, lib, systemSettings, ... }:
{
  networking = {
    hostName = systemSettings.hostname;

    # Use systemd-networkd for reliable container networking
    useNetworkd = true;
    useDHCP = lib.mkDefault true;

    # Disable NetworkManager in containers (not needed)
    networkmanager.enable = lib.mkForce false;
  };

  # Optimized systemd-networkd config for containers
  systemd.network = {
    enable = true;

    # Simple DHCP on all interfaces
    networks."10-container-ethernet" = {
      matchConfig.Name = "eth* veth*";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
      };
      dhcpV4Config = {
        UseDomains = true;
        UseRoutes = true;
      };
    };
  };

  # DNS configuration
  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNSSEC = false;
        FallbackDNS = [ "1.1.1.1" "8.8.8.8" ];
      };
    };
  };

  # Disable unnecessary network services
  services = {
    avahi.enable = lib.mkForce false;
    timesyncd.enable = lib.mkDefault true; # Keep time sync
  };
}