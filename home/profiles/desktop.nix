{
  lib,
  ...
}:
{
  imports = [
    ./terminal.nix
    ../modules/desktop.nix
  ];

  # Desktop profile configuration - extends terminal profile
  myHome = {
    profiles = {
      enableDesktop = lib.mkDefault true;
      enableDevelopment = lib.mkDefault true;
      enableMedia = lib.mkDefault true;
      enableOffice = lib.mkDefault true;
      enableSocial = lib.mkDefault true;
      enableGaming = lib.mkDefault true;
      enableVirtualization = lib.mkDefault false;
    };

    features = {
      # Minimal disruption overrides - disable intrusive new features
      enableAdvancedShell = lib.mkDefault false;
      enableGitExtensions = lib.mkDefault false;

      # Desktop features
      enableWindowManager = lib.mkDefault true;
      enableDisplayManager = lib.mkDefault true;
      enableAudioTools = lib.mkDefault true;
      enableBluetoothTools = lib.mkDefault true;
      enableNetworkTools = lib.mkDefault true;
      enable3DPrinting = lib.mkDefault true;

      # Development features
      enableContainerTools = lib.mkDefault true;

      # Remote desktop features
      enableMoonlight = lib.mkDefault true;
      enableSunshine = lib.mkDefault false;

      # System features
      enableSecurity = lib.mkDefault true;
    };

    platform = {
      isHeadless = lib.mkDefault false;
      isWSL = lib.mkDefault false;
    };
  };
}
