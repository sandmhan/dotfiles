{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.programs.sandvim;
  inherit (lib) types;

  packOption =
    description:
    lib.mkOption {
      type = types.bool;
      default = false;
      inherit description;
    };

  presetDefaults = {
    minimal = {
      ai = false;
      debugging = false;
      notes = false;
      tidal = false;
      workflow = false;
      languages = {
        general = false;
        documentation = false;
        nix = false;
        python = false;
        web = false;
        infrastructure = false;
        systems = false;
        dataMobile = false;
        java = false;
      };
    };

    standard = {
      ai = true;
      debugging = true;
      notes = true;
      tidal = true;
      workflow = true;
      languages = {
        general = false;
        documentation = true;
        nix = true;
        python = true;
        web = true;
        infrastructure = true;
        systems = true;
        dataMobile = true;
        java = false;
      };
    };

    full = {
      ai = true;
      debugging = true;
      notes = true;
      tidal = true;
      workflow = true;
      languages = {
        general = false;
        documentation = true;
        nix = true;
        python = true;
        web = true;
        infrastructure = true;
        systems = true;
        dataMobile = true;
        java = true;
      };
    };
  };

  selectedDefaults = presetDefaults.${cfg.preset};
in
{
  options.programs.sandvim = {
    enable = lib.mkEnableOption "Sandvim, this repository's NVF-based Neovim configuration";

    preset = lib.mkOption {
      type = types.enum [
        "minimal"
        "standard"
        "full"
      ];
      default = "standard";
      description = ''
        Sandvim feature-pack preset. Minimal keeps only core and hardening,
        standard preserves the historical non-Java feature set, and full adds
        every pack including Java.
      '';
    };

    packs = {
      ai = packOption "Enable AI assistant integration.";
      debugging = packOption "Enable shared debugging UI and keymaps.";
      notes = packOption "Enable notes and Obsidian integration.";
      tidal = packOption "Enable TidalCycles live-coding support.";
      workflow = packOption "Enable workflow plugins such as Trouble, grug-far, and diffview.";

      languages = {
        general = packOption "Deprecated compatibility umbrella for Markdown/Typst documentation, Nix, and Clang support. Prefer documentation, nix, and systems.";
        documentation = packOption "Enable Markdown and Typst documentation language support.";
        nix = packOption "Enable Nix language support.";
        python = packOption "Enable Python language support.";
        web = packOption "Enable web language support.";
        infrastructure = packOption "Enable infrastructure language support.";
        systems = packOption "Enable systems language support.";
        dataMobile = packOption "Enable data and mobile language support.";
        java = packOption "Enable Java language support.";
      };
    };

    notes = {
      attachmentsFolder = lib.mkOption {
        type = types.str;
        default = "attachments";
        description = "Obsidian attachment folder used by paste-image workflows.";
      };

      templatesFolder = lib.mkOption {
        type = types.str;
        default = "templates";
        description = "Obsidian template folder used by note template workflows.";
      };
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.enable || !cfg.packs.notes || cfg.packs.languages.documentation;
          message = "programs.sandvim.packs.notes requires programs.sandvim.packs.languages.documentation so Obsidian and Markdown LSP features share one owner.";
        }
      ];

      programs.sandvim.packs = {
        ai = lib.mkDefault selectedDefaults.ai;
        debugging = lib.mkDefault selectedDefaults.debugging;
        notes = lib.mkDefault selectedDefaults.notes;
        tidal = lib.mkDefault selectedDefaults.tidal;
        workflow = lib.mkDefault selectedDefaults.workflow;

        languages = {
          general = lib.mkDefault selectedDefaults.languages.general;
          documentation = lib.mkDefault (
            selectedDefaults.languages.documentation || cfg.packs.languages.general
          );
          nix = lib.mkDefault (selectedDefaults.languages.nix || cfg.packs.languages.general);
          python = lib.mkDefault selectedDefaults.languages.python;
          web = lib.mkDefault selectedDefaults.languages.web;
          infrastructure = lib.mkDefault selectedDefaults.languages.infrastructure;
          systems = lib.mkDefault selectedDefaults.languages.systems;
          dataMobile = lib.mkDefault selectedDefaults.languages.dataMobile;
          java = lib.mkDefault selectedDefaults.languages.java;
        };
      };
    }

    (lib.mkIf cfg.enable {
      programs.nvf = {
        settings.vim = {
          viAlias = true;
          vimAlias = true;

          clipboard = {
            enable = true;
            providers = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
              # Linux display-server clipboard tools; Darwin uses its native provider.
              wl-copy.enable = true;
              xsel.enable = true;
            };
            registers = "unnamedplus";
          };

          options = {
            relativenumber = true; # Relative Line numbers
            number = true; # Display the absolute line number of the current line
            scrolloff = 5; # Number of screen lines shown around the cursor
            # Tab options
            tabstop = 2; # Number of spaces a <Tab> in the text stands for (local to buffer)
            shiftwidth = 2; # Number of spaces used for each step of (auto)indent (local to buffer)
            expandtab = true; # Expand <Tab> to spaces in Insert mode (local to buffer)
            autoindent = true; # Do clever auto-indenting
          };
        };
      };
    })
  ];
}
