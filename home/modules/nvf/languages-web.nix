{ pkgs, ... }:
{
  programs.nvf = {
    settings.vim = {
      languages = {
        ts = {
          enable = true;
          treesitter.enable = true;

          lsp = {
            enable = true;
            servers = [ "ts_ls" ];
          };

          format = {
            enable = true;
            type = [ "prettierd" ];
          };

          extraDiagnostics = {
            enable = true;
            types = [ "eslint_d" ];
          };
        };

        json = {
          enable = true;
          treesitter.enable = true;

          lsp = {
            enable = true;
            servers = [ "jsonls" ];
          };

          format = {
            enable = true;
            type = [ "jsonfmt" ];
          };
        };
      };

      # Pinned NVF only derives ESLint mappings for TypeScript filetypes from
      # languages.ts.extraDiagnostics, so wire JavaScript filetypes explicitly.
      diagnostics.nvim-lint.linters_by_ft = {
        javascript = [ "eslint_d" ];
        javascriptreact = [ "eslint_d" ];
      };

      # JavaScript/TypeScript DAP ownership only. Phase 3 will decide task/test
      # commands and any additional debug keymaps.
      debugger.nvim-dap = {
        enable = true;
        sources.js-debugger = ''
          local dap = require("dap")
          local js_debug_port = 8123

          dap.adapters["pwa-node"] = {
            type = "server",
            host = "127.0.0.1",
            port = js_debug_port,
            executable = {
              command = "${pkgs.vscode-js-debug}/bin/js-debug",
              args = { tostring(js_debug_port) },
            },
          }

          for _, language in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact" }) do
            dap.configurations[language] = dap.configurations[language] or {}
            vim.list_extend(dap.configurations[language], {
              {
                type = "pwa-node",
                request = "launch",
                name = "Launch current file",
                program = "''${file}",
                cwd = "''${workspaceFolder}",
                sourceMaps = true,
                console = "integratedTerminal",
              },
              {
                type = "pwa-node",
                request = "attach",
                name = "Attach to Node process",
                processId = require("dap.utils").pick_process,
                cwd = "''${workspaceFolder}",
                sourceMaps = true,
              },
            })
          end
        '';
      };
    };
  };
}
