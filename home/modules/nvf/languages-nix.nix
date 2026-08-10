{
  lib,
  config,
  ...
}:
let
  cfg = config.programs.sandvim;
in
{
  config = lib.mkIf (cfg.enable && cfg.packs.languages.nix) {
    programs.nvf.settings.vim.languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;

      nix = {
        enable = true;
        extraDiagnostics.enable = true;
        treesitter.enable = true;
        format.type = [ "nixfmt" ];
        lsp = {
          enable = true;
          servers = [ "nixd" ];
        };
      };
    };
  };
}
