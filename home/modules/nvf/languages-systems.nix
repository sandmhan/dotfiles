{
  lib,
  config,
  ...
}:
let
  cfg = config.programs.sandvim;
in
{
  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && (cfg.packs.languages.systems || cfg.packs.languages.general)) {
      programs.nvf.settings.vim.languages.clang = {
        enable = true;
        treesitter.enable = true;
        lsp = {
          enable = true;
          servers = [ "clangd" ];
        };

        format.enable = true;

        dap = {
          enable = cfg.packs.debugging;
          debugger = [ "lldb" ];
        };

        # NVF defaults C/C++ extra diagnostics to cpplint when global
        # extra diagnostics are enabled. cpplint 2.0.2 currently fails to
        # build with Python 3.14 because its test suite treats
        # DeprecationWarning output as lint output. Keep clangd diagnostics
        # and formatting, but do not pull cpplint into the editor closure.
        extraDiagnostics.enable = false;
      };
    })

    (lib.mkIf (cfg.enable && cfg.packs.languages.systems) {
      programs.nvf.settings.vim.languages = {
        rust = {
          enable = true;
          treesitter.enable = true;

          lsp.enable = true;

          format = {
            enable = true;
            type = [ "rustfmt" ];
          };

          dap.enable = false;

          extensions.crates-nvim.enable = true;
        };

        go = {
          enable = true;
          treesitter.enable = true;

          lsp = {
            enable = true;
            servers = [ "gopls" ];
          };

          format = {
            enable = true;
            type = [ "gofmt" ];
          };

          extraDiagnostics = {
            enable = true;
            types = [ "golangci-lint" ];
          };

          dap.enable = false;
        };

        lua = {
          enable = true;
          treesitter.enable = true;

          lsp = {
            enable = true;
            servers = [ "lua-language-server" ];
            lazydev.enable = true;
          };

          format = {
            enable = true;
            type = [ "stylua" ];
          };

          extraDiagnostics = {
            enable = true;
            types = [ "luacheck" ];
          };
        };
      };
    })
  ];
}
