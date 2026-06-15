{
  lib,
  config,
  ...
}:
let
  inherit (lib.generators) mkLuaInline;
in
{
  config = lib.mkIf config.programs.sandvim.enable {
    programs.nvf = {
      settings.vim = {
        notes = {
          # Highlight TODO, FIXME, NOTE, HACK, etc.
          todo-comments.enable = true;

          obsidian = {
            enable = true;
            setupOpts = {
              legacy_commands = false;
              workspaces = mkLuaInline ''
                {
                  {
                    name = "cwd",
                    path = function()
                      if _G.NvfWorkspaceRoot then
                        return _G.NvfWorkspaceRoot()
                      end
                      return vim.uv.cwd()
                    end,
                  },
                }
              '';
              picker.name = "fzf-lua";
              completion.nvim_cmp = false;
            };
          };
        };

        keymaps = [
          {
            key = "<leader>nn";
            mode = [ "n" ];
            action = "<cmd>Obsidian new<cr>";
            desc = "Notes new note";
          }
          {
            key = "<leader>no";
            mode = [ "n" ];
            action = "<cmd>Obsidian open<cr>";
            desc = "Notes open in Obsidian";
          }
          {
            key = "<leader>nq";
            mode = [ "n" ];
            action = "<cmd>Obsidian quick_switch<cr>";
            desc = "Notes quick switch";
          }
          {
            key = "<leader>ns";
            mode = [ "n" ];
            action = "<cmd>Obsidian search<cr>";
            desc = "Notes search";
          }
          {
            key = "<leader>nb";
            mode = [ "n" ];
            action = "<cmd>Obsidian backlinks<cr>";
            desc = "Notes backlinks";
          }
          {
            key = "<leader>nl";
            mode = [ "n" ];
            action = "<cmd>Obsidian links<cr>";
            desc = "Notes links";
          }
          {
            key = "<leader>nf";
            mode = [ "n" ];
            action = "<cmd>Obsidian follow_link<cr>";
            desc = "Notes follow link";
          }
          {
            key = "<leader>nt";
            mode = [ "n" ];
            action = "<cmd>Obsidian tags<cr>";
            desc = "Notes tags";
          }
          {
            key = "<leader>nr";
            mode = [ "n" ];
            action = "<cmd>Obsidian rename<cr>";
            desc = "Notes rename";
          }
        ];
      };
    };
  };
}
