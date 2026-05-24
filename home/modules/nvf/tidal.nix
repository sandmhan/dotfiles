{ pkgs, ... }:
let
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
        require("tidal").setup({
          boot = {
            tidal = {
              cmd = "${tidalGhc}/bin/ghci",
              args = { "-v0" },
            },
          },
        })
      '';
    };
  };
}
