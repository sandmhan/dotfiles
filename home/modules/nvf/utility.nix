{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.programs.sandvim.enable {
    programs.nvf = {
      settings.vim = {
        # File Explorer
        mini.files.enable = true;

        utility = {
          # Jump navigation
          motion.flash-nvim.enable = true;

          # Markdown Previewer
          preview.markdownPreview.enable = true;

          # Development Assistance
          nix-develop.enable = true;

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
