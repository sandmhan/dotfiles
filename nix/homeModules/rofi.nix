{
  pkgs,
  lib,
  userSettings,
  ...
}:
{

  home = {
    packages = with pkgs; [
      rofi
    ];
  };

  programs.rofi = {

    enable = true;

    font = userSettings.font;

  };

}
