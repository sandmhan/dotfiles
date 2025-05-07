{
  lib,
  pkgs,
  userSettings,
  ...
}:
let
  username = userSettings.username;
  configPath = "/home/${username}/dotfile/configs/";
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
    enable = true;
    keyMode = "vi";
    mouse = true;
    shortcut = "a";

    extraConfig =
    ''
	set -g mouse on
	set -g history-limit 100000
	unbind C-b
	set -g prefix C-a
	bind C-a send-prefix

	bind -n C-h select-pane -L
	bind -n C-j select-pane -D
	bind -n C-k select-pane -U
	bind -n C-l select-pane -R
    '';

    # extraConfig = builtins.readFile "github:sandmhan/dotfiles/nix/config/.tmux.conf";
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      ".." = "cd ..";
    };

		bashrcExtra = "set -o vi";

  };

  programs.qutebrowser = {
    enable = true;
    # quickmarks = {
    # 	nixpkgs = "https://github.com/NixOS/nixpkgs";
    # 	home-manager = "https://github.com/nix-community/home-manager";
    # };
  };

  home = {
    # Define user packages here
    packages = with pkgs; [
      hello
      alacritty
      kitty
      nixfmt-rfc-style # styling nix files
			qmk
    ];

    # This needs to match the actual username logged into
    inherit username;
    homeDirectory = "/home/${username}";

    # Does not need to be changed
    # Don't change this after the first build.
    stateVersion = "24.11";
  };
}
