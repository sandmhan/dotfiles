{
  lib,
  pkgs,
  config,
  userSettings,
  ...
}:
let
  cfg = config.myHome;
in
{
  # Stylix theming
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${userSettings.theme}.yaml";
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.blex-mono;
        name = "BlexMono Nerd Font";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
  };

  # Font configuration
  fonts.fontconfig.enable = lib.mkIf cfg.features.enableFonts true;
}
