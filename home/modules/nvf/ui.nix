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
        # Statusline
        statusline.lualine.enable = true;

        ui = {
          # Better command line and search UI
          noice.enable = true;

          # Highlight current word under cursor
          illuminate.enable = false;

          # Breadcrumbs showing code context
          breadcrumbs.enable = true;
        };

        # Both Markdown LSPs provide document symbols, but nvim-navic supports
        # only one breadcrumb source per buffer. Keep markdown-oxide as the
        # breadcrumb owner while obsidian-ls provides note-aware completion,
        # navigation, rename, references, and other LSP features.
        pluginRC.navic-markdown-owner = {
          after = [ "breadcrumbs" ];
          before = [ ];
          data = ''
            local navic = require("nvim-navic")
            if not navic._sandvim_markdown_owner then
              local attach = navic.attach
              navic.attach = function(client, bufnr)
                if client.name == "obsidian-ls" then
                  return
                end
                return attach(client, bufnr)
              end
              navic._sandvim_markdown_owner = true
            end
          '';
        };
      };
    };

  };
}
