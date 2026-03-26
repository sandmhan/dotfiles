{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.myHome;

  # Pin bitwarden-desktop to stable version to avoid electron build issues
  # Use older nixpkgs with working electron/bitwarden (before electron 39 issues)
  oldNixpkgs = import (pkgs.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "nixos-24.05"; # Stable release before electron 39 issues
    sha256 = "OnSAY7XDSx7CtDoqNh8jwVwh4xNL/2HaJxGjryLWzX8=";
  }) { inherit (pkgs) system; };

  bitwarden-desktop-stable = oldNixpkgs.bitwarden-desktop;
in
{
  # Always import desktop modules, control with options
  imports = [
    ../../homeModules/wm.nix
    ../../homeModules/rofi.nix
    ../../homeModules/login.nix
    ../../homeModules/bluetooth.nix
    ../../homeModules/browser.nix
    ../../homeModules/3d_printing.nix
    ./moonlight.nix
    ./sunshine.nix
  ];

  # Desktop packages
  home.packages = with pkgs;
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
      bitwarden-desktop-stable  # Pinned version to avoid electron build issues
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