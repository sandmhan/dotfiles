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
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-hardware,
      home-manager,
      stylix,
      nvf,
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

      # Resolve active theme from ~/.config/active-theme if it exists,
      # otherwise fall back to default. This enables hot-swap via theme-switch.
      # Note: uses absolute path since flake eval is pure (no $HOME access).
      defaultTheme = "gruvbox-dark-hard";
      themeFile = /home/sandmhan/.config/active-theme;
      activeTheme =
        if builtins.pathExists themeFile then
          builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile themeFile)
        else
          defaultTheme;

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
          ];
          specialArgs = {
            inherit systemSettings;
            userSettings = linuxUserSettings;
          };
        };

        # Proxmox VM base image (no hardware-configuration)
        initialProxmoxVMA = mkNixosSystem {
          hostname = "initialProxmoxVMA";
          modules = [ ./hosts/server ];
        };

        # Generic Proxmox VM
        proxmoxVM = mkNixosSystem {
          hostname = "baseProxmox";
          modules = [
            ./hosts/server
            ./hosts/server/hardware-configuration.nix
          ];
        };

        # Network video recorder
        nvr = mkNixosSystem {
          hostname = "nvr";
          modules = [
            ./hosts/server
            ./hosts/server/hardware-configuration.nix
            ./hosts/nvr
          ];
        };

        # LLM inference server
        llama = mkNixosSystem {
          hostname = "llama";
          modules = [
            ./hosts/server
            ./hosts/server/hardware-configuration.nix
            ./hosts/llama
          ];
        };

        # Matrix homeserver
        matrix = mkNixosSystem {
          hostname = "matrix";
          modules = [
            ./hosts/server
            ./hosts/server/hardware-configuration.nix
            ./systemModules/matrix.nix
          ];
        };

        # Agent sandbox VM for autonomous infrastructure development
        agent-sandbox = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/agent
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useUserPackages = true;
                users.agent = {
                  imports = [
                    ./home/profiles/terminal.nix
                    ./home/modules/claude-agent.nix
                    stylix.homeModules.stylix
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

        # Agent VM VMA image for Proxmox deployment
        agentVMA = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/agent/image.nix
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
