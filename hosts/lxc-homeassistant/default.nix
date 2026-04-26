# Home Assistant LXC Container Configuration
# Resource-efficient alternative to VM deployment (no USB passthrough)
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
    ../lxc-base/default.nix
    ../../systemModules/homeassistant.nix
    ../../systemModules/sops.nix
  ];

  # System identification
  networking.hostName = systemSettings.hostname;

  # Enable Home Assistant optimized for container environment
  homelab.homeassistant = {
    enable = true;
    deploymentType = "container";
    resourceProfile = "minimal";

    # Domain for reverse proxy access
    domain = "homeassistant.homelab.local";

    # MQTT broker still available in container mode
    mqtt.enable = true;

    # PostgreSQL recorder for structured data storage
    postgres.enable = true;

    # Nginx reverse proxy
    reverseProxy.enable = true;

    # USB passthrough disabled - not practical in LXC containers
    # For Zigbee/Z-Wave, use a remote Zigbee2MQTT or ser2net bridge instead
    usb.enable = false;

    # Frigate integration (enable when NVR is deployed)
    # frigate = {
    #   enable = true;
    #   url = "http://10.0.20.105:5000";
    # };

    # Prometheus monitoring
    monitoring.enable = true;
  };

  # Override firewall to add Home Assistant ports
  networking.firewall.allowedTCPPorts = [
    22 # SSH (from lxc-base)
    80 # Nginx reverse proxy
    8123 # Home Assistant direct access
    1883 # MQTT broker
    1884 # MQTT WebSocket
    9100 # Node exporter (already in lxc-base)
  ];

  # Container-specific firewall rules
  networking.firewall.extraCommands = ''
    # Allow access from all homelab networks
    iptables -A INPUT -s 10.0.0.0/16 -p tcp -m multiport --dports 80,8123,1883,1884 -j ACCEPT

    # Allow IoT VLAN to reach MQTT broker
    iptables -A INPUT -s 10.0.10.0/24 -p tcp --dport 1883 -j ACCEPT
  '';

  # Container resource optimization
  boot.kernel.sysctl = {
    # Reduced limits for container (extend base sysctl)
    "fs.inotify.max_user_watches" = 131072;
    "fs.inotify.max_user_instances" = 128;
  };

}
