{
  lib,
  config,
  ...
}:
let
  cfg = config.programs.sandvim;
  hasLspPack = cfg.packs.tidal || builtins.any (pack: pack) (builtins.attrValues cfg.packs.languages);
in
{
  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && !hasLspPack) {
      programs.nvf.settings.vim.lsp.enable = lib.mkForce false;
    })

    (lib.mkIf (cfg.enable && hasLspPack) {
      programs.nvf.settings.vim.lsp = {
        enable = true;
        inlayHints.enable = true;
        mappings.signatureHelp = "<leader>lk";
      };
    })

    (lib.mkIf (cfg.enable && cfg.packs.languages.general) {
      programs.nvf.settings.vim.lsp = {
        # General prose/code support owns shared spellchecking.
        presets.harper.enable = true;

        servers = {
          # Keep NVF default servers from overlapping the explicit general-pack
          # owners in languages.nix.
          nil_ls.enable = false;
          marksman.enable = false;
        };
      };
    })
  ];
}
