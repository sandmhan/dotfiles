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
        languages = {
          terraform = {
            enable = true;
            treesitter.enable = true;

            lsp = {
              enable = true;
              servers = [ "tofuls-tf" ];
            };

            format = {
              enable = true;
              type = [ "tofu-fmt" ];
            };
          };

          hcl = {
            enable = true;
            treesitter.enable = true;

            lsp = {
              enable = true;
              servers = [ "tofuls-hcl" ];
            };

            format = {
              enable = true;
              type = [ "hclfmt" ];
            };
          };

          yaml = {
            enable = true;
            treesitter.enable = true;

            # Kubernetes manifests and Compose files are YAML-owned in Phase 2;
            # project CI commands are documented without adding task-runner keymaps.
            lsp = {
              enable = true;
              servers = [ "yaml-language-server" ];
            };
          };

          bash = {
            enable = true;
            treesitter.enable = true;

            lsp = {
              enable = true;
              servers = [ "bash-ls" ];
            };

            format = {
              enable = true;
              type = [ "shfmt" ];
            };

            extraDiagnostics = {
              enable = true;
              types = [ "shellcheck" ];
            };
          };

          toml = {
            enable = true;
            treesitter.enable = true;

            lsp = {
              enable = true;
              servers = [ "taplo" ];
            };

            format = {
              enable = true;
              type = [ "taplo" ];
            };

            extraDiagnostics = {
              enable = true;
              types = [ "tombi" ];
            };
          };
        };

        lsp.servers.dockerls = {
          enable = true;
          cmd = [
            (lib.getExe pkgs.dockerfile-language-server)
            "--stdio"
          ];
          filetypes = [ "dockerfile" ];
          root_markers = [
            "Dockerfile"
            ".git"
          ];
        };

        treesitter.grammars = [ pkgs.vimPlugins.nvim-treesitter.builtGrammars.dockerfile ];

        diagnostics.nvim-lint = {
          enable = true;
          linters_by_ft.dockerfile = [ "hadolint" ];
          linters.hadolint = {
            cmd = lib.getExe pkgs.hadolint;
            args = [ "--format=json" ];
            stdin = true;
          };
        };
      };
    };

  };
}
