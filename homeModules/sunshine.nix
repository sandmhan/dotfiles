{
  pkgs,
  lib,
  ...
}:
{
  # Sunshine server for game streaming
  home.packages = [
    pkgs.sunshine
  ];

  # Create service for Sunshine (Linux: systemd, macOS: launchd)
  systemd.user.services.sunshine = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "Sunshine Game Streaming Server";
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.sunshine}/bin/sunshine";
      Restart = "on-failure";
      RestartSec = "5s";
      # Sunshine needs access to display and input devices on Linux
      Environment = [
        "DISPLAY=:0"
      ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # macOS launchd service
  launchd.agents.sunshine = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.sunshine}/bin/sunshine" ];
      Label = "org.homebrewformulas.sunshine";
      RunAtLoad = true;
      KeepAlive = true;
    };
  };

  # Desktop entry for manual launch
  xdg.desktopEntries.sunshine = {
    name = "Sunshine";
    comment = "Host for remote access software";
    exec = "sunshine";
    icon = "sunshine";
    terminal = false;
    categories = [ "Network" "Utility" ];
  };

  # Create configuration directory with basic settings
  home.file.".config/sunshine/sunshine.conf".text = ''
    # Sunshine configuration
    # Web UI accessible at https://localhost:47990
    # Default username: admin
    # Generate password with: echo -n "your_password" | openssl dgst -sha256

    # Network settings
    address_family = both
    channels = 5

    # Video settings
    sw_preset = superfast
    adapter_name =
    output_name =

    # Audio settings
    audio_sink = auto

    # Input settings
    gamepad = auto

    # Security settings
    # Set this to a secure password hash
    # credentials_file =

    # Logging
    min_log_level = info
    log_colorized = true
  '';
}