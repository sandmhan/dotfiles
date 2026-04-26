{
  description = "Sandmhan's Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
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
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      home-manager,
      stylix,
      nvf,
      sops-nix,
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
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          inherit modules;
          extraSpecialArgs = {
            inherit userSettings;
          };
        };
    in
    {
      nixosConfigurations = {
        # Desktop — Framework 13 AMD (daily driver)
        gaia = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/gaia
            nixos-hardware.nixosModules.framework-13-7040-amd
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

        # WireGuard VPN Server (retained, not deployed — pivoted to Tailscale)
        vpn = mkNixosSystem {
          hostname = "vpn";
          modules = [
            ./hosts/vpn
            sops-nix.nixosModules.sops
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
                    ./home/modules/claude-agent.nix
                    nvf.homeManagerModules.default
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
          nvf.homeManagerModules.default
        ];

        # macOS (terminal-focused)
        macman = mkHomeConfiguration "aarch64-darwin" macUserSettings [
          ./home/profiles/macos.nix
          stylix.homeModules.stylix
          nvf.homeManagerModules.default
        ];

        # WSL (terminal-focused)
        wslman = mkHomeConfiguration "x86_64-linux" wslUserSettings [
          ./home/profiles/wsl.nix
          stylix.homeModules.stylix
          nvf.homeManagerModules.default
        ];

        # Terminal-only Linux (servers/headless)
        terminalman = mkHomeConfiguration "x86_64-linux" linuxUserSettings [
          ./home/profiles/terminal.nix
          stylix.homeModules.stylix
          nvf.homeManagerModules.default
        ];
      };

      # Formatter for `nix fmt`
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt;
    };
}
