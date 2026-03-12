{
  lib,
  pkgs,
  ...
}:
{
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
          nil_ls.enable = true;

          # Typst
          tinymist.enable = true;

          # Markdown
          marksman.enable = true;
        };

        # Spellchecking
        harper-ls = {
          enable = true;
        };
      };
    };
  };
}
