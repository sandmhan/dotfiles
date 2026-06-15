{
  lib,
  config,
  pkgs,
  ...
}:
let
  luaList = values: "{ ${lib.concatMapStringsSep ", " builtins.toJSON values} }";

  rootMarkers = [
    "flake.nix"
    ".envrc"
    "package.json"
    "pyproject.toml"
    "go.mod"
    "Cargo.toml"
    "pubspec.yaml"
    ".sqlfluff"
    "sqlfluff.toml"
    ".luarc.json"
    "stylua.toml"
    "pom.xml"
    "build.gradle"
    "settings.gradle"
    "terraform.tf"
    "tofu.tf"
    ".git"
  ];

  generatedPathPatterns = [
    "/%.git/"
    "/node_modules/"
    "/dist/"
    "/build/"
    "/target/"
    "/coverage/"
    "/%.next/"
    "/%.terraform/"
    "/result/"
    "%.lock$"
    "%.min%.js$"
    "%.generated%."
  ];
in
{
  config = lib.mkIf config.programs.sandvim.enable {
    programs.nvf.settings.vim = {
      extraPackages = [ pkgs.gitleaks ];

      diagnostics = {
        enable = true;
        config = {
          update_in_insert = false;
          severity_sort = true;
          virtual_text = {
            source = "if_many";
            spacing = 2;
          };
          float = {
            source = "if_many";
            border = "rounded";
          };
        };
      };

      keymaps = [
        {
          key = "<leader>tS";
          mode = [ "n" ];
          action = "<cmd>NvfScanSecrets<cr>";
          desc = "Task scan secrets";
        }
      ];

      luaConfigRC.workspace-hardening = {
        after = [
          "diagnostics"
          "lsp-servers"
        ];
        before = [ ];
        data = ''
          local workspace_policy = {
            root_markers = ${luaList rootMarkers},
            trust = {
              execute_local_config = false,
              local_config_files = { ".nvim.lua", ".nvimrc", ".exrc", ".envrc" },
            },
            large_file = {
              bytes = 1024 * 1024,
              lines = 20000,
              generated_path_patterns = ${luaList generatedPathPatterns},
            },
            secret_scanner = {
              command = "gitleaks",
              args = { "detect", "--no-git", "--redact", "--source" },
            },
          }

          vim.g.nvf_workspace_policy = workspace_policy
          vim.opt.exrc = false
          vim.opt.modeline = false

          local function normalize_path(path)
            return (path or ""):gsub("\\", "/")
          end

          local function workspace_root(path)
            local start = path or vim.api.nvim_buf_get_name(0)
            if start == "" then
              start = vim.uv.cwd()
            end

            local stat = start and vim.uv.fs_stat(start) or nil
            if stat and stat.type ~= "directory" then
              start = vim.fs.dirname(start)
            end

            local matches = vim.fs.find(workspace_policy.root_markers, {
              path = start,
              upward = true,
              limit = 1,
            })

            if matches[1] then
              local marker = matches[1]
              local marker_stat = vim.uv.fs_stat(marker)
              if marker_stat and marker_stat.type == "directory" then
                return marker
              end
              return vim.fs.dirname(marker)
            end

            return vim.uv.cwd()
          end

          _G.NvfWorkspaceRoot = workspace_root

          local function generated_path_reason(path)
            local normalized = normalize_path(path)
            for _, pattern in ipairs(workspace_policy.large_file.generated_path_patterns) do
              if normalized:match(pattern) then
                return "generated or dependency path matched " .. pattern
              end
            end
          end

          local function guard_reason(bufnr)
            if not vim.api.nvim_buf_is_loaded(bufnr) then
              return nil
            end

            local name = vim.api.nvim_buf_get_name(bufnr)
            if name == "" then
              return nil
            end

            local generated_reason = generated_path_reason(name)
            if generated_reason then
              return generated_reason
            end

            local stat = vim.uv.fs_stat(name)
            if stat and stat.size and stat.size > workspace_policy.large_file.bytes then
              return string.format("file is %.1f MiB", stat.size / 1024 / 1024)
            end

            local ok, line_count = pcall(vim.api.nvim_buf_line_count, bufnr)
            if ok and line_count > workspace_policy.large_file.lines then
              return string.format("file has %d lines", line_count)
            end
          end

          local function notify_guard(bufnr, reason)
            if vim.b[bufnr].nvf_workspace_guard_notified then
              return
            end
            vim.b[bufnr].nvf_workspace_guard_notified = true
            vim.notify(
              "NVF workspace guard disabled expensive editor features: " .. reason,
              vim.log.levels.WARN,
              { title = "NVF hardening" }
            )
          end

          local function apply_large_file_guard(bufnr)
            local reason = guard_reason(bufnr)
            if not reason then
              return false
            end

            vim.b[bufnr].nvf_workspace_guard = reason
            pcall(vim.diagnostic.enable, false, { bufnr = bufnr })

            if vim.treesitter then
              pcall(vim.treesitter.stop, bufnr)
            end

            for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
              pcall(vim.lsp.buf_detach_client, bufnr, client.id)
            end

            notify_guard(bufnr, reason)
            return true
          end

          local group = vim.api.nvim_create_augroup("UserNvfWorkspaceHardening", { clear = true })

          vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
            group = group,
            desc = "Disable expensive editor features for large or generated files",
            callback = function(event)
              apply_large_file_guard(event.buf)
            end,
          })

          vim.api.nvim_create_autocmd("LspAttach", {
            group = group,
            desc = "Detach language servers from guarded buffers",
            callback = function(event)
              if apply_large_file_guard(event.buf) and event.data and event.data.client_id then
                pcall(vim.lsp.buf_detach_client, event.buf, event.data.client_id)
              end
            end,
          })

          vim.api.nvim_create_user_command("NvfWorkspaceRoot", function(opts)
            local path = opts.args ~= "" and vim.fn.fnamemodify(opts.args, ":p") or nil
            vim.api.nvim_echo({ { workspace_root(path) } }, false, {})
          end, {
            nargs = "?",
            complete = "file",
            desc = "Print the NVF workspace root for the current buffer or path",
          })

          vim.api.nvim_create_user_command("NvfWorkspacePolicy", function()
            vim.notify(
              "Local Neovim config execution is disabled; run :NvfScanSecrets explicitly when needed.",
              vim.log.levels.INFO,
              { title = "NVF workspace policy" }
            )
          end, { desc = "Show the active NVF workspace trust policy" })

          local function open_secret_scan_results(lines, title)
            vim.fn.setqflist({}, " ", { title = title, lines = lines })
            vim.cmd.copen()
          end

          local function finish_secret_scan(root, result)
            local output = table.concat({ result.stdout or "", result.stderr or "" }, "\n")
            local lines = vim.split(output, "\n", { trimempty = true })

            if result.code == 0 then
              vim.notify("No secrets detected under " .. root, vim.log.levels.INFO, { title = "NVF secret scan" })
              return
            end

            if #lines == 0 then
              lines = { "gitleaks exited with status " .. tostring(result.code) }
            end

            open_secret_scan_results(lines, "NVF gitleaks secret scan")
            vim.notify("Potential secrets found under " .. root, vim.log.levels.ERROR, { title = "NVF secret scan" })
          end

          vim.api.nvim_create_user_command("NvfScanSecrets", function(opts)
            local root = opts.args ~= "" and vim.fn.fnamemodify(opts.args, ":p") or workspace_root()
            local scanner = vim.fn.exepath(workspace_policy.secret_scanner.command)

            if scanner == "" then
              vim.notify("gitleaks is not available in the Neovim wrapper", vim.log.levels.ERROR, { title = "NVF secret scan" })
              return
            end

            local cmd = vim.list_extend({ scanner }, vim.deepcopy(workspace_policy.secret_scanner.args))
            table.insert(cmd, root)

            vim.notify("Running gitleaks secret scan under " .. root, vim.log.levels.INFO, { title = "NVF secret scan" })

            if vim.system then
              vim.system(cmd, { text = true }, function(result)
                vim.schedule(function()
                  finish_secret_scan(root, result)
                end)
              end)
            else
              local lines = vim.fn.systemlist(cmd)
              finish_secret_scan(root, {
                code = vim.v.shell_error,
                stdout = table.concat(lines, "\n"),
                stderr = "",
              })
            end
          end, {
            nargs = "?",
            complete = "dir",
            desc = "Run gitleaks against the current NVF workspace root or a supplied directory",
          })
        '';
      };
    };

  };
}
