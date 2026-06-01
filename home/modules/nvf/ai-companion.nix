{
  lib,
  config,
  ...
}:
let
  cfg = config.myHome.features;
  inherit (lib.generators) mkLuaInline;
in
{
  config = lib.mkIf cfg.enableNvfAiCompanion {
    programs.nvf.settings.vim = {
      assistant.codecompanion-nvim = {
        enable = true;
        setupOpts = {
          opts = {
            log_level = "ERROR";
            language = "English";
            send_code = true;
          };

          display = {
            diff = {
              enabled = true;
              provider = "inline";
              layout = "vertical";
            };

            inline.layout = "vertical";

            chat = {
              show_settings = true;
              show_references = true;
              show_token_count = true;
              intro_message = "CodeCompanion is enabled for explicit selected-code chat/edit workflows. Use the guarded NVF AI bridge for sensitive prompts.";
            };

            action_palette.opts = {
              show_default_actions = true;
              show_default_prompt_library = false;
            };
          };

          adapters = mkLuaInline ''
            {
              openai_compatible = function()
                return require("codecompanion.adapters").extend("openai_compatible", {
                  name = "openai_compatible",
                  env = {
                    api_key = "OPENAI_API_KEY",
                    url = "OPENAI_BASE_URL",
                  },
                  schema = {
                    model = {
                      default = os.getenv("OPENAI_MODEL") or "gpt-4o-mini",
                    },
                  },
                })
              end,
            }
          '';

          interactions = {
            chat = {
              adapter = "openai_compatible";
              variables = mkLuaInline "{}";
              slash_commands = mkLuaInline "{}";
              tools = { };
            };
            inline = {
              adapter = "openai_compatible";
              variables = mkLuaInline "{}";
            };
          };

          prompt_library = {
            "Review selected code" = {
              strategy = "chat";
              description = "Review only the selected code for correctness, safety, tests, and docs drift.";
              opts = {
                modes = [ "v" ];
                short_name = "review_selected";
                auto_submit = true;
                stop_context_insertion = true;
              };
              prompts = [
                {
                  role = "user";
                  content = "Review the selected code for correctness, safety, tests, and documentation drift. Do not infer unseen repository context; ask for missing context instead.";
                  opts.contains_code = true;
                }
              ];
            };

            "Edit selected code" = {
              strategy = "inline";
              description = "Propose a minimal edit for the selected code and explain assumptions.";
              opts = {
                modes = [ "v" ];
                short_name = "edit_selected";
                auto_submit = true;
                stop_context_insertion = true;
              };
              prompts = [
                {
                  role = "user";
                  content = "Edit only the selected code. Propose the smallest viable diff, preserve surrounding behavior, and explain assumptions.";
                  opts.contains_code = true;
                }
              ];
            };

            "Generate tests for selected code" = {
              strategy = "chat";
              description = "Suggest tests for only the selected code and ask for runner details when unknown.";
              opts = {
                modes = [ "v" ];
                short_name = "tests_selected";
                auto_submit = true;
                stop_context_insertion = true;
              };
              prompts = [
                {
                  role = "user";
                  content = "Generate tests for the selected code only. Ask for missing test runner or fixture details instead of assuming them.";
                  opts.contains_code = true;
                }
              ];
            };

            "Explain selected code" = {
              strategy = "chat";
              description = "Explain behavior and edge cases for only the selected code.";
              opts = {
                modes = [ "v" ];
                short_name = "explain_selected";
                auto_submit = true;
                stop_context_insertion = true;
              };
              prompts = [
                {
                  role = "user";
                  content = "Explain the selected code, including behavior, edge cases, and any assumptions. Do not infer unseen repository context.";
                  opts.contains_code = true;
                }
              ];
            };
          };
        };
      };

      keymaps = [
        {
          key = "<leader>ac";
          mode = [ "n" ];
          action = "<cmd>CodeCompanionChat<cr>";
          desc = "AI CodeCompanion chat (OpenAI-compatible plugin)";
        }
        {
          key = "<leader>aA";
          mode = [ "n" ];
          action = "<cmd>CodeCompanionActions<cr>";
          desc = "AI CodeCompanion actions and curated prompts";
        }
        {
          key = "<leader>ae";
          mode = [ "x" ];
          action = ":'<,'>CodeCompanion Edit the selected code. Propose a minimal diff and explain assumptions.<cr>";
          desc = "AI CodeCompanion edit selected code";
        }
        {
          key = "<leader>aR";
          mode = [ "x" ];
          action = ":'<,'>CodeCompanion Review the selected code for correctness, safety, tests, and docs drift. Do not infer unseen repository context.<cr>";
          desc = "AI CodeCompanion review selected code";
        }
        {
          key = "<leader>aT";
          mode = [ "x" ];
          action = ":'<,'>CodeCompanion Generate tests for the selected code. Ask for missing runner details instead of assuming them.<cr>";
          desc = "AI CodeCompanion tests for selected code";
        }
      ];
    };
  };
}
