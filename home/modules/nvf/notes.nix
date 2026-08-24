{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.programs.sandvim;
  inherit (lib.generators) mkLuaInline;
in
{
  config = lib.mkIf (cfg.enable && cfg.packs.notes) {
    programs.nvf = {
      settings.vim = {
        # Keep paste-image helpers on the wrapped Neovim PATH, including when
        # consumers use the exported standalone Sandvim packages.
        extraPackages =
          lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.xclip ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.pngpaste ];

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
              # obsidian-ls owns note-aware completion/navigation alongside Obsidian.nvim commands.
              attachments.folder = cfg.notes.attachmentsFolder;
              templates.folder = cfg.notes.templatesFolder;
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
          {
            key = "<leader>np";
            mode = [ "n" ];
            action = "<cmd>Obsidian paste_img<cr>";
            desc = "Notes paste image";
          }
          {
            key = "<leader>nx";
            mode = [ "n" ];
            action = "<cmd>Obsidian toggle_checkbox<cr>";
            desc = "Notes toggle checkbox";
          }
          {
            key = "<leader>nT";
            mode = [ "n" ];
            action = "<cmd>Obsidian template<cr>";
            desc = "Notes insert template";
          }
        ];
      };
    };
  };
}
