{
  lib,
  config,
  ...
}:
let
  cfg = config.myHome;
in
{
  # Conditionally import theming modules only when theming is enabled
  imports = lib.optionals cfg.features.enableTheming [
    ../../homeModules/stylix.nix
  ];

  # Font configuration
  fonts.fontconfig.enable = lib.mkIf cfg.features.enableFonts true;
}