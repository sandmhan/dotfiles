{
  description = "Sandmhan's Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix/release-25.05";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

outputs = { self, nixpkgs, home-manager, stylix, nixvim, flake-utils, ... }:
  (
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # ---- SYSTEM SETTINGS ---- #
        systemSettings = {
          system = system;
          hostname = "gaia";
          profile = "personal";
          timezone = "America/Chicago";
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
        nixosConfigurations = nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          gaia = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./configuration.nix
              # stylix.nixosModules.stylix
            ];
          };
        };
      })
  )
  // {
    # Top-level home-manager configurations
    homeConfigurations = {
      sandmhan = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        modules = [
          ./home.nix
          nixvim.homeManagerModules.nixvim
          # stylix.homeManagerModules.stylix
        ];
        extraSpecialArgs = {
          userSettings = {
            username = "sandmhan";
            email = "austinsanders0105@gmail.com";
            theme = "";
            wm = "hyprland";
            font = "BlexMono Nerd Font";
          };
          inherit nixvim;
        };
      };

      macman = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "aarch64-darwin"; };
        modules = [
          ./home.nix
          nixvim.homeManagerModules.nixvim
          # stylix.homeManagerModules.stylix
        ];
        extraSpecialArgs = {
          userSettings = {
            username = "sandmhan";
            email = "austinsanders0105@gmail.com";
            theme = "";
            wm = "hyprland";
            font = "BlexMono Nerd Font";
          };
          inherit nixvim;
        };
      };
    };
  };
}
