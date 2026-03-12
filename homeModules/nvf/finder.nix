{
  lib,
  pkgs,
  ...
}:
{
  programs.nvf = {
    settings.vim = {
      fzf-lua = {
        enable = true;
        profile = "default";
      };
    };
  };
}
