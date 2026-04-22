{
  pkgs,
  lib,
  ...
}:
{
  # Enable incoming requests to frigate web server
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
          roles = [
            "detect"
            "record"
          ];
        }
      ];

    };
  };

}
