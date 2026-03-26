{
  pkgs,
  lib,
  ...
}:
{
  # Moonlight client for game streaming
  home.packages = [
    pkgs.moonlight-qt
  ];

  # Desktop entry and configuration
  xdg.desktopEntries.moonlight = {
    name = "Moonlight";
    comment = "Stream games from your PC";
    exec = "moonlight";
    icon = "moonlight";
    terminal = false;
    categories = [ "Game" "Network" ];
  };
}