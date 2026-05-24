{ pkgs, ... }:
let
  # Keep TidalCycles usable outside a project devshell: :TidalLaunch prefers
  # tidal-ghci from PATH, then falls back to this bundled ghci.
  tidalGhc = pkgs.haskellPackages.ghcWithPackages (haskellPackages: [
    haskellPackages.tidal
  ]);
in
{
  programs.nvf.settings.vim = {
    languages.haskell = {
      enable = true;
      treesitter.enable = true;
      lsp = {
        enable = true;
        servers = [ "hls" ];
      };
    };

    luaConfigRC.disable-tidal-hls-autoattach = {
      after = [ "haskell-tools-nvim" ];
      before = [ ];
      data = ''
        vim.g.haskell_tools = vim.g.haskell_tools or {}
        vim.g.haskell_tools.hls = vim.g.haskell_tools.hls or {}

        vim.g.haskell_tools.hls.auto_attach = function()
          local name = vim.api.nvim_buf_get_name(0)
          return not name:match("%.tidal$")
        end
      '';
    };

    extraPlugins.tidal-nvim = {
      package = pkgs.vimUtils.buildVimPlugin {
        pname = "tidal.nvim";
        version = "unstable-2026-05-23";
        src = pkgs.fetchFromGitHub {
          owner = "grddavies";
          repo = "tidal.nvim";
          rev = "fa4673e181e18fd1719ae17a1d4f4ecce2de37aa";
          hash = "sha256-sbxBIybZdQptiD3zDJtitOcuy5bZSwgf9EPpMlik8Ds=";
        };
      };
      setup = ''
        local tidal = require("tidal")
        local tidal_ghci = vim.fn.exepath("tidal-ghci")

        if tidal_ghci == "" then
          tidal_ghci = "${tidalGhc}/bin/ghci"
        end

        tidal.setup({
          boot = {
            tidal = {
              -- Prefer a project/devshell-provided tidal-ghci when available,
              -- then use the bundled fallback for standalone Tidal sessions.
              cmd = tidal_ghci,
              args = { "-v0" },
            },
          },
          -- Keep Tidal workflow mappings explicit and buffer-local below.
          mappings = false,
        })

        local api = tidal.api
        local config = require("tidal.config")
        local message = require("tidal.core.message")
        local state = require("tidal.core.state")

        local function launch_tidal()
          api.launch_tidal(config.options.boot)
        end

        local function toggle_tidal()
          if state.launched then
            api.exit_tidal()
          else
            launch_tidal()
          end
        end

        local function restart_tidal()
          if state.launched then
            api.exit_tidal()
          end
          launch_tidal()
        end

        local function hush_tidal()
          message.tidal.send_line("hush")
        end

        local function starts_tidal_statement(line)
          -- Treat unindented identifier-like lines as new Tidal/Haskell
          -- statements. Continuation lines for patterns commonly start with
          -- whitespace or operators such as #, $, |+|, or |*|.
          return line:match("^[%a_]") ~= nil
        end

        local function send_visual_tidal_blocks()
          local cursor_line = vim.fn.line(".")
          local visual_line = vim.fn.line("v")
          local start_line = math.min(cursor_line, visual_line)
          local end_line = math.max(cursor_line, visual_line)
          local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

          if #lines == 0 then
            return
          end

          require("tidal.core.highlight").apply_highlight(
            { start_line - 1, 0 },
            { end_line - 1, #lines[#lines] }
          )

          local block = {}
          local function flush_block()
            if #block > 0 then
              api.send_multiline(block)
              block = {}
            end
          end

          for _, line in ipairs(lines) do
            if line:match("^%s*$") then
              flush_block()
            else
              if #block > 0 and starts_tidal_statement(line) then
                flush_block()
              end
              table.insert(block, line)
            end
          end
          flush_block()
        end

        local function map_tidal_keys(event)
          if vim.b[event.buf].user_tidal_keymaps_set then
            return
          end
          vim.b[event.buf].user_tidal_keymaps_set = true

          local opts = function(desc)
            return { buffer = event.buf, desc = desc, silent = true }
          end

          vim.keymap.set({ "i", "n" }, "<S-CR>", api.send_line, opts("Tidal: send current line"))
          vim.keymap.set({ "i", "n", "x" }, "<M-CR>", api.send_block, opts("Tidal: send current block"))
          vim.keymap.set("x", "<S-CR>", send_visual_tidal_blocks, opts("Tidal: send visual selection"))

          vim.keymap.set("n", "<leader>tl", api.send_line, opts("Tidal: send current line"))
          vim.keymap.set("n", "<leader>tb", api.send_block, opts("Tidal: send current block"))
          vim.keymap.set("n", "<leader>tn", api.send_node, opts("Tidal: send Treesitter node"))
          vim.keymap.set("x", "<leader>tv", send_visual_tidal_blocks, opts("Tidal: send visual selection"))
          vim.keymap.set("n", "<leader>ts", api.send_silence, opts("Tidal: send d{count} silence"))
          vim.keymap.set("n", "<leader>th", hush_tidal, opts("Tidal: hush all patterns"))
          vim.keymap.set("n", "<leader>to", launch_tidal, opts("Tidal: open REPL"))
          vim.keymap.set("n", "<leader>tq", api.exit_tidal, opts("Tidal: quit REPL"))
          vim.keymap.set("n", "<leader>tt", toggle_tidal, opts("Tidal: toggle REPL"))
          vim.keymap.set("n", "<leader>tr", restart_tidal, opts("Tidal: restart REPL"))
        end

        local tidal_filetype = vim.api.nvim_create_augroup("UserTidalFiletype", { clear = true })
        vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
          group = tidal_filetype,
          pattern = "*.tidal",
          callback = function(event)
            if vim.bo[event.buf].filetype == "" then
              vim.bo[event.buf].filetype = "tidal"
            end
          end,
        })

        local tidal_keymaps = vim.api.nvim_create_augroup("UserTidalKeymaps", { clear = true })
        vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile", "BufEnter" }, {
          group = tidal_keymaps,
          pattern = "*.tidal",
          -- Scope live-coding maps to *.tidal buffers by path rather than final
          -- filetype: tidal.nvim resets these buffers to haskell on enter.
          callback = map_tidal_keys,
        })
      '';
    };
  };
}
