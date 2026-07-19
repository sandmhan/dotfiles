{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.programs.sandvim.enable {
    programs.nvf = {
      settings.vim = {
        languages = {
          enableFormat = true;
          enableTreesitter = true;
          enableExtraDiagnostics = true;

          markdown = {
            enable = true;
            treesitter.enable = true;
            format = {
              enable = true;
              type = [ "mdformat" ];
            };
            lsp = {
              enable = true;
              servers = [ "markdown-oxide" ];
            };
            extensions = {
              # Render markdown in-buffer (tables, checkboxes, headers, links)
              render-markdown-nvim.enable = true;
            };
          };

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

          typst = {
            enable = true;
            treesitter.enable = true;
            format.type = [ "typstyle" ];
            lsp = {
              enable = true;
              servers = [ "tinymist" ];
            };
          };

          clang = {
            enable = true;
            treesitter.enable = true;
            lsp = {
              enable = true;
              servers = [ "clangd" ];
            };

            dap = {
              enable = true;
              debugger = [ "lldb" ];
            };

            # NVF defaults C/C++ extra diagnostics to cpplint when global
            # extra diagnostics are enabled. cpplint 2.0.2 currently fails to
            # build with Python 3.14 because its test suite treats
            # DeprecationWarning output as lint output. Keep clangd diagnostics
            # and formatting, but do not pull cpplint into the editor closure.
            extraDiagnostics.enable = false;
          };
        };
      };
    };

  };
}
