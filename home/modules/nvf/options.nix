{
  lib,
  pkgs,
  ...
}:
{
  programs.nvf = {
    settings.vim = {
      viAlias = true;
      vimAlias = true;

      clipboard = {
        enable = true;
        providers = {
          # Wayland clipboard
          wl-copy.enable = true;
          # X11 clipboard
          xsel.enable = true;
        };
        registers = "unnamedplus";
      };

      options = {
        relativenumber = true; # Relative Line numbers
        number = true; # Display the absolute line number of the current line
        scrolloff = 5; # Number of screen lines shown around the cursor
        # Tab options
        tabstop = 2; # Number of spaces a <Tab> in the text stands for (local to buffer)
        shiftwidth = 2; # Number of spaces used for each step of (auto)indent (local to buffer)
        expandtab = true; # Expand <Tab> to spaces in Insert mode (local to buffer)
        autoindent = true; # Do clever auto-indenting
      };
    };
  };
}
