{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.myHome;
in
{
  # Moonlight client for game streaming
  home.packages = lib.optionals cfg.features.enableMoonlight [
    pkgs.moonlight-qt
  ];

  # Desktop entry and configuration
  xdg.desktopEntries = lib.mkIf cfg.features.enableMoonlight {
    moonlight = {
      name = "Moonlight";
      comment = "Stream games from your PC";
      exec = "moonlight";
      icon = "moonlight";
      terminal = false;
      categories = [ "Game" "Network" ];
    };
  };
}