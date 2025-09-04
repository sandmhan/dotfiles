{
  lib,
  pkgs,
  userSettings,
	nixvim,
  ...
}:
let
  username = userSettings.username;
	font = userSettings.font;
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

    extraConfig = ''
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

	programs.alacritty = {
		enable = true;
		settings = {
			#font = {
			#	normal = {
			#		family = "BlexMono";
			#		style = "Regular";
			#	};
			#	bold = {
			#		family = font;
			#		style = "Bold";
			#	};
			#	italic = {
			#		family = font;
			#		style = "Italic";
			#	};
			#	bold_italic = {
			#		family = font;
			#		style = "Bold Italic";
			#	};

			#	size = 16;
			#};
		};
	};

  programs.qutebrowser = {
    enable = true;
    # quickmarks = {
    # 	nixpkgs = "https://github.com/NixOS/nixpkgs";
    # 	home-manager = "https://github.com/nix-community/home-manager";
    # };
  };

	# Nixvim configuration
	programs.nixvim = {
		enable = true;
		defaultEditor = true;
		viAlias = true;
		vimAlias = true;

		# Clipboard settings
		clipboard = {
			providers = {
				wl-copy.enable = true;
				xsel.enable = true;
			};
			register = "unnamedplus";
		};

		# Editor Options
		opts = {
			# Line numbers
			relativenumber = true;
			scrolloff = 8; # Number of screen lines shown around the cursor

			# Tab options
      tabstop = 2; # Number of spaces a <Tab> in the text stands for (local to buffer)
      shiftwidth = 2; # Number of spaces used for each step of (auto)indent (local to buffer)
      expandtab = true; # Expand <Tab> to spaces in Insert mode (local to buffer)

			# Encoding settings
			encoding = "utf-8";
			fileencoding = "utf-8";

      autoindent = true; # Do clever autoindenting

			# Enable more colors (24-bit)
			termguicolors = true;
		};

		# Plugins
		plugins = {
			# Icons
			web-devicons.enable = true;
			bufferline.enable = true;
		};
	};

	fonts.fontconfig.enable = true;

  nixpkgs.config.allowUnfree = true;
  home = {
    # Define user packages here
    packages = with pkgs; [
      hello
      alacritty
      kitty
      nixfmt-rfc-style # styling nix files
      qmk
      #nerd-fonts
      mpv
      parsec-bin
    ];

    # This needs to match the actual username logged into
    inherit username;
    homeDirectory = "/home/${username}";

    # Does not need to be changed
    # Don't change this after the first build.
    stateVersion = "24.11";
  };
}
