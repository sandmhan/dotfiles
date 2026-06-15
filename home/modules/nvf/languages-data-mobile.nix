{
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.programs.sandvim.enable {
    programs.nvf.settings.vim.languages = {
      sql = {
        enable = true;
        treesitter.enable = true;

        lsp = {
          enable = true;
          servers = [ "sqls" ];
        };

        format = {
          enable = true;
          type = [ "sqlfluff" ];
        };

        extraDiagnostics = {
          enable = true;
          types = [ "sqlfluff" ];
        };
      };

      dart = {
        enable = true;
        treesitter.enable = true;

        lsp = {
          enable = true;
          servers = [ "dart" ];
        };

        dap.enable = false;

        flutter-tools = {
          enable = true;
          # Keep the editor wrapper portable and lightweight. Projects that need
          # Flutter should provide `flutter` on PATH through a devshell or SDK.
          # NVF's no-resolve patch currently fails to apply to the pinned
          # flutter-tools.nvim source, so keep it disabled and prefer a non-Nix
          # Flutter SDK on PATH until the NVF/input pin is updated.
          flutterPackage = null;
          enableNoResolvePatch = false;
        };
      };
    };
  };
}
