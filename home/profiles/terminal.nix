{
  lib,
  ...
}:
{
  imports = [
    ../options.nix
    ../modules/core.nix
    ../modules/terminal.nix
    ../modules/development.nix
    ../modules/theming.nix
  ];

  # Terminal profile configuration - use mkDefault for easy overrides
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
      enableCodex = lib.mkDefault true;
      enableNvfAiAvante = lib.mkDefault true;
      enableNixvim = lib.mkDefault true;
      enableContainerTools = lib.mkDefault false;

      # System features
      enableFonts = lib.mkDefault true;
      enableTheming = lib.mkDefault true;
      enableSecurity = lib.mkDefault false;

      # Desktop features (disabled for terminal profile)
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
