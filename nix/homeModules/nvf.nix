{
  lib,
  pkgs,
  ...
}:
{

  programs.nvf = {
    enable = true;

    settings.vim = {
      viAlias = true;
      vimAlias = true;

      clipboard = {
        enable = true;
        providers = {
          # Wayland clipboard
          wl-copy.enable = true;
          # X11 clipboard
          xsel.enable = true;
        };
        registers = "unnamedplus";
      };

      globals = {
        mapleader = " ";
      };

      options = {
        relativenumber = true; # Relative Line numbers
        number = true; # Display the absolute line numver of the current line
        scrolloff = 5; # Number of screen lines shown around the cursor
        # Tab options
        tabstop = 2; # Number of spaces a <Tab> in the text stands for (local to buffer)
        shiftwidth = 2; # Number of spaces used for each step of (auto)indent (local to buffer)
        expandtab = true; # Expand <Tab> to spaces in Insert mode (local to buffer)
        autoindent = true; # Do clever autoindenting
      };


      keymaps = [
        {
          key = "j";
          mode = ["n" "x"];
          silent = true;
          expr = true;
          action = "v:count == 0 ? 'gj' : 'j'";
          desc = "Smart down navigation";
        }
        {
          key = "k";
          mode = ["n" "x"];
          silent = true;
          expr = true;
          action = "v:count == 0 ? 'gk' : 'k'";
          desc = "Smart up navigation";
        }
        {
          key = "H";
          mode = [ "n" ];
          action = "<cmd>bprevious<CR>";
          desc = "Previous Buffer Navigation";
        }
        {
          key = "L";
          mode = [ "n" ];
          action = "<cmd>bnext<CR>";
          desc = "Next Buffer Navigation";
        }
        {
          key = "<esc>";
          mode = [ "n" "i" ];
          action = "<cmd>noh<cr><esc>";
          desc = "Escape and Clear hlsearch";
        }
        {
          key = "<leader>e";
          mode = [ "n" ];
          #lua = true;
          action = ":lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<cr>";
          desc = "Mini-File: Open directory of current file";
        }
        {
          key = "<leader>cp";
          mode = [ "n" ];
          action = "<cmd>MarkdownPreview<cr>";
          desc = "MarkdownPreview: Render the current markdown file";
        }
      ];

      # --- Plugins ---

      # Practical Ricing
      visuals = {
        nvim-web-devicons.enable = true;
        nvim-cursorline.enable = true;
        indent-blankline.enable = true;
      };

      # Prettier buffer tabs
      tabline.nvimBufferline = {
        enable = true;
        setupOpts.options = {
          numbers = "none";
        };
      };

      # File Explorer
      mini.files.enable = true;

      # Navigation
      utility.motion.flash-nvim.enable = true;

      # Markdown Previewer
      utility.preview.markdownPreview.enable = true;

      # Development Assistance
      utility.nix-develop.enable = true;

      # Hotkey Cheatsheet
      binds.whichKey.enable = true;

      # Random Cool Plugins
      utility.ccc.enable = true;

      # List of plugins to load at startup
      startPlugins = [
      ];

      optPlugins = [
      ];

      lsp = {
        enable = true;
        inlayHints.enable = true;
        servers = {
          # CPP
          clangd.enable = true;

          # Nix
          nixd.enable = true;
          nil_ls.enable = true;

          # Typst
          tinymist.enable = true;

          # Markdown
          marksman.enable = true;
        };

        # Spellchecking
        harper-ls = {
          enable = true;
        };
      };

      treesitter = {
        enable = true;
        grammars = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          c
          nix
        ];
        addDefaultGrammars = true;
        highlight.enable = true;

      };
    };
  };
}
