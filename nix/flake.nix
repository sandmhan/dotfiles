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
    flake-utils.url = "github:numtide/flake-utils";
  };

outputs = { self, nixpkgs, nixos-hardware, home-manager, stylix, nixvim, flake-utils, ... }:
  (
      let
        system = "x86_64-linux";
        pkgs = import nixpkgs { inherit system; };

        # ---- SYSTEM SETTINGS ---- #
        systemSettings = {
          system = system;
          hostname = "gaia";
          profile = "personal";
          timezone = "America/New_York";
          locale = "en_US.UTF-8";
          bootMode = "uefi";
          bootMountPath = "/boot";
          grubDevice = "";
          gpuType = "amd";
        };

        # ----- USER SETTINGS ----- #
        userSettings = {
          username = "sandmhan";
          email = "austinsanders0105@gmail.com";
          theme = "";
          wm = "hyprland";
          font = "BlexMono";
        };
      in {
        # Only define nixosConfiguration on Linux systems
        nixosConfigurations = {
          gaia = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";

            # Hardware specific configuration for Framework 13

            modules = [
              ./configuration.nix
              nixos-hardware.nixosModules.framework-amd-ai-300-series
              stylix.nixosModules.stylix
            ];
            specialArgs = {
                inherit systemSettings;
            };
          };
        };
      }
  )
  // {
    # Top-level home-manager configurations
    homeConfigurations = {
      sandmhan = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        modules = [
          ./home.nix
          nixvim.homeModules.nixvim
          stylix.homeModules.stylix
        ];
        extraSpecialArgs = {
          userSettings = {
            username = "sandmhan";
            email = "austinsanders0105@gmail.com";
            theme = "";
            wm = "hyprland";
            font = "BlexMono Nerd Font";
          };
        };
      };

      macman = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "aarch64-darwin"; };
        modules = [
          ./home.nix
          nixvim.homeManagerModules.nixvim
          stylix.homeModules.stylix #homeModule is new standard for stylix
        ];
        extraSpecialArgs = {
          userSettings = {
            username = "sandmhan";
            email = "austinsanders0105@gmail.com";
            theme = "";
            wm = "hyprland";
            font = "BlexMono Nerd Font";
          };
        };
      };
    };
  };
}
