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

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, stylix, nixvim, nvf, sops-nix, ... }:
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
          sops-nix.nixosModules.sops
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
          sops-nix.nixosModules.sops
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
          sops-nix.nixosModules.sops
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
          sops-nix.nixosModules.sops
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
          sops-nix.nixosModules.sops
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
          sops-nix.nixosModules.sops
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
          sops-nix.nixosModules.sops
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
              backupFileExtension = "hm-backup";
              users.agent = {
                imports = [
                  ./home/profiles/headless-terminal.nix
                  ./homeModules/claude-agent.nix
                  nixvim.homeModules.nixvim
                  # stylix removed - not needed for headless agent environment
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

      # NixOS Builder - autonomous configuration building and deployment
      nixos-builder = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixos-builder
        ];
        specialArgs = {
          userSettings = baseUserSettings;
          systemSettings = systemSettings // {
            hostname = "nixos-builder";
          };
        };
      };

      # WireGuard VPN Server - secure remote access to homelab
      vpn = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/vpn
          sops-nix.nixosModules.sops
        ];
        specialArgs = {
          userSettings = baseUserSettings;
          systemSettings = systemSettings // {
            hostname = "vpn";
          };
        };
      };

      # Monitoring Stack VM - Prometheus + Grafana observability
      monitor = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/monitor
          sops-nix.nixosModules.sops
        ];
        specialArgs = {
          userSettings = baseUserSettings;
          systemSettings = systemSettings // {
            hostname = "monitor";
          };
        };
      };

      # LXC Container Configurations (resource-efficient alternatives to VMs)
      # Deploy with: nixos-rebuild switch --target-host user@container --flake .#lxc-matrix

      lxc-matrix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/lxc-matrix
        ];
        specialArgs = {
          userSettings = linuxUserSettings // {
            username = "matrix";
            email = "matrix@homelab.local";
          };
          systemSettings = systemSettings // {
            hostname = "lxc-matrix";
          };
        };
      };

      lxc-monitor = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/lxc-monitor
        ];
        specialArgs = {
          userSettings = linuxUserSettings // {
            username = "monitor";
            email = "monitor@homelab.local";
          };
          systemSettings = systemSettings // {
            hostname = "lxc-monitor";
          };
        };
      };

      lxc-git = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/lxc-git
        ];
        specialArgs = {
          userSettings = linuxUserSettings // {
            username = "git";
            email = "git@homelab.local";
          };
          systemSettings = systemSettings // {
            hostname = "lxc-git";
          };
        };
      };

      lxc-nas = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/lxc-nas
        ];
        specialArgs = {
          userSettings = linuxUserSettings // {
            username = "nas";
            email = "nas@homelab.local";
          };
          systemSettings = systemSettings // {
            hostname = "lxc-nas";
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
