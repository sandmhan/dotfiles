{
  lib,
  config,
  ...
}:
let
  cfg = config.programs.sandvim;
in
{
  config = lib.mkIf cfg.enable {
    programs.nvf = {
      settings.vim = {
        # File Explorer
        mini.files.enable = true;

        utility = {
          # Jump navigation
          motion.flash-nvim.enable = true;

          # Markdown and Nix helpers belong to the general language pack.
          preview.markdownPreview.enable = cfg.packs.languages.general;
          nix-develop.enable = cfg.packs.languages.general;

          # Color Picker/Renderer
          ccc.enable = true;

          # Vim-aware split navigation with tmux pane integration.
          smart-splits = {
            enable = true;
            setupOpts.multiplexer_integration = "tmux";
          };
        };

        # Hotkey cheat sheet
        binds.whichKey.enable = true;

        # List of plugins to load at startup
        startPlugins = [ ];

        optPlugins = [ ];
      };
    };

  };
}
