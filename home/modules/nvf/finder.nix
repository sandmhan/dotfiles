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
        fzf-lua = {
          enable = true;
          profile = "default";
          setupOpts = {
            keymap.builtin = {
              "<S-j>" = "preview-down";
              "<S-k>" = "preview-up";
            };
            fzf_opts = {
              "--bind" = "ctrl-n:down,ctrl-p:up";
            };
          };
        };
      };
    };

  };
}
