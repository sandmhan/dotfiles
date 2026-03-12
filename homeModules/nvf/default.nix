{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./options.nix
    ./keymaps.nix
    ./visuals.nix
    ./lsp.nix
    ./languages.nix
    ./completion.nix
    ./treesitter.nix
    ./utility.nix
    ./finder.nix
    ./editing.nix
    ./git.nix
    ./notes.nix
    ./toggles.nix
    ./ui.nix
  ];

  programs.nvf = {
    enable = true;
  };
}
