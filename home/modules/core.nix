{
  lib,
  pkgs,
  userSettings,
  ...
}:
{
  # Always enable home-manager
  programs.home-manager.enable = true;

  # Git configuration
  programs.git = {
    enable = true;
    signing.format = null;
    settings.user = {
      email = userSettings.email;
      name = userSettings.username;
    };
  };

  # Base nixpkgs configuration
  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystem = true;
  };

  # Core packages that are always installed
  home.packages = with pkgs; [
    hello
    nixfmt
  ];

  # Platform detection
  myHome.platform = {
    enableLinuxSpecific = pkgs.stdenv.isLinux;
    enableDarwinSpecific = pkgs.stdenv.isDarwin;
  };
}
