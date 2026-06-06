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
        notes = {
          # Highlight TODO, FIXME, NOTE, HACK, etc.
          todo-comments.enable = true;
        };
      };
    };

  };
}
