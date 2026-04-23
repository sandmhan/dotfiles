{
  lib,
  ...
}:
{
  imports = [
    ../options.nix
    ../implementations/core.nix
    ../implementations/terminal.nix
    ../implementations/development.nix
    # Note: theming.nix excluded for headless environments
  ];

  # Headless terminal profile configuration - no GUI/theming dependencies
  myHome = {
    profiles = {
      enableDesktop = lib.mkDefault false;
      enableDevelopment = lib.mkDefault true;
      enableMedia = lib.mkDefault false;
      enableOffice = lib.mkDefault false;
      enableSocial = lib.mkDefault false;
      enableGaming = lib.mkDefault false;
      enableVirtualization = lib.mkDefault false;
    };

    features = {
      # Terminal features
      enableAdvancedShell = lib.mkDefault true;
      enableGitExtensions = lib.mkDefault true;
      enableTerminalUtils = lib.mkDefault true;

      # Development features
      enableClaudeCode = lib.mkDefault true;
      enableNixvim = lib.mkDefault true;
      enableContainerTools = lib.mkDefault false;

      # System features - no theming/fonts for headless
      enableFonts = lib.mkDefault false;
      enableTheming = lib.mkDefault false;
      enableSecurity = lib.mkDefault false;

      # Desktop features (all disabled for headless)
      enableWindowManager = lib.mkDefault false;
      enableDisplayManager = lib.mkDefault false;
      enableAudioTools = lib.mkDefault false;
      enableBluetoothTools = lib.mkDefault false;
      enableNetworkTools = lib.mkDefault false;
    };

    platform = {
      isHeadless = lib.mkDefault true;
      isWSL = lib.mkDefault false;
    };

    user = {
      enableKeyboardCustomization = lib.mkDefault true;
      enableDotfileSymlinks = lib.mkDefault false;
    };
  };
}