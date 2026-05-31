{
  pkgs,
  lib,
  ...
}:
{
  programs.nvf = {
    settings.vim = {
      languages.python = {
        enable = true;
        treesitter.enable = true;

        lsp = {
          enable = true;
          servers = [
            "basedpyright"
            "ruff"
          ];
        };

        format = {
          enable = true;
          type = [ "ruff" ];
        };

        # Ruff owns Python linting for editor/CI parity; pytest remains project-local
        # and is documented in docs/neovim-ide.md rather than wired to Phase 3 keys.
        extraDiagnostics.enable = false;

        dap = {
          enable = true;
          debugger = "debugpy";
        };
      };

      diagnostics.nvim-lint = {
        enable = true;
        linters_by_ft.python = [ "ruff" ];
        linters.ruff = {
          # Keep upstream nvim-lint Ruff defaults for stdin-filename,
          # force-exclude, parser, and stdin behavior while pinning the binary.
          cmd = lib.getExe pkgs.ruff;
        };
      };
    };
  };
}
