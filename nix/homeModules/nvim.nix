{
  ...
}:
{
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
          clangd = {
            enable = true;
            #config = {
            #  cmd = [
            #    "clangd"
            #    "--background-index"
            #  ];
            #  filetypes = [
            #    "c"
            #    "cpp"
            #  ];
            #  root_markers = [
            #    "CMakeLists.txt"
            #    ".git"
            #  ];
            #};
          };
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

}
