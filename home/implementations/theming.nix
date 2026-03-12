{
  lib,
  config,
  ...
}:
let
  cfg = config.myHome;
in
{
  # Always import theming modules, control with options
  imports = [
    ../../homeModules/stylix.nix
  ];

  # Font configuration
  fonts.fontconfig.enable = lib.mkIf cfg.features.enableFonts true;
}