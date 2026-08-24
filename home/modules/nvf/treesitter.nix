{
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.programs.sandvim.enable {
    programs.nvf = {
      settings.vim = {
        treesitter = {
          enable = true;
          addDefaultGrammars = true;
          highlight.enable = true;
        };
      };
    };

  };
}
