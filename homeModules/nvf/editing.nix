{
  lib,
  pkgs,
  ...
}:
{
  programs.nvf = {
    settings.vim = {
      # Auto-close brackets, quotes, etc.
      autopairs.nvim-autopairs.enable = true;

      # Toggle comments with gc
      comments.comment-nvim.enable = true;

      # Change/add/delete surrounding characters
      utility.surround.enable = true;

      # Visual undo history tree
      utility.undotree.enable = true;
    };
  };
}
