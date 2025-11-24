{
  lib,
  pkgs,
  userSettings,
  ...
}:
let
  username = userSettings.username;
  font = userSettings.font;
  configPath =
    if pkgs.stdenv.isLinux then
      "/home/${username}/dotfile/configs/"
    else
      "/Users/${username}/dotfile/configs/";
in
{
  # home-manager package
  programs.home-manager.enable = true;

  imports = [
    ./homeModules/browser.nix
    ./homeModules/terminal.nix
    ./homeModules/nvim.nix
    ./homeModules/stylix.nix
    ./homeModules/git.nix
    ./homeModules/wm.nix
    ./homeModules/login.nix
    ./homeModules/bluetooth.nix
    ./homeModules/rofi.nix
  ];

  home.keyboard = {
    layout = "us";
    options = [ "caps_toggle:escape" ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystem = true;
    allowBroken = true;
  };

  home = {
    # Define user packages here
    packages =
      with pkgs;
      [
        hello
        alacritty
        kitty
        nixfmt-rfc-style # styling nix files
        qmk
        nerd-fonts.blex-mono
        mpv
        typst # typesetter language compiler
        pdfpc # pdf as presentation viewer
        zathura # minimalist pdf viewer
        libreoffice
        legcord
        bitwarden-desktop
        bitwarden-cli
        openvpn
        qbittorrent
        xfce.thunar
      ]
      ++ (
        if pkgs.stdenv.isLinux then
          [
            parsec-bin
          ]
        else
          [
            # macOS only packages
          ]
      );

    # This needs to match the actual username logged into
    inherit username;
    homeDirectory = if pkgs.stdenv.isLinux then "/home/${username}" else "/Users/${username}";

    # Does not need to be changed
    # Don't change this after the first build.
    stateVersion = "24.11";
  };
}
