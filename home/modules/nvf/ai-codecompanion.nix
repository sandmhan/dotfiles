{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.myHome.features;
  inherit (lib.generators) mkLuaInline;
in
{
  config = lib.mkIf cfg.enableNvfAiCodeCompanion {
    home.packages = [ pkgs.codex-acp ];

    programs.nvf.settings.vim = {
      assistant.codecompanion-nvim = {
        enable = true;
        setupOpts = {
          opts.log_level = "ERROR";

          adapters = mkLuaInline ''
            {
              acp = {
                opts = {
                  show_presets = false,
                },
                codex = function()
                  local adapter = require("codecompanion.adapters").extend("codex", {
                    commands = {
                      default = { "codex-acp" },
                    },
                    defaults = {
                      auth_method = "chatgpt",
                      mcpServers = {},
                      timeout = 20000,
                    },
                  })
                  adapter.env = {}
                  return adapter
                end,
              },
              http = {
                opts = {
                  show_presets = false,
                  show_model_choices = false,
                },
              },
            }
          '';

          interactions = {
            # ACP adapters are supported for chat; leave command/inline
            # interactions unconfigured because CodeCompanion only supports
            # HTTP adapters for those paths.
            chat = {
              adapter = "codex";
              variables = mkLuaInline "{}";
              slash_commands = mkLuaInline ''
                {
                  buffer = { enabled = false },
                  command = { enabled = false },
                  compact = { enabled = false },
                  fetch = { enabled = false },
                  file = { enabled = false },
                  help = { enabled = false },
                  image = { enabled = false },
                  mcp = { enabled = false },
                  mode = { enabled = false },
                  now = { enabled = false },
                  resume = { enabled = false },
                  rules = { enabled = false },
                  symbols = { enabled = false },
                  opts = {
                    acp = {
                      enabled = false,
                    },
                  },
                }
              '';
              tools.opts = {
                default_tools = [ ];
                system_prompt.enabled = false;
              };
            };
          };

          rules.opts = {
            chat = {
              enabled = false;
              autoload = false;
            };
            show_presets = false;
          };

          display.action_palette.opts = {
            show_default_actions = false;
            show_default_prompt_library = false;
            show_preset_actions = false;
            show_preset_prompts = false;
            show_preset_rules = false;
          };
        };
      };

      keymaps = [
        {
          key = "<leader>ac";
          mode = [ "n" ];
          action = "<cmd>CodeCompanionChat<cr>";
          desc = "AI CodeCompanion chat (Codex ACP)";
        }
      ];
    };
  };
}
