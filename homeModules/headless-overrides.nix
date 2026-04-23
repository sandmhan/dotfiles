# Headless environment overrides - disable GUI/theming features
{
  lib,
  ...
}:
{
  # Disable theming features that require GUI services
  myHome.features.enableTheming = lib.mkForce false;
  myHome.features.enableFonts = lib.mkForce false;
}