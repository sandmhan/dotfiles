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
    ./languages-python.nix
    ./languages-web.nix
    ./languages-infra.nix
    ./completion.nix
    ./treesitter.nix
    ./utility.nix
    ./finder.nix
    ./editing.nix
    ./git.nix
    ./notes.nix
    ./tidal.nix
    ./toggles.nix
    ./ui.nix
  ];

  programs.nvf = {
    enable = true;
  };
}
