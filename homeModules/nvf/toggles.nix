{
  lib,
  pkgs,
  ...
}:
{
  programs.nvf = {
    settings.vim = {
      keymaps = [
        # Toggle diagnostics
        {
          key = "<leader>ud";
          mode = [ "n" ];
          action = "<cmd>lua vim.diagnostic.enable(not vim.diagnostic.is_enabled())<cr>";
          desc = "Toggle diagnostics";
        }
        # Toggle line numbers
        {
          key = "<leader>ul";
          mode = [ "n" ];
          action = "<cmd>set number!<cr>";
          desc = "Toggle line numbers";
        }
        # Toggle relative numbers
        {
          key = "<leader>ur";
          mode = [ "n" ];
          action = "<cmd>set relativenumber!<cr>";
          desc = "Toggle relative numbers";
        }
        # Toggle word wrap
        {
          key = "<leader>uw";
          mode = [ "n" ];
          action = "<cmd>set wrap!<cr>";
          desc = "Toggle word wrap";
        }
        # Toggle spell check
        {
          key = "<leader>us";
          mode = [ "n" ];
          action = "<cmd>set spell!<cr>";
          desc = "Toggle spell check";
        }
        # Toggle inlay hints
        {
          key = "<leader>uh";
          mode = [ "n" ];
          action = "<cmd>lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())<cr>";
          desc = "Toggle inlay hints";
        }
        # Toggle conceallevel (markdown rendering)
        {
          key = "<leader>uc";
          mode = [ "n" ];
          action = "<cmd>lua vim.opt.conceallevel = vim.o.conceallevel == 0 and 2 or 0<cr>";
          desc = "Toggle conceal (markdown render)";
        }
        # Toggle signcolumn (gutter signs)
        {
          key = "<leader>ug";
          mode = [ "n" ];
          action = "<cmd>lua vim.opt.signcolumn = vim.o.signcolumn == 'no' and 'yes' or 'no'<cr>";
          desc = "Toggle signcolumn (gutter)";
        }
        # Toggle treesitter highlight
        {
          key = "<leader>ut";
          mode = [ "n" ];
          action = "<cmd>TSToggle highlight<cr>";
          desc = "Toggle treesitter highlight";
        }
        # Toggle indent guides
        {
          key = "<leader>ui";
          mode = [ "n" ];
          action = "<cmd>IBLToggle<cr>";
          desc = "Toggle indent guides";
        }
      ];
    };
  };
}
