{
  lib,
  ...
}:
let
  luaList = values: "{ ${lib.concatMapStringsSep ", " builtins.toJSON values} }";

  providers = [
    {
      id = "claude";
      label = "Claude Code";
      command = "claude";
      args = [ "-p" ];
      promptMode = "stdin";
    }
    {
      id = "codex";
      label = "Codex CLI";
      command = "codex";
      args = [ "exec" ];
      promptMode = "stdin";
    }
    {
      id = "pi";
      label = "Pi coding agent";
      command = "pi";
      args = [ "-p" ];
      promptMode = "argv";
    }
  ];

  providerLua =
    "{\n"
    + lib.concatMapStringsSep ",\n" (provider: ''
      {
        id = ${builtins.toJSON provider.id},
        label = ${builtins.toJSON provider.label},
        command = ${builtins.toJSON provider.command},
        args = ${luaList provider.args},
        prompt_mode = ${builtins.toJSON provider.promptMode},
      }'') providers
    + "\n}";

  blockedPathPatterns = [
    "/secrets/"
    "^secrets/"
    "[ab]/secrets/"
    "%.env"
    "%.pem$"
    "%.key$"
    "id_rsa"
    "id_ed25519"
  ];

  blockContentPatterns = [
    "BEGIN [A-Z ]*PRIVATE KEY"
    "BEGIN OPENSSH PRIVATE KEY"
    "age%-encryption%.org/v1"
    "^%s*[+%-]?%s*sops:"
  ];
in
{
  programs.nvf.settings.vim = {
    keymaps = [
      {
        key = "<leader>aa";
        mode = [ "n" ];
        action = "<cmd>NvfAiAsk<cr>";
        desc = "AI ask selected/small prompt (guarded provider)";
      }
      {
        key = "<leader>aa";
        mode = [ "x" ];
        action = ":'<,'>NvfAiAsk<cr>";
        desc = "AI ask selected/small prompt (guarded provider)";
      }
      {
        key = "<leader>ar";
        mode = [ "n" ];
        action = "<cmd>NvfAiReviewDiff<cr>";
        desc = "AI review git diff (confirm + redact)";
      }
      {
        key = "<leader>at";
        mode = [ "n" ];
        action = "<cmd>NvfAiTests<cr>";
        desc = "AI generate tests (guarded provider)";
      }
      {
        key = "<leader>at";
        mode = [ "x" ];
        action = ":'<,'>NvfAiTests<cr>";
        desc = "AI generate tests for selection (guarded provider)";
      }
      {
        key = "<leader>ad";
        mode = [ "n" ];
        action = "<cmd>NvfAiDiagnostic<cr>";
        desc = "AI explain diagnostic (guarded provider)";
      }
      {
        key = "<leader>as";
        mode = [ "n" ];
        action = "<cmd>NvfAiSkills<cr>";
        desc = "AI pick shared skill/prompt (guarded provider)";
      }
    ];

    luaConfigRC.ai-bridge = {
      after = [ "workspace-hardening" ];
      before = [ ];
      data = ''
        local ai_policy = {
          providers = ${providerLua},
          max_context_chars = 12000,
          max_prompt_chars = 6000,
          blocked_path_patterns = ${luaList blockedPathPatterns},
          block_content_patterns = ${luaList blockContentPatterns},
        }

        vim.g.nvf_ai_bridge_policy = ai_policy

        local function notify(message, level)
          vim.notify(message, level or vim.log.levels.INFO, { title = "NVF AI bridge" })
        end

        local function workspace_root()
          if _G.NvfWorkspaceRoot then
            return _G.NvfWorkspaceRoot()
          end
          return vim.uv.cwd()
        end

        local function normalize_path(path)
          return (path or ""):gsub("\\", "/")
        end

        local function format_size(text)
          local bytes = #(text or "")
          return string.format("%d chars / %.1f KiB", bytes, bytes / 1024)
        end

        local function copy_table(value)
          return vim.deepcopy(value or {})
        end

        local function is_blocked_path(path)
          local normalized = normalize_path(path)
          for _, pattern in ipairs(ai_policy.blocked_path_patterns) do
            if normalized:match(pattern) then
              return pattern
            end
          end
        end

        local function blocked_content_pattern(text)
          for _, pattern in ipairs(ai_policy.block_content_patterns) do
            if text:match(pattern) then
              return pattern
            end

            for line in (text .. "\n"):gmatch("([^\n]*)\n") do
              if line:match(pattern) then
                return pattern
              end
            end
          end
        end

        local secret_key_patterns = {
          "password",
          "token",
          "secret",
          "api[_%-]*key",
          "private[_%-]*key",
        }

        local function find_secret_assignment(line, offset)
          local lower = line:lower()
          local best = nil

          for _, pattern in ipairs(secret_key_patterns) do
            local search_from = offset
            while search_from <= #lower do
              local start_pos, end_pos = lower:find(pattern, search_from)
              if not start_pos then
                break
              end

              local after = line:sub(end_pos + 1)
              local _, rel_delimiter_end = after:find("^%s*['\"]?%s*[:=]%s*")

              if rel_delimiter_end then
                if not best or start_pos < best.key_start then
                  best = {
                    key_start = start_pos,
                    key_end = end_pos,
                    delimiter_end = end_pos + rel_delimiter_end,
                  }
                end
                break
              end

              search_from = end_pos + 1
            end
          end

          return best
        end

        local function find_quoted_value_end(line, value_start, quote)
          local index = value_start + 1
          while index <= #line do
            local char = line:sub(index, index)
            if char == "\\" then
              index = index + 2
            elseif char == quote then
              return index
            else
              index = index + 1
            end
          end
        end

        local function redact_secret_assignment(line, offset)
          local assignment = find_secret_assignment(line, offset)
          if not assignment then
            return line, false, offset
          end

          local replacement = "[REDACTED]"
          local value_start = assignment.delimiter_end + 1
          local quote = line:sub(value_start, value_start)
          if quote == "\"" or quote == "'" then
            local value_end = find_quoted_value_end(line, value_start, quote)
            if value_end then
              local redacted = line:sub(1, value_start) .. replacement .. line:sub(value_end)
              return redacted, true, value_start + #replacement + 2
            end

            local redacted = line:sub(1, value_start) .. replacement
            return redacted, true, #redacted + 1
          end

          local value_end = line:find("[%s,}]", value_start) or (#line + 1)
          local redacted = line:sub(1, value_start - 1) .. replacement .. line:sub(value_end)
          return redacted, true, value_start + #replacement
        end

        local function redact_secret_assignments(line)
          local redacted = line
          local changed = false
          local offset = 1
          local iterations = 0

          while offset <= #redacted do
            local next_redacted, replaced, next_offset = redact_secret_assignment(redacted, offset)
            if not replaced then
              break
            end

            redacted = next_redacted
            changed = true
            iterations = iterations + 1
            if iterations >= 100 then
              break
            end

            if next_offset <= offset then
              offset = offset + 1
            else
              offset = next_offset
            end
          end

          return redacted, changed
        end

        local function redact_line(line)
          local redacted, changed = redact_secret_assignments(line)

          redacted = redacted:gsub("AKIA[0-9A-Z]+", "[REDACTED-AWS-KEY]")
          redacted = redacted:gsub("gh[pousr]_[A-Za-z0-9_]+", "[REDACTED-GITHUB-TOKEN]")
          redacted = redacted:gsub("xox[baprs]%-[A-Za-z0-9%-]+", "[REDACTED-SLACK-TOKEN]")
          redacted = redacted:gsub("[Bb]earer%s+[A-Za-z0-9%._%-%+/=]+", "Bearer [REDACTED]")

          if redacted ~= line then
            changed = true
          end

          return redacted, changed
        end

        local function sanitize_context(request)
          local text = request.context or ""
          if text == "" then
            return nil, "No AI context was provided."
          end

          local path_pattern = is_blocked_path(request.path)
          if path_pattern then
            return nil, "Refusing AI context from sensitive path matching " .. path_pattern
          end

          local content_pattern = blocked_content_pattern(text)
          if content_pattern then
            return nil, "Refusing AI context containing blocked secret marker " .. content_pattern
          end

          for line in (text .. "\n"):gmatch("([^\n]*)\n") do
            local line_path_pattern = is_blocked_path(line)
            if line_path_pattern then
              return nil, "Refusing AI context referencing sensitive path matching " .. line_path_pattern
            end
          end

          local lines = {}
          local redactions = 0
          for line in (text .. "\n"):gmatch("([^\n]*)\n") do
            local redacted, changed = redact_line(line)
            if changed then
              redactions = redactions + 1
            end
            table.insert(lines, redacted)
          end

          local sanitized = table.concat(lines, "\n")
          if #sanitized > (request.max_chars or ai_policy.max_context_chars) then
            return nil, string.format(
              "Refusing AI context over safe size limit (%s > %d chars). Select a smaller scope.",
              format_size(sanitized),
              request.max_chars or ai_policy.max_context_chars
            )
          end

          return sanitized, nil, { redactions = redactions }
        end

        local function provider_by_id(id)
          for _, provider in ipairs(ai_policy.providers) do
            if provider.id == id then
              return provider
            end
          end
        end

        local function available_providers()
          local available = {}
          for _, provider in ipairs(ai_policy.providers) do
            local exe = vim.fn.exepath(provider.command)
            if exe ~= "" then
              local copy = copy_table(provider)
              copy.exe = exe
              table.insert(available, copy)
            end
          end
          return available
        end

        local function choose_provider(preferred, callback)
          if preferred and preferred ~= "" then
            local provider = provider_by_id(preferred)
            if not provider then
              notify("Unknown AI provider: " .. preferred, vim.log.levels.ERROR)
              return
            end

            local exe = vim.fn.exepath(provider.command)
            if exe == "" then
              notify(provider.label .. " CLI is not available in PATH; AI action was not sent.", vim.log.levels.ERROR)
              return
            end

            local copy = copy_table(provider)
            copy.exe = exe
            callback(copy)
            return
          end

          local providers = available_providers()
          if #providers == 0 then
            notify("No supported AI provider CLI found. Expected one of: claude, codex, pi.", vim.log.levels.ERROR)
            return
          end

          if #providers == 1 then
            callback(providers[1])
            return
          end

          vim.ui.select(providers, {
            prompt = "NVF AI provider",
            format_item = function(provider)
              return provider.label .. " (" .. provider.command .. ")"
            end,
          }, function(provider)
            if provider then
              callback(provider)
            end
          end)
        end

        local function open_result_buffer(provider, request, result)
          local lines = {
            "# NVF AI result",
            "",
            "Provider: " .. provider.label,
            "Action: " .. request.action_label,
            "Scope: " .. request.scope,
            "Exit code: " .. tostring(result.code),
            "",
            "## stdout",
            "",
          }

          vim.list_extend(lines, vim.split(result.stdout or "", "\n", { plain = true }))
          vim.list_extend(lines, { "", "## stderr", "" })
          vim.list_extend(lines, vim.split(result.stderr or "", "\n", { plain = true }))

          local bufnr = vim.api.nvim_create_buf(false, true)
          vim.api.nvim_buf_set_name(bufnr, "NVF AI " .. provider.id .. " " .. request.action .. " " .. tostring(vim.uv.hrtime()))
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
          vim.bo[bufnr].buftype = "nofile"
          vim.bo[bufnr].bufhidden = "wipe"
          vim.bo[bufnr].filetype = "markdown"
          vim.bo[bufnr].modifiable = false
          vim.cmd("botright split")
          vim.api.nvim_win_set_buf(0, bufnr)
        end

        local function prompt_for_provider(provider, request)
          return table.concat({
            "NVF guarded AI bridge request",
            "Provider: " .. provider.label,
            "Action: " .. request.action_label,
            "Scope: " .. request.scope,
            "Workspace root: " .. request.root,
            "Guardrails: context was size-checked, sensitive paths were blocked, secret-like values were redacted, and full buffers are not collected automatically.",
            "",
            "User request:",
            request.instructions,
            "",
            "Context:",
            "```",
            request.context,
            "```",
          }, "\n")
        end

        local function build_provider_invocation(provider, prompt, cwd)
          local command = { provider.exe or provider.command }
          vim.list_extend(command, copy_table(provider.args))

          local system_opts = {
            text = true,
            cwd = cwd,
          }

          if provider.prompt_mode == "argv" then
            table.insert(command, prompt)
          else
            system_opts.stdin = prompt
          end

          return command, system_opts
        end

        local function confirm_and_invoke(provider, request)
          local prompt = prompt_for_provider(provider, request)
          local command, system_opts = build_provider_invocation(provider, prompt, request.root)

          local confirmation = table.concat({
            "Send guarded AI request?",
            "",
            "Provider: " .. provider.label .. " (" .. provider.command .. ")",
            "Action: " .. request.action_label,
            "Scope: " .. request.scope,
            "Context size: " .. format_size(request.context),
            "Redactions: " .. tostring(request.redactions or 0),
            "Workspace: " .. request.root,
            "",
            "No full buffer was collected automatically. Continue?",
          }, "\n")

          if vim.fn.confirm(confirmation, "&Send\n&Cancel", 2) ~= 1 then
            notify("AI request cancelled before provider invocation.")
            return
          end

          if not vim.system then
            notify("vim.system is unavailable; AI request was not sent.", vim.log.levels.ERROR)
            return
          end

          notify("Sending " .. request.action_label .. " request to " .. provider.label .. " (" .. format_size(request.context) .. ").")
          vim.system(command, system_opts, function(result)
            vim.schedule(function()
              local level = result.code == 0 and vim.log.levels.INFO or vim.log.levels.WARN
              notify(provider.label .. " completed with exit code " .. tostring(result.code) .. ".", level)
              open_result_buffer(provider, request, result)
            end)
          end)
        end

        local function dispatch(request, preferred_provider)
          request.root = request.root or workspace_root()
          local sanitized, reason, meta = sanitize_context(request)
          if not sanitized then
            notify(reason, vim.log.levels.ERROR)
            return
          end

          request.context = sanitized
          request.redactions = meta and meta.redactions or 0

          choose_provider(preferred_provider, function(provider)
            confirm_and_invoke(provider, request)
          end)
        end

        local function get_range_context(line1, line2)
          local bufnr = vim.api.nvim_get_current_buf()
          local total = vim.api.nvim_buf_line_count(bufnr)
          if line1 <= 1 and line2 >= total then
            return nil, "Full-buffer selection is blocked. Select a smaller range before invoking AI."
          end

          local lines = vim.api.nvim_buf_get_lines(bufnr, line1 - 1, line2, false)
          if #lines == 0 then
            return nil, "Selection is empty."
          end

          return table.concat(lines, "\n")
        end

        _G.NvfAiBridgeTest = {
          sanitize_context = sanitize_context,
          redact_line = redact_line,
          is_blocked_path = is_blocked_path,
          blocked_content_pattern = blocked_content_pattern,
          build_provider_invocation = build_provider_invocation,
          get_range_context = get_range_context,
          provider_by_id = provider_by_id,
        }

        local function dispatch_range_or_prompt(opts, action, action_label, instructions, prompt_message)
          local provider = opts.args ~= "" and opts.args or nil
          local line1 = opts.line1 or 0
          local line2 = opts.line2 or 0

          if (opts.range or 0) > 0 then
            local context, reason = get_range_context(line1, line2)
            if not context then
              notify(reason, vim.log.levels.ERROR)
              return
            end

            dispatch({
              action = action,
              action_label = action_label,
              instructions = instructions,
              scope = string.format("selected lines %d-%d", line1, line2),
              context = context,
              path = vim.api.nvim_buf_get_name(0),
              max_chars = ai_policy.max_prompt_chars,
            }, provider)
            return
          end

          vim.ui.input({ prompt = prompt_message }, function(input)
            if not input or input == "" then
              return
            end

            dispatch({
              action = action,
              action_label = action_label,
              instructions = instructions,
              scope = "typed prompt only",
              context = input,
              max_chars = ai_policy.max_prompt_chars,
            }, provider)
          end)
        end

        vim.api.nvim_create_user_command("NvfAiAsk", function(opts)
          dispatch_range_or_prompt(
            opts,
            "ask",
            "Ask",
            "Answer the user's question using only the scoped context. If more context is required, ask for it explicitly instead of assuming full-buffer access.",
            "NVF AI ask (small prompt): "
          )
        end, {
          nargs = "?",
          range = true,
          desc = "Ask an AI provider about a small prompt or selected text after redaction and confirmation",
        })

        vim.api.nvim_create_user_command("NvfAiTests", function(opts)
          dispatch_range_or_prompt(
            opts,
            "tests",
            "Generate or improve tests",
            "Suggest focused test cases or test improvements. Do not rewrite unrelated code, and call out assumptions about the project test runner.",
            "NVF AI tests prompt (module/function to test): "
          )
        end, {
          nargs = "?",
          range = true,
          desc = "Generate or improve tests from a small prompt or selected code after redaction and confirmation",
        })

        vim.api.nvim_create_user_command("NvfAiDiagnostic", function(opts)
          local provider = opts.args ~= "" and opts.args or nil
          local bufnr = vim.api.nvim_get_current_buf()
          local row = vim.api.nvim_win_get_cursor(0)[1] - 1
          local diagnostics = vim.diagnostic.get(bufnr, { lnum = row })
          if #diagnostics == 0 then
            notify("No diagnostic under the current cursor line.", vim.log.levels.WARN)
            return
          end

          local diagnostic = diagnostics[1]
          local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
          local severity = vim.diagnostic.severity[diagnostic.severity] or tostring(diagnostic.severity)
          local context = table.concat({
            "File: " .. vim.api.nvim_buf_get_name(bufnr),
            "Line: " .. tostring(row + 1),
            "Severity: " .. severity,
            "Source: " .. tostring(diagnostic.source or "unknown"),
            "Code: " .. tostring(diagnostic.code or "none"),
            "Message: " .. tostring(diagnostic.message or ""),
            "Current line: " .. line,
          }, "\n")

          dispatch({
            action = "diagnostic",
            action_label = "Explain diagnostic under cursor",
            instructions = "Explain the diagnostic, likely root cause, and a minimal safe fix. Do not request or expose secrets.",
            scope = "current diagnostic under cursor",
            context = context,
            path = vim.api.nvim_buf_get_name(bufnr),
            max_chars = ai_policy.max_prompt_chars,
          }, provider)
        end, {
          nargs = "?",
          desc = "Explain the current diagnostic after redaction and confirmation",
        })

        vim.api.nvim_create_user_command("NvfAiReviewDiff", function(opts)
          local provider = opts.args ~= "" and opts.args or nil
          local git = vim.fn.exepath("git")
          if git == "" then
            notify("git is not available; diff review was not sent.", vim.log.levels.ERROR)
            return
          end

          local root = workspace_root()
          if not vim.system then
            notify("vim.system is unavailable; diff review was not sent.", vim.log.levels.ERROR)
            return
          end

          vim.system({ git, "-C", root, "diff", "--no-ext-diff", "--" }, { text = true }, function(result)
            vim.schedule(function()
              if result.code ~= 0 then
                notify("git diff failed: " .. (result.stderr or "unknown error"), vim.log.levels.ERROR)
                return
              end

              if result.stdout == nil or result.stdout == "" then
                notify("No current git diff to review.", vim.log.levels.INFO)
                return
              end

              dispatch({
                action = "review-diff",
                action_label = "Review current git diff",
                instructions = "Review the current git diff for correctness, safety, test gaps, and documentation drift. Do not ask for full files unless required.",
                scope = "current git diff from workspace root",
                context = result.stdout,
                root = root,
                max_chars = ai_policy.max_context_chars,
              }, provider)
            end)
          end)
        end, {
          nargs = "?",
          desc = "Review current git diff after redaction and explicit confirmation",
        })

        local function discover_shared_prompts()
          local root = vim.env.AI_SKILLS_DIR or vim.fn.expand("~/.local/share/ai")
          local choices = {}

          local skill_files = vim.fn.globpath(root .. "/skills", "*/SKILL.md", false, true)
          for _, path in ipairs(skill_files) do
            table.insert(choices, {
              kind = "skill",
              name = vim.fn.fnamemodify(vim.fn.fnamemodify(path, ":h"), ":t"),
              path = path,
            })
          end

          local rule_files = vim.fn.globpath(root .. "/rules", "*.md", false, true)
          for _, path in ipairs(rule_files) do
            table.insert(choices, {
              kind = "rule",
              name = vim.fn.fnamemodify(path, ":t:r"),
              path = path,
            })
          end

          table.sort(choices, function(a, b)
            return (a.kind .. a.name) < (b.kind .. b.name)
          end)

          return choices, root
        end

        vim.api.nvim_create_user_command("NvfAiSkills", function(opts)
          local provider = opts.args ~= "" and opts.args or nil
          local choices, root = discover_shared_prompts()
          if #choices == 0 then
            notify("No shared AI skills or rules found under " .. root .. ".", vim.log.levels.WARN)
            return
          end

          vim.ui.select(choices, {
            prompt = "NVF AI shared skill/prompt",
            format_item = function(choice)
              return choice.kind .. ": " .. choice.name
            end,
          }, function(choice)
            if not choice then
              return
            end

            local lines = vim.fn.readfile(choice.path)
            local content = table.concat(lines, "\n")
            if #content > ai_policy.max_prompt_chars then
              content = content:sub(1, ai_policy.max_prompt_chars)
                .. "\n\n[TRUNCATED by NVF AI bridge: prompt exceeded safe context limit.]"
            end

            dispatch({
              action = "skill",
              action_label = "Pick shared skill/prompt",
              instructions = "Use this shared skill or rule as guidance. Summarize how it applies and ask for a scoped follow-up before making changes.",
              scope = choice.kind .. " " .. choice.name,
              context = content,
              path = choice.path,
              max_chars = ai_policy.max_context_chars,
            }, provider)
          end)
        end, {
          nargs = "?",
          desc = "Pick a shared AI skill or prompt after redaction and confirmation",
        })
      '';
    };
  };
}
