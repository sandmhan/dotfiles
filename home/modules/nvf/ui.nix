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
        # Statusline
        statusline.lualine.enable = true;

        ui = {
          # Better command line and search UI
          noice.enable = true;

          # Highlight current word under cursor
          illuminate.enable = false;

          # Breadcrumbs showing code context
          breadcrumbs.enable = true;
        };
      };
    };

  };
}
