{
  lib,
  pkgs,
  ...
}:
{
  programs.nvf = {
    settings.vim = {
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
    };
  };
}
