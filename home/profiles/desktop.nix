{
  ...
}:
{
  imports = [
    ./terminal.nix
    ../modules/desktop.nix
  ];

  # Desktop profile — extends terminal profile.
  # Values here are plain (priority 100) so they override
  # terminal.nix's mkDefault (priority 1000).
  myHome = {
    profiles = {
      enableDesktop = true;
      enableDevelopment = true;
      enableMedia = true;
      enableOffice = true;
      enableSocial = true;
      enableGaming = true;
      enableVirtualization = false;
    };

    features = {
      # Override terminal defaults
      enableAdvancedShell = false;
      enableGitExtensions = false;

      # Desktop features
      enableWindowManager = true;
      enableDisplayManager = true;
      enableAudioTools = true;
      enableBluetoothTools = true;
      enableNetworkTools = true;
      enableScreenshotTools = true;
      enable3DPrinting = true;

      # Development features
      enableContainerTools = true;

      # Remote desktop features
      enableMoonlight = true;
      enableSunshine = false;

      # System features
      enableSecurity = true;
    };

    platform = {
      isHeadless = false;
      isWSL = false;
    };
  };
}
