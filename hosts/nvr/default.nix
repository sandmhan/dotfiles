# NVR Host Configuration
# Frigate NVR deployed as a Proxmox VM
# Only sets deployment-specific options; all service logic lives in systemModules/frigate.nix
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
    ../../systemModules/frigate.nix
    ../../systemModules/sops.nix
  ];

  networking.hostName = systemSettings.hostname;

  # Enable Frigate with option-based camera configuration
  homelab.frigate = {
    enable = true;
    deploymentType = "vm";
    resourceProfile = "standard";

    # Camera definitions
    # Camera streams on IoT VLAN (10.0.10.0/24), Frigate VM on services VLAN (20)
    cameras = {
      fishtank = {
        rtspUrl = "rtsp://192.168.50.174:554/ch0_0.h264";
        roles = [ "record" ];
        detect.enabled = false;
      };

      office = {
        rtspUrl = "rtsp://192.168.50.210:554/ch0_0.h264";
        roles = [
          "detect"
          "record"
        ];
        detect = {
          enabled = true;
          width = 1280;
          height = 720;
          fps = 5;
        };
      };
    };

    # MQTT integration for Home Assistant
    mqtt = {
      enabled = true;
      host = "localhost"; # Update when Home Assistant MQTT broker is deployed
      port = 1883;
    };

    # CPU detection by default; switch to http when AI server is available
    detector = {
      type = "cpu";
      # httpUrl = "http://ai-server.homelab.local:5000/v1/vision/detection";
    };

    # Recording configuration
    recording = {
      enabled = true;
      retainDays = 7;
      retainMode = "all";
      eventsRetainDays = 10;
    };

    # Storage — default /var/lib/frigate; enable NFS when NAS is ready
    storage.path = "/var/lib/frigate";

    # NFS mount placeholder — enable when NAS is deployed
    nfs = {
      enable = false;
      # server = "nas.homelab.local";
      # path = "/export/frigate";
      # mountPoint = "/mnt/nas-frigate";
    };

    # SOPS secrets for camera RTSP URLs
    sops.enableCameraSecrets = true;
  };
}
