{
  lib,
  pkgs,
  ...
}:
{
  programs.nvf = {
    settings.vim = {
      notes = {
        # Highlight TODO, FIXME, NOTE, HACK, etc.
        todo-comments.enable = true;
      };
    };
  };
}
