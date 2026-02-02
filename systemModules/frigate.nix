{
  pkgs,
  lib,
  ...
}:
{
  services.frigate = {
    enable = true;
    hostname = "localhost";

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
          roles = ["audio" "detect" "record"];
        }
      ];

    };
  };

}
