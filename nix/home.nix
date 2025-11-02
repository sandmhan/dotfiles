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
  configPath =
    if pkgs.stdenv.isLinux then
      "/home/${username}/dotfile/configs/"
    else
      "/Users/${username}/dotfile/configs/";
in
{
  # home-manager package
  programs.home-manager.enable = true;

  stylix = {
    enable = true;

    # Current theme file
    # TODO: Make this sourced from personal colorscheme and linked wallpaper like librephoenix's config
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";

    fonts = {
      # Monospace font for terminals and code editors
      monospace = {
        package = pkgs.nerd-fonts.blex-mono;
        name = "BlexMono Nerd Font";
      };

      # Optional: emoji font, if you want emojis to render properly
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };
  };

  programs.git = {
    enable = true;
    settings.user = {
      email = "austinsanders0105@gmail.com";
      name = "sandmhan";
    };
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

        # Pane Navigation
      	bind -n C-h select-pane -L
      	bind -n C-j select-pane -D
      	bind -n C-k select-pane -U
      	bind -n C-l select-pane -R

        # Resizing Panes
        bind -r h resize-pane -L 5
        bind -r j resize-pane -D 5
        bind -r k resize-pane -U 5
        bind -r l resize-pane -R 5
    '';

    # extraConfig = builtins.readFile "github:sandmhan/dotfiles/nix/config/.tmux.conf";
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      ".." = "cd ..";
      gs = "git status";
      ga = "git add";
      gc = "git commit -m";
    };

    bashrcExtra = "set -o vi";
  };

  programs.alacritty = {
    enable = true;
  };

  programs.qutebrowser = {
    enable = true;

    searchEngines = {
      w = "https://en.wikipedia.org/wiki/Special:Search?search={}&amp;go=Go&amp;ns0=1";
      g = "https://www.google.com/search?hl=en&amp;q={}";
      hm = "https://home-manager-options.extranix.com/?query={}&release=release-25.05";
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
    };
    extraConfig = ''
      c.content.javascript.log_message.excludes = {
        'userscript:_qute_stylesheet' : ['*Refused to apply inline style because it violates the following Content Security Policy directive: *'],
        'userscript:_qute_js' : ['*TrustedHTML*']
      }
    '';
  };

  # Nixvim configuration
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    globals.mapleader = " ";

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
      relativenumber = true; # Relative Line numbers
      number = true; # Display the absolute line numver of the current line
      scrolloff = 5; # Number of screen lines shown around the cursor

      # Tab options
      tabstop = 2; # Number of spaces a <Tab> in the text stands for (local to buffer)
      shiftwidth = 2; # Number of spaces used for each step of (auto)indent (local to buffer)
      expandtab = true; # Expand <Tab> to spaces in Insert mode (local to buffer)
      autoindent = true; # Do clever autoindenting

      # Encoding settings
      encoding = "utf-8";
      fileencoding = "utf-8";

      swapfile = false; # Disable swapfiles

      # Enable more colors (24-bit)
      termguicolors = true;
    };

    keymaps = [
      {
        mode = [
          "n"
          "x"
        ];
        key = "j";
        action = "v:count == 0 ? 'gj' : 'j'";
        options = {
          expr = true;
          silent = true;
        };
      }
      {
        mode = [
          "n"
          "x"
        ];
        key = "k";
        action = "v:count == 0 ? 'gk' : 'k'";
        options = {
          expr = true;
          silent = true;
        };
      }
      {
        key = "H";
        mode = [ "n" ];
        action = "<cmd>bprevious<CR>";
      }
      {
        key = "L";
        mode = [ "n" ];
        action = "<cmd>bnext<CR>";
      }
      {
        mode = [
          "i"
          "n"
        ];
        key = "<esc>";
        action = "<cmd>noh<cr><esc>";
        options = {
          desc = "Escape and Clear hlsearch";
        };
      }
    ];

    # Plugins
    plugins = {
      # Icons
      web-devicons.enable = true;

      # Makes the buffer tabs look nicer
      bufferline.enable = true;

      # nix style highlighting
      nix.enable = true;

      # Render markdown documents in browser
      markdown-preview = {
        enable = true;
        settings.theme = "dark";
      };

      # Status line
      lualine.enable = true;

      # Show off available keymaps
      which-key.enable = true;

      lsp = {
        enable = true;

        inlayHints = true;

        # Add Language Servers here
        servers = {
          nil_ls.enable = true;
          nixd.enable = true;
          clangd.enable = true;
          cmake.enable = true;
          tinymist.enable = true;
          marksman.enable = true;
        };

        keymaps = {
          lspBuf = {
            gd = {
              action = "definition";
              desc = "Goto Definition";
            };
            gr = {
              action = "references";
              desc = "Goto References";
            };
            gD = {
              action = "declaration";
              desc = "Goto Declaration";
            };
            gI = {
              action = "implementation";
              desc = "Goto Implementation";
            };
            gT = {
              action = "type_definition";
              desc = "Type Definition";
            };
            K = {
              action = "hover";
              desc = "Hover";
            };
            "<leader>cr" = {
              action = "rename";
              desc = "Rename";
            };
          };

          diagnostic = {
            "<leader>cd" = {
              action = "open_float";
              desc = "Line Diagnostics";
            };
            "[d" = {
              action = "goto_next";
              desc = "Next Diagnostic";
            };
            "]d" = {
              action = "goto_prev";
              desc = "Previous Diagnostic";
            };
          };
        };
      };
    };
  };

  home.keyboard = {
    layout = "us";
    options = [ "caps_toggle:escape" ];

  };

  fonts.fontconfig.enable = true;

  wayland.windowManager.sway.enable = true;

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
        #nerd-fonts
        nerd-fonts.blex-mono
        mpv
        typst
        zathura
        legcord
        bitwarden-desktop
        bitwarden-cli
        openvpn
        qbittorrent
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
