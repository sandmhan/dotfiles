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
      rofi-power-menu
    ];
  };

  programs.rofi = {

    enable = true;
    plugins = [];

  };

}
