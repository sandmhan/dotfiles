{ lib, pkgs, userSettings, ...}:
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

    # extraConfig = builtins.readFile "github:sandmhan/dotfiles/nix/config/.tmux.conf";
  };

	programs.bash = {
		enable = true;
		shellAliases = {
			ll = "ls -l";
			".." = "cd ..";
		};
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
      nixfmt-rfc-style #styling nix files
    ];

    # This needs to match the actual username logged into
    inherit username;
    homeDirectory = "/home/${username}";

    # Does not need to be changed
    # Don't change this after the first build.
    stateVersion = "24.11";
  };
}
