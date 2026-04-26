# Home Assistant Module
# Provides smart home automation with MQTT, PostgreSQL recorder, and nginx reverse proxy
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  servicePackages = import ./packages.nix { inherit pkgs lib; };
  cfg = config.homelab.homeassistant;
in
{
  options.homelab.homeassistant = {
    enable = mkEnableOption "Homelab Home Assistant smart home automation";

    deploymentType = mkOption {
      type = types.enum [
        "vm"
        "container"
      ];
      default = "vm";
      description = "Deployment type - affects resource allocation, USB support, and feature set";
    };

    resourceProfile = mkOption {
      type = types.enum [
        "minimal"
        "standard"
        "high"
      ];
      default = "standard";
      description = "Resource profile for automatic configuration optimization";
    };

    domain = mkOption {
      type = types.str;
      default = "homeassistant.homelab.local";
      description = "Domain name for Home Assistant web interface";
    };

    httpPort = mkOption {
      type = types.port;
      default = 8123;
      description = "Home Assistant HTTP port";
    };

    # MQTT broker configuration
    mqtt = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Mosquitto MQTT broker for IoT device communication";
      };

      port = mkOption {
        type = types.port;
        default = 1883;
        description = "MQTT broker TCP port";
      };

      websocketPort = mkOption {
        type = types.port;
        default = 1884;
        description = "MQTT broker WebSocket port for browser-based clients";
      };
    };

    # PostgreSQL recorder backend
    postgres = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable PostgreSQL backend for Home Assistant recorder (replaces default SQLite)";
      };
    };

    # Nginx reverse proxy
    reverseProxy = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable nginx reverse proxy with WebSocket support for Home Assistant";
      };
    };

    # USB device passthrough (Zigbee/Z-Wave dongles)
    usb = {
      enable = mkOption {
        type = types.bool;
        default = cfg.deploymentType == "vm";
        description = ''
          Enable USB device passthrough for Zigbee/Z-Wave dongles.
          Only practical for VM deployments (requires Proxmox USB passthrough via qm set --usb).
          LXC containers cannot use USB passthrough directly.
        '';
      };

      zigbeeDevice = mkOption {
        type = types.str;
        default = "/dev/ttyUSB0";
        description = ''
          PLACEHOLDER - Path to Zigbee coordinator USB device.
          Update this with the actual device path after plugging in your Zigbee dongle.
          Use `ls /dev/serial/by-id/` on the Proxmox host to find the correct device.
          Common dongles: SONOFF Zigbee 3.0 USB Dongle Plus, ConBee II
        '';
      };

      zwaveDevice = mkOption {
        type = types.str;
        default = "/dev/ttyUSB1";
        description = ''
          PLACEHOLDER - Path to Z-Wave controller USB device.
          Update this with the actual device path after plugging in your Z-Wave stick.
          Use `ls /dev/serial/by-id/` on the Proxmox host to find the correct device.
          Common dongles: Aeotec Z-Stick Gen5+, Zooz ZST10
        '';
      };
    };

    # Frigate NVR integration
    frigate = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Frigate NVR integration for camera feeds and object detection";
      };

      url = mkOption {
        type = types.str;
        default = "http://nvr.homelab.local:5000";
        description = "Frigate server URL for API integration";
      };
    };

    # Prometheus monitoring integration
    monitoring = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Prometheus metrics exporter for Home Assistant";
      };
    };
  };

  config = mkMerge [
    # Core Home Assistant configuration
    (mkIf cfg.enable {
      services.home-assistant = {
        enable = true;
        openFirewall = true;

        # Extra components to install for integrations
        extraComponents = [
          "default_config"
          "esphome"
          "met" # Weather
          "radio_browser"
        ]
        ++ optionals cfg.mqtt.enable [
          "mqtt"
        ]
        ++ optionals cfg.frigate.enable [
          "frigate"
        ]
        ++ optionals cfg.monitoring.enable [
          "prometheus"
        ];

        config = {
          # Core configuration
          homeassistant = {
            name = "Homelab";
            unit_system = "us_customary";
            time_zone = "America/New_York";
            currency = "USD";
          };

          # HTTP configuration with reverse proxy support
          http = {
            server_port = cfg.httpPort;
            use_x_forwarded_for = cfg.reverseProxy.enable;
            trusted_proxies = mkIf cfg.reverseProxy.enable [
              "127.0.0.1"
              "::1"
            ];
          };

          # Recorder configuration - use PostgreSQL when enabled
          recorder = mkIf cfg.postgres.enable {
            db_url = "postgresql://@/hass";
            purge_keep_days =
              if cfg.resourceProfile == "minimal" then
                5
              else if cfg.resourceProfile == "high" then
                30
              else
                10;
          };

          # MQTT integration
          mqtt = mkIf cfg.mqtt.enable { };

          # Prometheus metrics endpoint
          prometheus = mkIf cfg.monitoring.enable { };

          # Default automations and scenes (empty lists for user to populate)
          automation = [ ];
          scene = [ ];
          script = [ ];
        };
      };

      # Fix hass user: NixOS module sets isNormalUser with low UID, causing assertion failure
      users.users.hass = {
        isNormalUser = lib.mkForce false;
        isSystemUser = true;
        group = "hass";
      };
      users.groups.hass = { };

      # Firewall rules for Home Assistant
      networking.firewall.allowedTCPPorts = [ cfg.httpPort ];

      # Install Home Assistant related packages
      environment.systemPackages = [
        pkgs.mosquitto
      ]
      ++ (optionals (cfg.deploymentType == "vm") [ pkgs.usbutils ])
      ++ servicePackages.base;

      # Health check service for Home Assistant
      systemd.services.homeassistant-health-check = {
        description = "Home Assistant Health Check";
        wantedBy = [ "multi-user.target" ];
        after = [ "home-assistant.service" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "homeassistant-health-check" ''
            # Wait for Home Assistant to initialize (it can take a while on first boot)
            sleep 60

            # Check Home Assistant is responding
            if ${pkgs.curl}/bin/curl -f http://localhost:${toString cfg.httpPort}/api/ >/dev/null 2>&1; then
              echo "Home Assistant is ready"
            else
              echo "Warning: Home Assistant not responding on port ${toString cfg.httpPort}"
            fi

            ${optionalString cfg.mqtt.enable ''
              # Check MQTT broker is responding
              if ${pkgs.mosquitto}/bin/mosquitto_sub -h localhost -p ${toString cfg.mqtt.port} -t '$SYS/broker/version' -C 1 -W 5 2>/dev/null; then
                echo "MQTT broker is ready"
              else
                echo "Warning: MQTT broker not responding on port ${toString cfg.mqtt.port}"
              fi
            ''}

            ${optionalString cfg.postgres.enable ''
              # Check PostgreSQL is accepting connections
              if ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql -c "SELECT 1;" hass >/dev/null 2>&1; then
                echo "PostgreSQL (hass database) is ready"
              else
                echo "Warning: PostgreSQL not responding for hass database"
              fi
            ''}
          '';
        };

        startAt = "hourly";
      };

      # Systemd resource limits based on deployment type
      systemd.services.home-assistant = {
        serviceConfig = mkMerge [
          (mkIf (cfg.deploymentType == "container") {
            MemoryMax = "512M";
            CPUQuota = "100%";
          })
          (mkIf (cfg.deploymentType == "vm" && cfg.resourceProfile == "minimal") {
            MemoryMax = "1G";
            CPUQuota = "150%";
          })
          (mkIf (cfg.deploymentType == "vm" && cfg.resourceProfile == "standard") {
            MemoryMax = "2G";
            CPUQuota = "200%";
          })
          (mkIf (cfg.deploymentType == "vm" && cfg.resourceProfile == "high") {
            MemoryMax = "4G";
          })
        ];
      };
    })

    # MQTT Broker (Mosquitto) Configuration
    (mkIf (cfg.enable && cfg.mqtt.enable) {
      services.mosquitto = {
        enable = true;

        listeners = [
          {
            # Standard MQTT listener
            port = cfg.mqtt.port;
            settings = {
              allow_anonymous = true; # Homelab-only; secure with ACLs for production
            };
            acl = [ "topic readwrite #" ];
          }
          {
            # WebSocket listener for browser-based MQTT clients
            port = cfg.mqtt.websocketPort;
            settings = {
              protocol = "websockets";
              allow_anonymous = true;
            };
            acl = [ "topic readwrite #" ];
          }
        ];
      };

      # Firewall rules for MQTT
      networking.firewall.allowedTCPPorts = [
        cfg.mqtt.port
        cfg.mqtt.websocketPort
      ];

      # IoT VLAN firewall rules for MQTT broker access
      # The IoT VLAN (10.0.10.0/24) needs to reach the MQTT broker
      # so that Zigbee2MQTT, ESPHome, and other IoT devices can publish/subscribe
      # NOTE: Inter-VLAN routing must be configured on the Protectli router
      # to allow traffic from IoT VLAN to the services VLAN where HA runs
      networking.firewall.extraCommands = ''
        # Allow IoT VLAN devices to reach MQTT broker
        iptables -A INPUT -s 10.0.10.0/24 -p tcp --dport ${toString cfg.mqtt.port} -j ACCEPT
        iptables -A INPUT -s 10.0.10.0/24 -p tcp --dport ${toString cfg.mqtt.websocketPort} -j ACCEPT

        # Allow Home Assistant to reach IoT VLAN devices (for discovery and control)
        iptables -A OUTPUT -d 10.0.10.0/24 -j ACCEPT

        # Allow management VLAN access to MQTT for debugging
        iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport ${toString cfg.mqtt.port} -j ACCEPT

        # Allow services VLAN access to Home Assistant and MQTT
        iptables -A INPUT -s 10.0.20.0/24 -p tcp --dport ${toString cfg.httpPort} -j ACCEPT
        iptables -A INPUT -s 10.0.20.0/24 -p tcp --dport ${toString cfg.mqtt.port} -j ACCEPT
      '';
    })

    # PostgreSQL Recorder Backend
    (mkIf (cfg.enable && cfg.postgres.enable) {
      services.postgresql = {
        enable = true;
        ensureDatabases = [ "hass" ];
        ensureUsers = [
          {
            name = "hass";
            ensureDBOwnership = true;
          }
        ];

        # PostgreSQL tuning based on resource profile
        settings = mkMerge [
          {
            # Base settings for all profiles
            log_connections = true;
            log_disconnections = true;
          }
          (mkIf (cfg.resourceProfile == "minimal") {
            shared_buffers = "64MB";
            work_mem = "4MB";
            maintenance_work_mem = "32MB";
            effective_cache_size = "128MB";
          })
          (mkIf (cfg.resourceProfile == "standard") {
            shared_buffers = "256MB";
            work_mem = "8MB";
            maintenance_work_mem = "64MB";
            effective_cache_size = "512MB";
          })
          (mkIf (cfg.resourceProfile == "high") {
            shared_buffers = "512MB";
            work_mem = "16MB";
            maintenance_work_mem = "128MB";
            effective_cache_size = "1GB";
          })
        ];
      };

      # Ensure hass user can connect via local socket (peer authentication)
      services.postgresql.authentication = ''
        local hass hass peer map=hass
      '';

      services.postgresql.identMap = ''
        hass hass hass
      '';

      # Firewall: PostgreSQL should only be accessible locally
      # No external port needed - HA connects via unix socket
    })

    # Nginx Reverse Proxy with WebSocket Support
    (mkIf (cfg.enable && cfg.reverseProxy.enable) {
      services.nginx = {
        enable = true;

        # Recommended nginx settings for Home Assistant
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;

        virtualHosts.${cfg.domain} = {
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
          ];

          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString cfg.httpPort}";
            proxyWebsockets = true; # Required for Home Assistant frontend
            extraConfig = ''
              proxy_buffering off;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
            '';
          };

          # WebSocket endpoint for Home Assistant
          locations."/api/websocket" = {
            proxyPass = "http://127.0.0.1:${toString cfg.httpPort}/api/websocket";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_buffering off;
              proxy_read_timeout 86400;
            '';
          };
        };
      };

      # Open HTTP port for reverse proxy
      networking.firewall.allowedTCPPorts = [ 80 ];
    })

    # USB Device Passthrough Configuration
    (mkIf (cfg.enable && cfg.usb.enable) {
      # PLACEHOLDER: USB passthrough requires Proxmox-level configuration
      # On the Proxmox host, run:
      #   qm set <vmid> --usb0 host=<zigbee-vendor-id>:<product-id>
      #   qm set <vmid> --usb1 host=<zwave-vendor-id>:<product-id>
      #
      # Find device IDs with: lsusb | grep -i "zigbee\|zwave\|silicon labs\|aeotec"
      #
      # Common Zigbee dongle IDs:
      #   SONOFF Zigbee 3.0 USB Dongle Plus: 10c4:ea60 (Silicon Labs CP2102)
      #   ConBee II: 1cf1:0030 (dresden elektronik)
      #
      # Common Z-Wave dongle IDs:
      #   Aeotec Z-Stick Gen5+: 0658:0200
      #   Zooz ZST10: 0658:0200

      # udev rules for consistent device naming
      # Uncomment and update with your actual device serial numbers
      # services.udev.extraRules = ''
      #   # PLACEHOLDER: Zigbee dongle - update ATTRS{serial} with actual serial
      #   SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", \
      #     SYMLINK+="zigbee", MODE="0660", GROUP="dialout"
      #
      #   # PLACEHOLDER: Z-Wave stick - update ATTRS{serial} with actual serial
      #   SUBSYSTEM=="tty", ATTRS{idVendor}=="0658", ATTRS{idProduct}=="0200", \
      #     SYMLINK+="zwave", MODE="0660", GROUP="dialout"
      # '';

      # Add hass user to dialout group for serial device access
      users.users.hass = {
        extraGroups = [ "dialout" ];
      };
    })

    # Prometheus Monitoring Integration
    (mkIf (cfg.enable && cfg.monitoring.enable) {
      # Home Assistant exposes metrics at /api/prometheus
      # The monitoring module can scrape this endpoint
      # Add this target to the monitoring module's staticTargets:
      #   "homelab-services" = [ "10.0.20.103:8123" ];
      #
      # Prometheus scrape config for Home Assistant:
      #   job_name = "homeassistant"
      #   metrics_path = "/api/prometheus"
      #   bearer_token = "<long-lived-access-token>"  # Generate in HA UI

      # Node exporter for system-level metrics
      services.prometheus.exporters.node = {
        enable = true;
        port = 9100;
        enabledCollectors = [
          "systemd"
          "processes"
          "tcpstat"
          "network_route"
        ]
        ++ optionals (cfg.deploymentType == "vm") [
          "interrupts"
          "logind"
          "meminfo_numa"
          "mountstats"
        ];
      };

      networking.firewall.allowedTCPPorts = [ 9100 ];
    })

    # SOPS Secrets Integration
    (mkIf cfg.enable {
      # SOPS secrets for Home Assistant
      # These will be populated from secrets/homeassistant/secrets.yaml
      sops.secrets = {
        "homeassistant/ha-secrets" = {
          mode = "0600";
          owner = "hass";
          group = "hass";
        };
        "homeassistant/mqtt-password" = mkIf cfg.mqtt.enable {
          mode = "0600";
          owner = "hass";
          group = "hass";
        };
        "homeassistant/postgres-password" = mkIf cfg.postgres.enable {
          mode = "0600";
          owner = "hass";
          group = "hass";
        };
      };
    })
  ];
}
