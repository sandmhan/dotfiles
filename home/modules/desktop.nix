{
  lib,
  pkgs,
  freecadPkgs ? pkgs,
  config,
  ...
}:
let
  cfg = config.myHome;
in
{
  imports = [
    ./wm.nix
    ./moonlight.nix
    ./sunshine.nix
    ./screenshot.nix
    ./notifications.nix
  ];

  # Rofi application launcher
  programs.rofi = lib.mkIf cfg.features.enableWindowManager {
    enable = true;
    plugins = [ ];
  };

  # Swaylock screen locker
  programs.swaylock = lib.mkIf cfg.features.enableWindowManager {
    enable = true;
    settings = {
      color = lib.mkForce "808080";
      font-size = 24;
      indicator-idle-visible = false;
      indicator-radius = 100;
      line-color = "ffffff";
      show-failed-attempts = true;
    };
  };

  # Qutebrowser
  programs.qutebrowser = lib.mkIf cfg.profiles.enableDesktop {
    enable = true;
    searchEngines = {
      w = "https://en.wikipedia.org/wiki/Special:Search?search={}&amp;go=Go&amp;ns0=1";
      g = "https://www.google.com/search?hl=en&amp;q={}";
      hm = "https://home-manager-options.extranix.com/?query={}&release=master";
      y = "https://www.youtube.com/results?search_query={}";
      np = "https://search.nixos.org/packages?channel=unstable&query={}";
      no = "https://search.nixos.org/options?channel=unstable&query={}";
    };
    settings = {
      tabs = {
        position = "left";
        max_width = 1;
        show = "switching";
      };
      scrolling.smooth = true;
      colors.webpage.darkmode.enabled = true;
      downloads.remove_finished = 5000;
    };
    extraConfig = ''
      c.content.javascript.log_message.excludes = {
        'userscript:_qute_stylesheet' : ['*Refused to apply inline style because it violates the following Content Security Policy directive: *'],
        'userscript:_qute_js' : ['*TrustedHTML*']
      }
    '';
  };

  # Bitwarden Desktop currently depends on Electron 39 in the pinned nixpkgs.
  nixpkgs.config.permittedInsecurePackages = lib.mkIf cfg.features.enableSecurity [
    "electron-39.8.10"
  ];

  # Desktop packages
  home.packages =
    with pkgs;
    # GUI terminal emulators
    lib.optionals cfg.profiles.enableDesktop [
      alacritty
      kitty
    ]
    # Rofi and power menu
    ++ lib.optionals cfg.features.enableWindowManager [
      rofi
      rofi-power-menu
      swaylock
    ]
    # Bluetooth
    ++ lib.optionals cfg.features.enableBluetoothTools [
      bluetui
    ]
    # Media applications
    ++ lib.optionals cfg.profiles.enableMedia [
      mpv
      pdfpc
      zathura
    ]
    # Office applications
    ++ lib.optionals cfg.profiles.enableOffice [
      libreoffice
      typst
    ]
    # Social applications
    ++ lib.optionals cfg.profiles.enableSocial [
      legcord
      element-desktop
    ]
    # Security applications
    ++ lib.optionals cfg.features.enableSecurity [
      bitwarden-desktop
      bitwarden-cli
      openvpn
    ]
    # Audio tools
    ++ lib.optionals cfg.features.enableAudioTools [
      pulsemixer
      pavucontrol
    ]
    # File management
    ++ lib.optionals cfg.profiles.enableDesktop [
      thunar
      bashmount
    ]
    # Entertainment/Gaming
    ++ lib.optionals cfg.profiles.enableGaming [
      qbittorrent
    ]
    # 3D printing tools
    ++ lib.optionals cfg.features.enable3DPrinting [
      orca-slicer
      freecadPkgs.freecad
      openscad
      qidi-studio
    ]
    # Linux-specific desktop packages
    ++ lib.optionals (cfg.platform.enableLinuxSpecific && cfg.profiles.enableDesktop) [
      parsec-bin
      qmk
    ]
    # Fonts
    ++ lib.optionals cfg.features.enableFonts [
      nerd-fonts.blex-mono
    ];

}
