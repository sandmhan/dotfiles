{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.programs.sandvim;
in
{
  config = lib.mkIf (cfg.enable && cfg.packs.languages.java) {
    programs.nvf.settings.vim = {
      extraPackages = [ pkgs.astyle ];

      languages.java = {
        enable = true;
        treesitter.enable = true;

        lsp = {
          enable = true;
          servers = [ "jdt-language-server" ];
        };

        format = {
          enable = true;
          type = [ "astyle" ];
        };

        dap.enable = false;
      };
    };
  };
}
