{
  lib,
  pkgs,
  ...
}:
{
  programs.nvf = {
    settings.vim = {
      autocomplete.blink-cmp = {
        enable = true;
        friendly-snippets.enable = true;
        mappings = {
          scrollDocsDown = "<C-f>";
          scrollDocsUp = "<C-g>";
        };
      };
    };
  };
}
