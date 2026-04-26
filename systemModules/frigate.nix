# Frigate NVR Module
# Option-based configuration for Frigate network video recording
# Translates declarative camera options into services.frigate.settings
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  servicePackages = import ./packages.nix { inherit pkgs lib; };
  cfg = config.homelab.frigate;

  # Per-camera option type
  cameraOpts =
    { name, ... }:
    {
      options = {
        rtspUrl = mkOption {
          type = types.str;
          description = "RTSP URL for the camera stream (may contain credentials)";
          example = "rtsp://192.168.50.174:554/ch0_0.h264";
        };

        roles = mkOption {
          type = types.listOf (
            types.enum [
              "detect"
              "record"
            ]
          );
          default = [ "record" ];
          description = "Roles for this camera stream (detect, record)";
        };

        detect = {
          enabled = mkOption {
            type = types.bool;
            default = false;
            description = "Enable object detection on this camera";
          };

          width = mkOption {
            type = types.int;
            default = 1280;
            description = "Detection stream width in pixels";
          };

          height = mkOption {
            type = types.int;
            default = 720;
            description = "Detection stream height in pixels";
          };

          fps = mkOption {
            type = types.int;
            default = 5;
            description = "Detection frames per second";
          };
        };

        zones = mkOption {
          type = types.attrsOf (
            types.submodule {
              options = {
                coordinates = mkOption {
                  type = types.str;
                  description = "Comma-separated polygon coordinates for the zone";
                  example = "100,720,500,720,500,400,100,400";
                };

                objects = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                  description = "Object types to detect in this zone";
                  example = [
                    "person"
                    "car"
                  ];
                };
              };
            }
          );
          default = { };
          description = "Detection zones for this camera";
        };

        motionMask = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Motion mask coordinates to ignore areas with frequent motion";
          example = [ "0,0,1280,100" ];
        };
      };
    };

  # Build frigate camera config from our options
  mkCameraConfig = name: cam: {
    ffmpeg.inputs = [
      {
        path = cam.rtspUrl;
        roles = cam.roles;
      }
    ];

    detect = mkIf cam.detect.enabled {
      enabled = true;
      width = cam.detect.width;
      height = cam.detect.height;
      fps = cam.detect.fps;
    };

    zones = mapAttrs (
      zoneName: zone:
      {
        coordinates = zone.coordinates;
      }
      // optionalAttrs (zone.objects != [ ]) {
        objects = zone.objects;
      }
    ) cam.zones;

    motion = mkIf (cam.motionMask != [ ]) {
      mask = cam.motionMask;
    };
  };

  # Build detector config based on type
  detectorConfig =
    if cfg.detector.type == "cpu" then
      {
        cpu = {
          type = "cpu";
          num_threads = cfg.detector.cpuThreads;
        };
      }
    else if cfg.detector.type == "http" then
      {
        http = {
          type = "deepstack";
          api_url = cfg.detector.httpUrl;
        };
      }
    else
      {
        cpu = {
          type = "cpu";
        };
      };
in
{
  options.homelab.frigate = {
    enable = mkEnableOption "Frigate NVR (Network Video Recorder)";

    deploymentType = mkOption {
      type = types.enum [
        "vm"
        "container"
      ];
      default = "vm";
      description = "Deployment type - affects resource allocation";
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

    cameras = mkOption {
      type = types.attrsOf (types.submodule cameraOpts);
      default = { };
      description = "Camera definitions for Frigate";
    };

    mqtt = {
      enabled = mkOption {
        type = types.bool;
        default = true;
        description = "Enable MQTT integration for Home Assistant";
      };

      host = mkOption {
        type = types.str;
        default = "localhost";
        description = "MQTT broker hostname or IP";
      };

      port = mkOption {
        type = types.port;
        default = 1883;
        description = "MQTT broker port";
      };

      topicPrefix = mkOption {
        type = types.str;
        default = "frigate";
        description = "MQTT topic prefix";
      };
    };

    detector = {
      type = mkOption {
        type = types.enum [
          "cpu"
          "http"
        ];
        default = "cpu";
        description = "Detector type: cpu (default) or http (for remote AI server)";
      };

      httpUrl = mkOption {
        type = types.str;
        default = "";
        description = "URL for HTTP-based detector API (e.g., local AI server)";
        example = "http://ai-server.homelab.local:5000/v1/vision/detection";
      };

      cpuThreads = mkOption {
        type = types.int;
        default =
          if cfg.resourceProfile == "minimal" then
            2
          else if cfg.resourceProfile == "high" then
            4
          else
            3;
        description = "Number of CPU threads for detection";
      };
    };

    recording = {
      enabled = mkOption {
        type = types.bool;
        default = true;
        description = "Enable recording";
      };

      retainDays = mkOption {
        type = types.int;
        default =
          if cfg.resourceProfile == "minimal" then
            3
          else if cfg.resourceProfile == "high" then
            14
          else
            7;
        description = "Number of days to retain recordings";
      };

      retainMode = mkOption {
        type = types.enum [
          "all"
          "motion"
          "active_objects"
        ];
        default = "all";
        description = "Recording retain mode";
      };

      eventsRetainDays = mkOption {
        type = types.int;
        default = 10;
        description = "Number of days to retain event recordings";
      };
    };

    storage = {
      path = mkOption {
        type = types.str;
        default = "/var/lib/frigate";
        description = "Base storage path for Frigate recordings and database";
      };
    };

    nfs = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Mount NFS share for recording storage";
      };

      server = mkOption {
        type = types.str;
        default = "";
        description = "NFS server hostname or IP";
        example = "nas.homelab.local";
      };

      path = mkOption {
        type = types.str;
        default = "/export/frigate";
        description = "NFS export path on the server";
      };

      mountPoint = mkOption {
        type = types.str;
        default = "/mnt/nas-frigate";
        description = "Local mount point for NFS share";
      };
    };

    sops = {
      enableCameraSecrets = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SOPS secrets for camera RTSP URLs";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Core Frigate service configuration
    {
      services.frigate = {
        enable = true;
        hostname = "0.0.0.0";

        settings = {
          mqtt = mkIf cfg.mqtt.enabled {
            enabled = true;
            host = cfg.mqtt.host;
            port = cfg.mqtt.port;
            topic_prefix = cfg.mqtt.topicPrefix;
          };

          detectors = detectorConfig;

          record = mkIf cfg.recording.enabled {
            enabled = true;
            retain = {
              days = cfg.recording.retainDays;
              mode = cfg.recording.retainMode;
            };
            events.retain = {
              default = cfg.recording.eventsRetainDays;
              mode = "active_objects";
            };
          };

          cameras = mapAttrs mkCameraConfig cfg.cameras;
        };
      };

      # Firewall rules
      # 5000: Frigate web UI
      # 1935: RTSP relay
      # 8554: go2rtc WebRTC/RTSP
      networking.firewall.allowedTCPPorts = [
        5000
        1935
        8554
      ];

      # Base packages
      environment.systemPackages = servicePackages.base;
    }

    # SOPS secrets for camera RTSP URLs
    (mkIf cfg.sops.enableCameraSecrets {
      sops.secrets = mapAttrs' (
        name: _cam:
        nameValuePair "cameras/${name}/rtsp_url" {
          owner = "root";
          mode = "0400";
        }
      ) cfg.cameras;
    })

    # NFS mount for recording storage
    (mkIf cfg.nfs.enable {
      fileSystems.${cfg.nfs.mountPoint} = {
        device = "${cfg.nfs.server}:${cfg.nfs.path}";
        fsType = "nfs";
        options = [
          "nfsvers=4"
          "x-systemd.automount"
          "x-systemd.idle-timeout=600"
          "noatime"
        ];
      };
    })

    # Node exporter for monitoring
    {
      services.prometheus.exporters.node = {
        enable = true;
        port = 9100;
        enabledCollectors = [
          "systemd"
          "processes"
        ];
      };

      networking.firewall.allowedTCPPorts = [ 9100 ];
    }

    # Health check service
    {
      systemd.services.frigate-health-check = {
        description = "Frigate NVR health check";
        after = [ "frigate.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.curl}/bin/curl -sf http://localhost:5000/api/version || exit 1";
        };
      };

      systemd.timers.frigate-health-check = {
        description = "Periodic Frigate NVR health check";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*:0/5"; # Every 5 minutes
          Persistent = true;
        };
      };
    }
  ]);
}
