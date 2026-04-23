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
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, stylix, nixvim, nvf, ... }:
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

    # User settings per-machine/platform
    linuxUserSettings = baseUserSettings // {
      theme = "gruvbox-dark-hard";
      wm = "sway";
    };

    macUserSettings = baseUserSettings // {
      theme = "gruvbox-dark-hard";  # Enable theming for terminal
      wm = "";  # No WM for macOS
    };

    wslUserSettings = baseUserSettings // {
      theme = "gruvbox-dark-hard";
      wm = "";  # No WM for WSL
    };

    # Helper function to create home configurations
    mkHomeConfiguration = system: userSettings: modules:
      home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        inherit modules;
        extraSpecialArgs = {
          inherit userSettings;
        };
      };
  in {
    nixosConfigurations = {
      gaia = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          nixos-hardware.nixosModules.framework-13-7040-amd
          stylix.nixosModules.stylix
        ];
        specialArgs = {
          inherit systemSettings;
          userSettings = linuxUserSettings;
        };
      };

      # Minimal Proxmox base - foundation for all Proxmox VMs
      proxmoxBase = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/proxmox-base
        ];
        specialArgs = {
          userSettings = baseUserSettings;
          systemSettings = systemSettings // {
            hostname = "proxmox-base";
          };
        };
      };

      initialProxmoxVMA = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/server
        ];
        specialArgs = {
          userSettings = baseUserSettings;

           systemSettings = systemSettings //
            {
              hostname = "initialProxmoxVMA";
            }
            ;
        };
      };

      proxmoxVM = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/server
          ./hosts/server/hardware-configuration.nix
        ];
        specialArgs = {
          userSettings = baseUserSettings;

           systemSettings = systemSettings //
            {
              hostname = "baseProxmox";
            }
            ;
        };
      };

      nvr = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/proxmox-base
          ./hosts/nvr
        ];
        specialArgs = {
          userSettings = baseUserSettings;

           systemSettings = systemSettings //
            {
              hostname = "nvr";
            }
            ;
        };
      };

      llama = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/server
          ./hosts/server/hardware-configuration.nix
          ./hosts/llama
        ];
        specialArgs = {
          userSettings = baseUserSettings;

           systemSettings = systemSettings //
            {
              hostname = "llama";
            }
            ;
        };
      };

      matrix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/server
          ./hosts/server/hardware-configuration.nix
          ./systemModules/matrix.nix
        ];
        specialArgs = {
          userSettings = baseUserSettings;

           systemSettings = systemSettings //
            {
              hostname = "matrix";
            }
            ;
        };
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
                  ./homeModules/claude-agent.nix
                  nixvim.homeModules.nixvim
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

           systemSettings = systemSettings //
            {
              hostname = "agent-sandbox";
            }
            ;
        };
      };

      # Agent VM VMA image for Proxmox deployment (minimal - boots reliably)
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
            diskSize = 50 * 1024;  # 50GB for agent development and nix-shell tooling
          };
        };
      };
    };

    homeConfigurations = {
      # Linux desktop configuration (full desktop environment)
      sandmhan = mkHomeConfiguration "x86_64-linux" linuxUserSettings [
        ./home/profiles/desktop.nix
        nixvim.homeModules.nixvim
        stylix.homeModules.stylix
        nvf.homeManagerModules.default
      ];

      # macOS configuration (terminal-focused)
      macman = mkHomeConfiguration "aarch64-darwin" macUserSettings [
        ./home/profiles/macos.nix
        nixvim.homeModules.nixvim
        stylix.homeModules.stylix
        nvf.homeManagerModules.default
      ];

      # WSL configuration (terminal-focused)
      wslman = mkHomeConfiguration "x86_64-linux" wslUserSettings [
        ./home/profiles/wsl.nix
        nixvim.homeModules.nixvim
        stylix.homeModules.stylix
        nvf.homeManagerModules.default
      ];

      # Terminal-only Linux configuration (for servers/headless systems)
      terminalman = mkHomeConfiguration "x86_64-linux" linuxUserSettings [
        ./home/profiles/terminal.nix
        nixvim.homeModules.nixvim
        stylix.homeModules.stylix
        nvf.homeManagerModules.default
      ];
    };
  };
}
