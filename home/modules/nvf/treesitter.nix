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

  };
}
