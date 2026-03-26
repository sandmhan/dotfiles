{
  ...
}:
{
  imports = [
    ./terminal.nix
    ../implementations/moonlight.nix
    ../implementations/sunshine.nix
  ];

  # macOS-specific profile configuration
  myHome = {
    platform = {
      enableDarwinSpecific = true;
      enableLinuxSpecific = false;
      isHeadless = false;  # macOS has GUI but we focus on terminal
      isWSL = false;
    };

    features = {
      # macOS doesn't need some Linux-specific tools
      enableBluetoothTools = false;  # macOS handles this natively
      enableWindowManager = false;  # Use native macOS window management
      enableDisplayManager = false;  # Use macOS login
      enableAudioTools = false;  # Use native macOS audio controls
      enableNetworkTools = false;  # Use native macOS network settings

      # Remote desktop features
      enableSunshine = true;  # Game streaming server (cross-platform)
    };

    user = {
      enableKeyboardCustomization = false;  # Handle via macOS settings
    };
  };
}