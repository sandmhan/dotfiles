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
  imports = [
    ../../homeModules/git.nix
  ];

  # Always enable home-manager
  programs.home-manager.enable = true;

  # Base nixpkgs configuration
  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystem = true;
    allowBroken = true;
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