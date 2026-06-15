{
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.programs.sandvim.enable {
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
  };
}
