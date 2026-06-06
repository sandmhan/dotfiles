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
              type = [ "prettierd" ];
            };
            lsp = {
              enable = true;
              servers = [ "marksman" ];
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
              debugger = "lldb-vscode";
            };
          };
        };
      };
    };

  };
}
