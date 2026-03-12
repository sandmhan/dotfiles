{
  lib,
  pkgs,
  ...
}:
{
  programs.nvf = {
    settings.vim = {
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
