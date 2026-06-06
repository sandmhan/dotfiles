{
  lib,
  config,
  ...
}:
let
  cfg = config.programs.sandvim;
in
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
    ./debugging.nix
    ./hardening.nix
    ./ai-codecompanion.nix
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

  config = lib.mkIf cfg.enable {
    programs.nvf.enable = true;
  };
}
