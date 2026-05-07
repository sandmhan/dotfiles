# Home Assistant VM Host Configuration
# Smart home automation with MQTT, PostgreSQL, and USB passthrough for Zigbee/Z-Wave
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
    ../../systemModules/homeassistant.nix
    ../../systemModules/sops.nix
  ];

  # System identification
  networking.hostName = systemSettings.hostname;

  # Enable Home Assistant with VM-optimized settings
  homelab.homeassistant = {
    enable = true;
    deploymentType = "vm";
    resourceProfile = "standard";

    # Domain for reverse proxy access
    domain = "homeassistant.homelab.local";

    # MQTT broker enabled by default for IoT device communication
    mqtt.enable = true;

    # PostgreSQL recorder for better performance over SQLite
    postgres.enable = true;

    # Nginx reverse proxy with WebSocket support
    reverseProxy.enable = true;

    # USB passthrough for Zigbee/Z-Wave dongles
    # PLACEHOLDER: Update device paths after connecting physical dongles
    # On Proxmox host, run:
    #   lsusb                          # Find vendor:product IDs
    #   qm set 103 --usb0 host=10c4:ea60  # Pass Zigbee dongle to VM
    #   qm set 103 --usb1 host=0658:0200  # Pass Z-Wave stick to VM
    usb = {
      enable = true;
      zigbeeDevice = "/dev/ttyUSB0"; # PLACEHOLDER - update with actual device path
      zwaveDevice = "/dev/ttyUSB1"; # PLACEHOLDER - update with actual device path
    };

    # Frigate integration (enable when NVR is deployed)
    # frigate = {
    #   enable = true;
    #   url = "http://10.0.0.TBD:5000"; # NVR IP — set after deployment
    # };

    # Prometheus monitoring integration
    monitoring.enable = true;
  };

  # Additional firewall rules for Home Assistant access
  networking.firewall = {
    allowedTCPPorts = [
      80 # Nginx reverse proxy
      8123 # Home Assistant direct access
      1883 # MQTT broker
      1884 # MQTT WebSocket
      9100 # Node exporter metrics
    ];

    # Allow access from homelab network
    # TODO: Add VLAN-specific rules once VLANs are deployed (services 10.0.20.0/24, IoT 10.0.10.0/24)
    extraCommands = ''
      # Allow Home Assistant access from homelab network
      iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 8123 -j ACCEPT
      iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 80 -j ACCEPT

      # Allow MQTT broker from homelab network (IoT devices will use 10.0.10.0/24 once VLANs exist)
      iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 1883 -j ACCEPT

      # Allow Prometheus scraping from homelab network
      iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 9100 -j ACCEPT
    '';
  };

  # Kernel tuning for IoT workloads
  # Home Assistant handles many concurrent connections from IoT devices
  boot.kernel.sysctl = {
    # Increase inotify limits for Home Assistant file watching
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 256;

    # Network tuning for many concurrent IoT device connections
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.core.netdev_max_backlog" = 5000;
    "net.core.somaxconn" = 4096;

    # TCP keepalive tuning for persistent IoT connections
    "net.ipv4.tcp_keepalive_time" = 60;
    "net.ipv4.tcp_keepalive_intvl" = 10;
    "net.ipv4.tcp_keepalive_probes" = 6;

    # Increase connection tracking for many IoT devices
    "net.netfilter.nf_conntrack_max" = 131072;
  };

  # VM resource recommendations (configure on Proxmox host):
  # qm set 103 --cores 2 --memory 4096
  # qm set 103 --balloon 2048  # Allow memory ballooning from 2GB to 4GB

}
