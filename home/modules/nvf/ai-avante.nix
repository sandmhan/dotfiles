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
  config = lib.mkIf cfg.enableNvfAiAvante {
    programs.nvf.settings.vim = {
      assistant.avante-nvim = {
        enable = true;
        setupOpts = {
          provider = "openai_compatible";
          providers.openai_compatible = mkLuaInline ''
            function()
              return {
                __inherited_from = "openai",
                api_key_name = "OPENAI_API_KEY",
                endpoint = os.getenv("OPENAI_BASE_URL") or "https://api.openai.com/v1",
                model = os.getenv("OPENAI_MODEL") or "gpt-4o-mini",
                timeout = 30000,
                disable_tools = true,
                extra_request_body = {
                  temperature = 0,
                  max_completion_tokens = 8192,
                  reasoning_effort = "medium",
                },
              }
            end
          '';

          behaviour = {
            auto_set_keymaps = false;
            auto_suggestions = false;
            auto_apply_diff_after_generation = false;
            auto_add_current_file = false;
            auto_approve_tool_permissions = false;
            auto_check_diagnostics = false;
            auto_focus_on_diff_view = false;
            acp_follow_agent_locations = false;
            enable_cursor_planning_mode = false;
            enable_claude_text_editor_tool_mode = false;
          };

          hints.enabled = false;
          prompt_logger.enabled = false;
          custom_tools = mkLuaInline "{}";
          slash_commands = mkLuaInline "{}";
          disabled_tools = mkLuaInline "{}";
        };
      };

      keymaps = [
        {
          key = "<leader>ac";
          mode = [ "n" ];
          action = "<cmd>AvanteAsk<cr>";
          desc = "AI Avante ask (OpenAI-compatible plugin)";
        }
        {
          key = "<leader>ae";
          mode = [ "x" ];
          action = ":AvanteEdit Edit only the selected code. Propose the smallest viable diff, preserve surrounding behavior, and explain assumptions.<cr>";
          desc = "AI Avante edit selected code";
        }
        {
          key = "<leader>aR";
          mode = [ "x" ];
          action = "<cmd>AvanteAsk Review the selected code for correctness, safety, tests, and documentation drift. Do not infer unseen repository context; ask for missing context instead.<cr>";
          desc = "AI Avante review selected code";
        }
        {
          key = "<leader>aT";
          mode = [ "x" ];
          action = "<cmd>AvanteAsk Generate tests for the selected code only. Ask for missing test runner or fixture details instead of assuming them.<cr>";
          desc = "AI Avante tests for selected code";
        }
      ];
    };
  };
}
