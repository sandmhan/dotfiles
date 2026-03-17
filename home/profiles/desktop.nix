{
  ...
}:
{
  imports = [
    ./terminal.nix
    ../implementations/desktop.nix
  ];

  # Desktop profile configuration - extends terminal profile
  myHome = {
    profiles = {
      enableDesktop = true;
      enableDevelopment = true;  # Keep from terminal profile
      enableMedia = true;
      enableOffice = true;
      enableSocial = true;
      enableGaming = true;
      enableVirtualization = false;  # Can be enabled per-user
    };

    features = {
      # Minimal disruption overrides - disable intrusive new features
      enableAdvancedShell = false;     # Disable starship prompt, direnv, zoxide
      enableGitExtensions = false;     # Disable gitui, gh, lazygit, delta
      # enableTerminalUtils = true;    # Keep useful tools (ripgrep, fd, bat, eza) - inherited

      # Desktop features
      enableWindowManager = true;
      enableDisplayManager = true;
      enableAudioTools = true;
      enableBluetoothTools = true;
      enableNetworkTools = true;

      # Development features (keep from parent)
      # enableClaudeCode = true; (inherited)
      # enableNixvim = true; (inherited)
      enableContainerTools = true;  # More useful on desktop

      # System features
      enableSecurity = true;  # Bitwarden, VPN, etc. useful on desktop
    };

    platform = {
      isHeadless = false;  # Override terminal profile
      isWSL = false;
    };
  };
}