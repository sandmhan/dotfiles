{ lib, pkgs, userSettings, ...}:
let
  username = userSettings.username;
  configPath = "../configs/";
in
{
  # home-manager package
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userEmail = "austinsanders0105@gmail.com";
    userName = "sandmhan";
  };

  programs.tmux = {
    keyMode = "vi";
    mouse = true;
    shortcut = "a";

    extraConfig = builtins.readFile configPath + ".tmux.conf";
  };

  home = {
    # Define user packages here
    packages = with pkgs; [
      git
      hello
      alacritty
      kitty
      nixfmt-rfc-style #styling nix files
      tmux
    ];

    # This needs to match the actual username logged into
    inherit username;
    homeDirectory = "/home/${username}";

    # Does not need to be changed
    # Don't change this after the first build.
    stateVersion = "24.11";
  };
}
