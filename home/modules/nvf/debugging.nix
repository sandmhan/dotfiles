{
  programs.nvf.settings.vim = {
    debugger.nvim-dap = {
      enable = true;

      ui = {
        enable = true;
        autoStart = true;
      };
    };

    keymaps = [
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
