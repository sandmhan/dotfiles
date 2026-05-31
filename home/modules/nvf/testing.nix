{ pkgs, ... }:
{
  programs.nvf.settings.vim = {
    debugger.nvim-dap = {
      enable = true;

      ui = {
        enable = true;
        autoStart = true;
      };
    };

    extraPlugins = {
      neotest = {
        package = pkgs.vimPlugins.neotest;
        setup = ''
          require("neotest").setup({
            adapters = {
              require("neotest-python")({
                dap = { justMyCode = false },
                runner = "pytest",
              }),
              require("neotest-jest")({
                jestCommand = "npx jest",
              }),
              require("neotest-vitest")({
                vitestCommand = "npx vitest",
              }),
            },
          })
        '';
      };

      "neotest-python" = {
        package = pkgs.vimPlugins.neotest-python;
      };

      "neotest-jest" = {
        package = pkgs.vimPlugins.neotest-jest;
      };

      "neotest-vitest" = {
        package = pkgs.vimPlugins.neotest-vitest;
      };
    };

    keymaps = [
      {
        key = "<leader>tn";
        mode = [ "n" ];
        action = "<cmd>lua require('neotest').run.run()<cr>";
        desc = "Test nearest";
      }
      {
        key = "<leader>tf";
        mode = [ "n" ];
        action = "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<cr>";
        desc = "Test file";
      }
      {
        key = "<leader>ta";
        mode = [ "n" ];
        action = "<cmd>lua require('neotest').run.run(vim.uv.cwd())<cr>";
        desc = "Test suite";
      }
      {
        key = "<leader>tr";
        mode = [ "n" ];
        action = "<cmd>lua require('neotest').run.run_last()<cr>";
        desc = "Test last failed";
      }
      {
        key = "<leader>to";
        mode = [ "n" ];
        action = "<cmd>lua require('neotest').output.open({ enter = true, auto_close = true })<cr>";
        desc = "Test output";
      }
      {
        key = "<leader>ts";
        mode = [ "n" ];
        action = "<cmd>lua require('neotest').summary.toggle()<cr>";
        desc = "Test summary";
      }
      {
        key = "<leader>tw";
        mode = [ "n" ];
        action = "<cmd>lua require('neotest').watch.toggle(vim.fn.expand('%'))<cr>";
        desc = "Test watch file";
      }
      {
        key = "<leader>tD";
        mode = [ "n" ];
        action = "<cmd>lua require('neotest').run.run({ strategy = 'dap' })<cr>";
        desc = "Debug nearest test";
      }
      {
        key = "<leader>dp";
        mode = [ "n" ];
        action = "<cmd>lua require('dap').pause()<cr>";
        desc = "Debug pause";
      }
      {
        key = "<leader>dB";
        mode = [ "n" ];
        action = "<cmd>lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>";
        desc = "Debug conditional breakpoint";
      }
      {
        key = "<leader>dx";
        mode = [ "n" ];
        action = "<cmd>lua require('dap').clear_breakpoints()<cr>";
        desc = "Debug clear breakpoints";
      }
      {
        key = "<leader>ds";
        mode = [ "n" ];
        action = "<cmd>lua require('dap.ui.widgets').centered_float(require('dap.ui.widgets').scopes)<cr>";
        desc = "Debug scopes";
      }
    ];
  };
}
