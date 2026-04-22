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
  # Always import desktop modules, control with options
  imports = [
    ../../homeModules/wm.nix
    ../../homeModules/rofi.nix
    ../../homeModules/login.nix
    ../../homeModules/bluetooth.nix
    ../../homeModules/browser.nix
    ./moonlight.nix
    ./sunshine.nix
  ];

  # Desktop packages
  home.packages =
    with pkgs;
    # GUI terminal emulators
    lib.optionals cfg.profiles.enableDesktop [
      alacritty
      kitty
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
      freecad
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
