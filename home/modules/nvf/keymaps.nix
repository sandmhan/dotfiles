{
  lib,
  pkgs,
  ...
}:
{
  programs.nvf = {
    settings.vim = {
      globals = {
        mapleader = " ";
      };

      keymaps = [
        {
          key = "j";
          mode = [
            "n"
            "x"
          ];
          silent = true;
          expr = true;
          action = "v:count == 0 ? 'gj' : 'j'";
          desc = "Smart down navigation";
        }
        {
          key = "k";
          mode = [
            "n"
            "x"
          ];
          silent = true;
          expr = true;
          action = "v:count == 0 ? 'gk' : 'k'";
          desc = "Smart up navigation";
        }
        {
          key = "H";
          mode = [ "n" ];
          action = "<cmd>BufferLineCyclePrev<CR>";
          desc = "Previous Buffer Navigation (Visual Order)";
        }
        {
          key = "L";
          mode = [ "n" ];
          action = "<cmd>BufferLineCycleNext<CR>";
          desc = "Next Buffer Navigation (Visual Order)";
        }
        {
          key = "<leader>bd";
          mode = [ "n" ];
          action = "<cmd>bdelete<CR>";
          desc = "Close Current Buffer";
        }
        {
          key = "<esc>";
          mode = [
            "n"
            "i"
          ];
          action = "<cmd>noh<cr><esc>";
          desc = "Escape and Clear hlsearch";
        }
        {
          key = "<leader>e";
          mode = [ "n" ];
          action = ":lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<cr>";
          desc = "Mini-File: Open directory of current file";
        }
        {
          key = "<leader>cp";
          mode = [ "n" ];
          action = "<cmd>MarkdownPreview<cr>";
          desc = "MarkdownPreview: Render the current markdown file";
        }
        # fzf-lua keymaps
        {
          key = "<leader><leader>";
          mode = [ "n" ];
          action = "<cmd>FzfLua files<cr>";
          desc = "Find files";
        }
        {
          key = "<leader>/";
          mode = [ "n" ];
          action = "<cmd>FzfLua live_grep<cr>";
          desc = "Live grep";
        }
        {
          key = "<leader>fb";
          mode = [ "n" ];
          action = "<cmd>FzfLua buffers<cr>";
          desc = "Find buffers";
        }
        {
          key = "<leader>fh";
          mode = [ "n" ];
          action = "<cmd>FzfLua help_tags<cr>";
          desc = "Help tags";
        }
        {
          key = "<leader>fr";
          mode = [ "n" ];
          action = "<cmd>FzfLua oldfiles<cr>";
          desc = "Recent files";
        }
        {
          key = "<leader>fw";
          mode = [ "n" ];
          action = "<cmd>FzfLua grep_cword<cr>";
          desc = "Grep word under cursor";
        }
        # fzf-lua git
        {
          key = "<leader>gs";
          mode = [ "n" ];
          action = "<cmd>FzfLua git_status<cr>";
          desc = "Git status";
        }
        {
          key = "<leader>gc";
          mode = [ "n" ];
          action = "<cmd>FzfLua git_commits<cr>";
          desc = "Git commits";
        }
        {
          key = "<leader>gb";
          mode = [ "n" ];
          action = "<cmd>FzfLua git_branches<cr>";
          desc = "Git branches";
        }
        {
          key = "<leader>gf";
          mode = [ "n" ];
          action = "<cmd>FzfLua git_files<cr>";
          desc = "Git files";
        }
        # fzf-lua LSP
        {
          key = "<leader>lr";
          mode = [ "n" ];
          action = "<cmd>FzfLua lsp_references<cr>";
          desc = "LSP references";
        }
        {
          key = "<leader>ld";
          mode = [ "n" ];
          action = "<cmd>FzfLua lsp_definitions<cr>";
          desc = "LSP definitions";
        }
        {
          key = "<leader>ls";
          mode = [ "n" ];
          action = "<cmd>FzfLua lsp_document_symbols<cr>";
          desc = "LSP document symbols";
        }
        {
          key = "<leader>lw";
          mode = [ "n" ];
          action = "<cmd>FzfLua lsp_workspace_symbols<cr>";
          desc = "LSP workspace symbols";
        }
        {
          key = "<leader>la";
          mode = [ "n" ];
          action = "<cmd>FzfLua lsp_code_actions<cr>";
          desc = "LSP code actions";
        }
        {
          key = "<leader>lh";
          mode = [ "n" ];
          action = "<cmd>lua vim.lsp.buf.hover()<cr>";
          desc = "LSP hover";
        }
        {
          key = "<leader>lR";
          mode = [ "n" ];
          action = "<cmd>lua vim.lsp.buf.rename()<cr>";
          desc = "LSP rename";
        }
        {
          key = "<leader>li";
          mode = [ "n" ];
          action = "<cmd>lua vim.lsp.buf.implementation()<cr>";
          desc = "LSP implementation";
        }
        {
          key = "<leader>lt";
          mode = [ "n" ];
          action = "<cmd>lua vim.lsp.buf.type_definition()<cr>";
          desc = "LSP type definition";
        }
        {
          key = "<leader>lk";
          mode = [ "n" ];
          action = "<cmd>lua vim.lsp.buf.signature_help()<cr>";
          desc = "LSP signature help";
        }
        {
          key = "<leader>xx";
          mode = [ "n" ];
          action = "<cmd>FzfLua diagnostics_document<cr>";
          desc = "Document diagnostics";
        }
      ];
    };
  };
}
