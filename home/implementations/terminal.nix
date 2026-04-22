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
  # Always import terminal modules, control with options
  imports = [
    ../../homeModules/terminal.nix
    ../../homeModules/nvf
  ];

  # Terminal utilities
  home.packages = with pkgs;
    lib.optionals cfg.features.enableTerminalUtils [
      ripgrep
      fd
      bat
      eza
      tree
      htop
      fastfetch
      unzip
    ] ++ lib.optionals cfg.features.enableGitExtensions [
      gitui
      gh
      lazygit
      delta
    ];

  # Advanced shell features
  programs = lib.mkIf cfg.features.enableAdvancedShell {
    starship.enable = true;
    direnv.enable = true;
    zoxide.enable = true;
  };

  # Keyboard layout (Linux only)
  home.keyboard = lib.mkIf (cfg.user.enableKeyboardCustomization && cfg.platform.enableLinuxSpecific) {
    layout = "us";
    options = [ "caps:escape" ];
  };

  # Set up home directory and username
  home = {
    username = userSettings.username;
    homeDirectory =
      if cfg.platform.enableLinuxSpecific then "/home/${userSettings.username}"
      else if cfg.platform.enableDarwinSpecific then "/Users/${userSettings.username}"
      else throw "Unsupported platform";

    stateVersion = "24.11";
  };
}
