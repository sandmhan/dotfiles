{
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.programs.sandvim.enable {
    programs.nvf.settings.vim = {
      lsp = {
        trouble = {
          enable = true;
          mappings = {
            workspaceDiagnostics = "<leader>xw";
            documentDiagnostics = "<leader>xd";
            lspReferences = "<leader>xR";
            quickfix = "<leader>xq";
            locList = "<leader>xl";
            symbols = "<leader>xs";
          };
        };

        lightbulb.enable = true;
      };

      utility = {
        grug-far-nvim.enable = true;
        diffview-nvim.enable = true;
        sleuth.enable = true;
      };

      ui.fastaction.enable = true;

      mini = {
        align.enable = true;
        splitjoin.enable = true;
        move.enable = true;
      };

      keymaps = [
        {
          key = "<leader>sr";
          mode = [ "n" ];
          action = "<cmd>GrugFar<cr>";
          desc = "Search and replace workspace";
        }
        {
          key = "<leader>sR";
          mode = [ "n" ];
          action = "<cmd>GrugFarWithin<cr>";
          desc = "Search and replace current buffer";
        }
        {
          key = "<leader>gd";
          mode = [ "n" ];
          action = "<cmd>DiffviewOpen<cr>";
          desc = "Git diff review";
        }
        {
          key = "<leader>gD";
          mode = [ "n" ];
          action = "<cmd>DiffviewClose<cr>";
          desc = "Git diff review close";
        }
        {
          key = "<leader>gh";
          mode = [ "n" ];
          action = "<cmd>DiffviewFileHistory %<cr>";
          desc = "Git current file history";
        }
        {
          key = "<leader>gH";
          mode = [ "n" ];
          action = "<cmd>DiffviewFileHistory<cr>";
          desc = "Git file history";
        }
        {
          key = "<leader>gt";
          mode = [ "n" ];
          action = "<cmd>DiffviewToggleFiles<cr>";
          desc = "Git diff files toggle";
        }
      ];
    };
  };
}
