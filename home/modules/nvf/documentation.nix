{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.programs.sandvim;
  markdownlintConfig = pkgs.writeText "sandvim-markdownlint-cli2.yaml" ''
    config:
      MD025:
        # Obsidian notes commonly use both a frontmatter title and one H1.
        front_matter_title: ""
  '';
in
{
  config = lib.mkIf (cfg.enable && cfg.packs.languages.documentation) {
    programs.nvf.settings.vim = {
      diagnostics.nvim-lint.linters."markdownlint-cli2".args = [
        "--config"
        "${markdownlintConfig}"
        "-"
      ];

      languages = {
        enableFormat = true;
        enableTreesitter = true;
        enableExtraDiagnostics = true;

        markdown = {
          enable = true;
          treesitter.enable = true;
          format = {
            enable = true;
            type = [ "mdformat" ];
          };
          # markdownlint-cli2 owns structural lint; Harper owns prose via lsp.nix.
          # markdown-oxide owns document/link LSP; obsidian-ls owns note-aware completion/navigation via notes.nix.
          extraDiagnostics = {
            enable = true;
            types = [ "markdownlint-cli2" ];
          };
          lsp = {
            enable = true;
            servers = [ "markdown-oxide" ];
          };
          extensions.render-markdown-nvim = {
            enable = true;
            setupOpts.completions.blink.enabled = true;
          };
        };

        typst = {
          enable = true;
          treesitter.enable = true;
          format.type = [ "typstyle" ];
          lsp = {
            enable = true;
            servers = [ "tinymist" ];
          };
        };
      };
    };
  };
}
