{
  description = "Sandmhan's Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    # FreeCAD is pinned separately to avoid transient source build failures in
    # unstable's GDAL/Python stack while keeping the rest of the system current.
    nixpkgsFreecad.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Codex releases move faster than nixos-unstable. Track nixpkgs master for
    # just the Codex CLI while keeping the rest of the profile on the main pin.
    nixpkgsCodex.url = "github:NixOS/nixpkgs/master";
    nixos-hardware.url = "github:NixOs/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    remoteCommunity = {
      url = "git+ssh://git@github.com/sandmhan/remote-community.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgsFreecad,
      nixpkgsCodex,
      nixos-hardware,
      home-manager,
      stylix,
      nvf,
      sops-nix,
      remoteCommunity,
      zen-browser,
      ...
    }:
    let
      # Shared user settings
      baseUserSettings = {
        username = "sandmhan";
        email = "austinsanders0105@gmail.com";
        font = "BlexMono Nerd Font";
      };

      # System settings for NixOS
      systemSettings = {
        system = "x86_64-linux";
        hostname = "gaia";
        profile = "personal";
        timezone = "America/New_York";
        locale = "en_US.UTF-8";
        bootMode = "uefi";
        bootMountPath = "/boot";
        grubDevice = "";
        gpuType = "amd";
      };

      # Default build-time theme (Stylix bakes this into generated configs).
      # Runtime theme switching uses OSC escape sequences — see home/modules/theming.nix.
      activeTheme = "gruvbox-dark-hard";

      # Reusable Home Manager module for the NVF-based Sandvim configuration.
      sandvimHomeManagerModule = {
        imports = [
          nvf.homeManagerModules.default
          ./home/modules/nvf
        ];
      };

      dotfilesSandvimAdapter =
        {
          lib,
          config,
          ...
        }:
        {
          config.programs.sandvim = {
            enable = lib.mkDefault config.myHome.features.enableNixvim;
            preset = lib.mkDefault "full";
          };
        };

      mkSandvimExternalConsumer =
        {
          system,
          preset ? "standard",
          modules ? [ ],
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [
            sandvimHomeManagerModule
            {
              home = {
                username = "sandvim-${preset}";
                homeDirectory = "/home/sandvim-${preset}";
                stateVersion = "24.11";
              };

              news.display = "silent";
              programs.sandvim = {
                enable = true;
                inherit preset;
              };
            }
          ]
          ++ modules;
        };

      mkSandvimExternalConsumers =
        system:
        let
          configurations = nixpkgs.lib.genAttrs [
            "minimal"
            "standard"
            "full"
          ] (preset: mkSandvimExternalConsumer { inherit system preset; });
        in
        {
          inherit configurations;
          activationPackages = nixpkgs.lib.mapAttrs (
            _: configuration: configuration.activationPackage
          ) configurations;
          finalPackages = nixpkgs.lib.mapAttrs (
            _: configuration: configuration.config.programs.nvf.finalPackage
          ) configurations;
        };

      mkSandvimMinimalRuntimeCheck =
        pkgs: finalPackage:
        pkgs.runCommand "sandvim-minimal-runtime"
          {
            nativeBuildInputs = [
              pkgs.coreutils
              pkgs.git
              pkgs.gnugrep
            ];
          }
          ''
            set -euo pipefail

            export HOME="$TMPDIR/home"
            export XDG_CACHE_HOME="$TMPDIR/cache"
            export XDG_CONFIG_HOME="$TMPDIR/config"
            export XDG_DATA_HOME="$TMPDIR/data"
            export XDG_STATE_HOME="$TMPDIR/state"
            mkdir -p "$HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$out"

            nvim="${finalPackage}/bin/nvim"
            if ! timeout 120s "$nvim" --headless -n -i NONE \
              -c "luafile ${./scripts/check-nvf-minimal-runtime.lua}" \
              -c messages \
              -c 'qa!' >"$out/minimal-runtime.log" 2>&1; then
              cat "$out/minimal-runtime.log" >&2
              exit 1
            fi
            if ! grep -Fq 'NVF_MINIMAL_RUNTIME_OK' "$out/minimal-runtime.log"; then
              cat "$out/minimal-runtime.log" >&2
              exit 1
            fi
          '';

      mkSandvimMarkdownRuntimeCheck =
        pkgs: finalPackage:
        pkgs.runCommand "sandvim-markdown-runtime"
          {
            nativeBuildInputs = [
              pkgs.coreutils
              pkgs.git
              pkgs.gnugrep
            ];
          }
          ''
            set -euo pipefail

            export HOME="$TMPDIR/home"
            export XDG_CACHE_HOME="$TMPDIR/cache"
            export XDG_CONFIG_HOME="$TMPDIR/config"
            export XDG_DATA_HOME="$TMPDIR/data"
            export XDG_STATE_HOME="$TMPDIR/state"
            # The workspace guard intentionally treats /build as generated output;
            # use the sandbox-private /tmp so LSP clients remain enabled.
            workspace="/tmp/sandvim-markdown-runtime-workspace"
            mkdir -p \
              "$HOME" \
              "$XDG_CACHE_HOME" \
              "$XDG_CONFIG_HOME" \
              "$XDG_DATA_HOME" \
              "$XDG_STATE_HOME" \
              "$workspace/.git" \
              "$workspace/.obsidian" \
              "$workspace/attachments" \
              "$workspace/templates" \
              "$out"
            cp ${./tests/fixtures/markdown-obsidian-runtime.md} "$workspace/markdown-obsidian-runtime.md"
            chmod u+w "$workspace/markdown-obsidian-runtime.md"

            cd "$workspace"
            export SANDVIM_MARKDOWN_FIXTURE="$workspace/markdown-obsidian-runtime.md"
            if ! timeout 240s ${finalPackage}/bin/nvim \
              --headless -n -i NONE "$SANDVIM_MARKDOWN_FIXTURE" \
              -c "luafile ${./scripts/check-nvf-markdown-runtime.lua}" \
              -c messages \
              -c 'qa!' >"$out/markdown-runtime.log" 2>&1; then
              cat "$out/markdown-runtime.log" >&2
              exit 1
            fi
            if ! grep -Fq 'NVF_MARKDOWN_RUNTIME_OK' "$out/markdown-runtime.log"; then
              cat "$out/markdown-runtime.log" >&2
              exit 1
            fi
            if grep -Fq 'nvim-navic: Failed to attach' "$out/markdown-runtime.log"; then
              cat "$out/markdown-runtime.log" >&2
              exit 1
            fi
          '';

      mkSandvimJavaRuntimeCheck =
        pkgs: finalPackage:
        let
          javaSource = pkgs.writeText "Greeter.java" ''
            package dev.sandvim;

            public class Greeter {
                public String greet(String name) {
                    return makeMessage(name);
                }

                private String makeMessage(String name) {
                    return "Hello, " + name;
                }
            }
          '';
        in
        pkgs.runCommand "sandvim-java-runtime"
          {
            nativeBuildInputs = [
              pkgs.coreutils
              pkgs.git
              pkgs.gnugrep
            ];
          }
          ''
            set -euo pipefail

            export HOME="$TMPDIR/home"
            export XDG_CACHE_HOME="$TMPDIR/cache"
            export XDG_CONFIG_HOME="$TMPDIR/config"
            export XDG_DATA_HOME="$TMPDIR/data"
            export XDG_STATE_HOME="$TMPDIR/state"
            workspace="$(mktemp -d /tmp/sandvim-java-runtime.XXXXXX)"
            mkdir -p \
              "$HOME" \
              "$XDG_CACHE_HOME" \
              "$XDG_CONFIG_HOME" \
              "$XDG_DATA_HOME" \
              "$XDG_STATE_HOME" \
              "$workspace/.git" \
              "$workspace/src/main/java/dev/sandvim" \
              "$out"
            cp ${javaSource} "$workspace/src/main/java/dev/sandvim/Greeter.java"

            cd "$workspace"
            if ! timeout 240s ${finalPackage}/bin/nvim \
              --headless -n -i NONE src/main/java/dev/sandvim/Greeter.java \
              -c "luafile ${./scripts/check-nvf-java-runtime.lua}" \
              -c messages \
              -c 'qa!' >"$out/java-runtime.log" 2>&1; then
              cat "$out/java-runtime.log" >&2
              exit 1
            fi
            if ! grep -Fq 'NVF_JAVA_RUNTIME_OK' "$out/java-runtime.log"; then
              cat "$out/java-runtime.log" >&2
              exit 1
            fi
          '';

      mkSandvimStartupProfileCheck =
        pkgs:
        {
          minimalPackage,
          fullPackage,
        }:
        pkgs.runCommand "sandvim-startup-profile"
          {
            nativeBuildInputs = [
              pkgs.gawk
              pkgs.git
            ];
          }
          ''
            set -euo pipefail

            mkdir -p "$out"

            run_startup() {
              label="$1"
              nvim="$2"
              budget_ms="$3"
              export HOME="$TMPDIR/$label-home"
              export XDG_CACHE_HOME="$TMPDIR/$label-cache"
              export XDG_CONFIG_HOME="$TMPDIR/$label-config"
              export XDG_DATA_HOME="$TMPDIR/$label-data"
              export XDG_STATE_HOME="$TMPDIR/$label-state"
              mkdir -p "$HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"

              log="$out/$label-startuptime.log"
              stdout_log="$out/$label-startuptime.stdout.log"
              timeout 120s "$nvim" --headless -n -i NONE --startuptime "$log" -c 'qa!' >"$stdout_log" 2>&1
              if ! elapsed_ms="$(awk '
                /^[0-9]+[.][0-9]+/ { elapsed = $1; seen = 1 }
                END { if (!seen) exit 1; printf "%.0f", elapsed }
              ' "$log")"; then
                cat "$log" >&2
                printf 'no startup timing rows found for %s\n' "$label" >&2
                exit 1
              fi
              {
                printf 'profile=%s\n' "$label"
                printf 'elapsed_ms=%s\n' "$elapsed_ms"
                printf 'budget_ms=%s\n' "$budget_ms"
                printf 'budget_note=%s\n' 'CI guardrail is intentionally generous versus observed 149-169ms warm local full starts to avoid flaky cold-cache failures.'
              } >"$out/$label-summary.txt"
              if [ "$elapsed_ms" -gt "$budget_ms" ]; then
                cat "$out/$label-summary.txt" >&2
                exit 1
              fi
            }

            run_startup minimal "${minimalPackage}/bin/nvim" 1000
            run_startup full "${fullPackage}/bin/nvim" 2000
          '';

      # User settings per-machine/platform
      linuxUserSettings = baseUserSettings // {
        theme = activeTheme;
        wm = "sway";
      };

      macUserSettings = baseUserSettings // {
        theme = activeTheme;
        wm = "";
      };

      wslUserSettings = baseUserSettings // {
        theme = activeTheme;
        wm = "";
      };

      # Helper to create Proxmox VM NixOS configurations
      mkNixosSystem =
        {
          hostname,
          modules ? [ ],
          userSettings ? baseUserSettings,
        }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          inherit modules;
          specialArgs = {
            inherit userSettings;
            systemSettings = systemSettings // {
              inherit hostname;
            };
          };
        };

      # Helper to create Home Manager configurations
      mkHomeConfiguration =
        system: userSettings: modules:
        let
          pinnedNixpkgsConfig = {
            allowUnfree = true;
            allowUnsupportedSystem = true;
          };
          freecadPkgs = import nixpkgsFreecad {
            inherit system;
            config = pinnedNixpkgsConfig;
          };
          codexPkgs = import nixpkgsCodex {
            inherit system;
            config = pinnedNixpkgsConfig;
          };
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = modules ++ [
            sandvimHomeManagerModule
            dotfilesSandvimAdapter
          ];
          extraSpecialArgs = {
            inherit userSettings freecadPkgs codexPkgs;
          };
        };
    in
    {
      homeManagerModules = {
        sandvim = sandvimHomeManagerModule;
        default = sandvimHomeManagerModule;
      };

      packages =
        nixpkgs.lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-darwin"
          ]
          (
            system:
            let
              consumers = mkSandvimExternalConsumers system;
            in
            {
              sandvimMinimal = consumers.finalPackages.minimal;
              sandvimStandard = consumers.finalPackages.standard;
              sandvimFull = consumers.finalPackages.full;
            }
          );

      checks.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          consumers = mkSandvimExternalConsumers "x86_64-linux";
          markdownConsumer = mkSandvimExternalConsumer {
            system = "x86_64-linux";
            preset = "minimal";
            modules = [
              {
                programs.sandvim.packs = {
                  notes = true;
                  languages.documentation = true;
                };
              }
            ];
          };
        in
        {
          sandvimExternalConsumer = consumers.activationPackages.standard;
          sandvimMinimalConsumer = consumers.activationPackages.minimal;
          sandvimMinimalRuntime = mkSandvimMinimalRuntimeCheck pkgs consumers.finalPackages.minimal;
          sandvimMarkdownRuntime = mkSandvimMarkdownRuntimeCheck pkgs markdownConsumer.config.programs.nvf.finalPackage;
          sandvimJavaRuntime = mkSandvimJavaRuntimeCheck pkgs consumers.finalPackages.full;
          sandvimStartupProfile = mkSandvimStartupProfileCheck pkgs {
            minimalPackage = consumers.finalPackages.minimal;
            fullPackage = consumers.finalPackages.full;
          };
        };

      nixosConfigurations = {
        # Desktop — Framework 13 AMD (daily driver)
        gaia = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/gaia
            nixos-hardware.nixosModules.framework-amd-ai-300-series
            stylix.nixosModules.stylix
            sops-nix.nixosModules.sops
          ];
          specialArgs = {
            inherit systemSettings;
            userSettings = linuxUserSettings;
          };
        };

        # Minimal Proxmox base — foundation for all Proxmox VMs (from agent-sandbox)
        proxmoxBase = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/proxmox-base
            sops-nix.nixosModules.sops
          ];
          specialArgs = {
            userSettings = baseUserSettings;
            systemSettings = systemSettings // {
              hostname = "proxmox-base";
            };
          };
        };

        # Proxmox VM base image (no hardware-configuration)
        initialProxmoxVMA = mkNixosSystem {
          hostname = "initialProxmoxVMA";
          modules = [
            ./hosts/server
            sops-nix.nixosModules.sops
          ];
        };

        # Generic Proxmox VM
        proxmoxVM = mkNixosSystem {
          hostname = "baseProxmox";
          modules = [
            ./hosts/server
            ./hosts/server/hardware-configuration.nix
            sops-nix.nixosModules.sops
          ];
        };

        # Network video recorder
        nvr = mkNixosSystem {
          hostname = "nvr";
          modules = [
            ./hosts/server
            ./hosts/server/hardware-configuration.nix
            ./hosts/nvr
            sops-nix.nixosModules.sops
          ];
        };

        # LLM inference server
        llama = mkNixosSystem {
          hostname = "llama";
          modules = [
            ./hosts/server
            ./hosts/server/hardware-configuration.nix
            ./hosts/llama
            sops-nix.nixosModules.sops
          ];
        };

        # Matrix homeserver
        matrix = mkNixosSystem {
          hostname = "matrix";
          modules = [
            ./hosts/server
            ./hosts/server/hardware-configuration.nix
            ./systemModules/matrix.nix
            ./systemModules/matrix-agent-bridge.nix
            sops-nix.nixosModules.sops
          ];
        };

        # Forgejo Git server
        git = mkNixosSystem {
          hostname = "git";
          modules = [
            ./hosts/git
            sops-nix.nixosModules.sops
          ];
        };

        # Fitness tracking — wger
        fitness = mkNixosSystem {
          hostname = "fitness";
          modules = [
            ./hosts/fitness
            sops-nix.nixosModules.sops
          ];
        };

        # Home Assistant — smart home automation
        homeassistant = mkNixosSystem {
          hostname = "homeassistant";
          modules = [
            ./hosts/homeassistant
            sops-nix.nixosModules.sops
          ];
        };

        # Media server — Jellyfin, *arr stack
        media = mkNixosSystem {
          hostname = "media";
          modules = [
            ./hosts/media
            sops-nix.nixosModules.sops
          ];
        };

        # Tailscale Subnet Router — always-on VM for remote access into homelab
        vpn = mkNixosSystem {
          hostname = "vpn";
          modules = [
            ./hosts/vpn
            sops-nix.nixosModules.sops
          ];
        };

        # Remote Community — observe-only Android lab VM, no public app/ADB ports
        remote-community = mkNixosSystem {
          hostname = "remote-community";
          modules = [
            ./hosts/remote-community
            remoteCommunity.nixosModules.remote-community
            remoteCommunity.nixosModules.android-emulator
            sops-nix.nixosModules.sops
            {
              services.remote-community.actuatorCommand = nixpkgs.lib.getExe remoteCommunity.packages.x86_64-linux.android-gate-actuator;
            }
          ];
        };

        # Monitoring Stack — Prometheus + Grafana
        monitor = mkNixosSystem {
          hostname = "monitor";
          modules = [
            ./hosts/monitor
            sops-nix.nixosModules.sops
          ];
        };

        # Network Attached Storage
        nas = mkNixosSystem {
          hostname = "nas";
          modules = [
            ./hosts/nas
            sops-nix.nixosModules.sops
          ];
        };

        # NixOS Builder — autonomous configuration building and deployment
        nixos-builder = mkNixosSystem {
          hostname = "nixos-builder";
          modules = [
            ./hosts/nixos-builder
          ];
        };

        # Agent sandbox VM for autonomous infrastructure development
        agent-sandbox = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/agent
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            {
              home-manager = {
                useUserPackages = true;
                backupFileExtension = "hm-backup";
                users.agent = {
                  imports = [
                    ./home/profiles/headless-terminal.nix
                    ./home/modules/ai-agent.nix
                    sandvimHomeManagerModule
                    dotfilesSandvimAdapter
                  ];
                };
                extraSpecialArgs = {
                  userSettings = linuxUserSettings // {
                    username = "agent";
                    email = "agent@homelab.local";
                  };
                };
              };
            }
          ];
          specialArgs = {
            userSettings = linuxUserSettings // {
              username = "agent";
              email = "agent@homelab.local";
            };
            systemSettings = systemSettings // {
              hostname = "agent-sandbox";
            };
          };
        };

        # Agent VM VMA image for Proxmox deployment (minimal — boots reliably)
        agentVMA = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/agent-minimal/image.nix
          ];
          specialArgs = {
            userSettings = linuxUserSettings // {
              username = "agent";
              email = "agent@homelab.local";
            };
            systemSettings = systemSettings // {
              hostname = "agent-sandbox";
              diskSize = 50 * 1024; # 50GB for agent development and nix-shell tooling
            };
          };
        };

        # Remote Gaming VM — Sunshine server with GPU passthrough (Phase 4)
        gaming = mkNixosSystem {
          hostname = "gaming";
          modules = [
            ./hosts/gaming
            sops-nix.nixosModules.sops
          ];
        };

        # LXC Base Image
        # Build: nix build .#nixosConfigurations.initialLXC.config.system.build.tarball
        initialLXC = mkNixosSystem {
          hostname = "nixos-lxc";
          modules = [
            ./hosts/lxc-base/image.nix
          ];
          userSettings = linuxUserSettings // {
            username = "sandmhan";
            email = "sandmhan@homelab.local";
          };
        };

        # LXC Container Configurations
        lxc-matrix = mkNixosSystem {
          hostname = "lxc-matrix";
          modules = [
            ./hosts/lxc-matrix
            sops-nix.nixosModules.sops
          ];
          userSettings = linuxUserSettings // {
            username = "matrix";
            email = "matrix@homelab.local";
          };
        };

        lxc-monitor = mkNixosSystem {
          hostname = "lxc-monitor";
          modules = [
            ./hosts/lxc-monitor
            sops-nix.nixosModules.sops
          ];
          userSettings = linuxUserSettings // {
            username = "monitor";
            email = "monitor@homelab.local";
          };
        };

        lxc-git = mkNixosSystem {
          hostname = "lxc-git";
          modules = [
            ./hosts/lxc-git
            sops-nix.nixosModules.sops
          ];
          userSettings = linuxUserSettings // {
            username = "git";
            email = "git@homelab.local";
          };
        };

        lxc-homeassistant = mkNixosSystem {
          hostname = "lxc-homeassistant";
          modules = [
            ./hosts/lxc-homeassistant
            sops-nix.nixosModules.sops
          ];
          userSettings = linuxUserSettings // {
            username = "hass";
            email = "hass@homelab.local";
          };
        };

        lxc-nas = mkNixosSystem {
          hostname = "lxc-nas";
          modules = [
            ./hosts/lxc-nas
            sops-nix.nixosModules.sops
          ];
          userSettings = linuxUserSettings // {
            username = "nasadmin";
            email = "nasadmin@homelab.local";
          };
        };
      };

      homeConfigurations = {
        # Linux desktop (full desktop environment — Gaia daily driver)
        sandmhan = mkHomeConfiguration "x86_64-linux" linuxUserSettings [
          ./home/profiles/desktop.nix
          stylix.homeModules.stylix
          zen-browser.homeModules.beta
        ];

        # macOS (terminal-focused)
        macman = mkHomeConfiguration "aarch64-darwin" macUserSettings [
          ./home/profiles/macos.nix
          stylix.homeModules.stylix
        ];

        # WSL (terminal-focused)
        wslman = mkHomeConfiguration "x86_64-linux" wslUserSettings [
          ./home/profiles/wsl.nix
          stylix.homeModules.stylix
        ];

        # Terminal-only Linux (servers/headless)
        terminalman = mkHomeConfiguration "x86_64-linux" linuxUserSettings [
          ./home/profiles/terminal.nix
          stylix.homeModules.stylix
        ];
      };

      # Formatter for `nix fmt`
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt;
    };
}
