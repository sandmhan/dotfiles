{
  lib,
  pkgs,
  ...
}:
{
  programs.nvf = {
    settings.vim = {
      git = {
        # Git diff markers in gutter, hunk actions
        gitsigns = {
          enable = true;
          codeActions.enable = true;
        };

        # Git UI (like magit for emacs)
        neogit.enable = true;

        # Resolve git conflicts in buffer
        git-conflict.enable = true;
      };
    };
  };
}
