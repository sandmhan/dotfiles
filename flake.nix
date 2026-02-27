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

    # User settings per-machine
    linuxUserSettings = baseUserSettings // {
      theme = "gigavolt";
      wm = "sway";
    };

    macUserSettings = baseUserSettings // {
      theme = "";
      wm = "hyprland";
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
          ./hosts/server
          ./hosts/server/hardware-configuration.nix
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
    };

    homeConfigurations = {
      sandmhan = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./home.nix
          nixvim.homeModules.nixvim
          stylix.homeModules.stylix
          nvf.homeManagerModules.default
        ];
        extraSpecialArgs = {
          userSettings = linuxUserSettings;
        };
      };

      macman = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [
          ./home.nix
          nixvim.homeModules.nixvim
          stylix.homeModules.stylix
        ];
        extraSpecialArgs = {
          userSettings = macUserSettings;
        };
      };
    };
  };
}
