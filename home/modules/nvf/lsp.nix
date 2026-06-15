{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.programs.sandvim.enable {
    programs.nvf = {
      settings.vim = {
        lsp = {
          enable = true;
          inlayHints.enable = true;
          servers = {
            # CPP
            clangd.enable = true;

            # Nix
            nixd.enable = true;
            nil_ls.enable = false;

            # Typst
            tinymist.enable = true;

            # Markdown/Obsidian notes
            marksman.enable = false;
            markdown-oxide.enable = true;
          };

          # Spellchecking
          harper-ls = {
            enable = true;
          };
        };
      };
    };

  };
}
