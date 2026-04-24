{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./sops.nix ];

  # Override default sops file to use nvr-specific secrets
  sops.defaultSopsFile = lib.mkForce ../secrets/nvr/secrets.yaml;

  # Define camera secrets - these will be used when cameras require authentication.
  # The RTSP URLs in secrets/nvr/secrets.yaml should contain full URLs with credentials,
  # e.g.: rtsp://user:password@192.168.50.174:554/ch0_0.h264
  #
  # To use: replace the hardcoded paths below with values read from
  # config.sops.secrets."cameras/fishtank/rtsp_url".path at runtime.
  # Since services.frigate generates config at build time, switching to
  # authenticated cameras requires using virtualisation.oci-containers
  # with a sops.templates-generated config file mounted as /config/config.yml.
  sops.secrets = {
    "cameras/fishtank/rtsp_url" = {
      owner = "root";
      mode = "0400";
    };

    "cameras/office/rtsp_url" = {
      owner = "root";
      mode = "0400";
    };
  };

  networking.firewall.allowedTCPPorts = [ 5000 ];

  services.frigate = {
    enable = true;
    hostname = "0.0.0.0";
    bind_addr = "0.0.0.0";

    settings = {
      mqtt.enabled = true;

      record = {
        enabled = true;
        retain = {
          days = 7;
          mode = "all";
        };
      };

      cameras."fishtank".ffmpeg.inputs = [
        {
          path = "rtsp://192.168.50.174:554/ch0_0.h264";
          roles = [ "record" ];
        }
      ];

      cameras."office".ffmpeg.inputs = [
        {
          path = "rtsp://192.168.50.210:554/ch0_0.h264";
          roles = [ "detect" "record" ];
        }
      ];
    };
  };
}
