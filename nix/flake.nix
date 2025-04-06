{
  description = "My First Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, home-manager, ...}: 
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs {inherit system;};

      # ----- USER SETTINGS ----- #
      userSettings = {
        username = "sandmhan";
      };
    in {

      # System Configuration Output
      nixosConfigurations = {
        nixos = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [./configuration.nix];
        };
      };

      # User Configuration Output
      homeConfigurations = {
        # configuration name matches with hostname
        sandmhan = home-manager.lib.homeManagerConfiguration {
	  inherit pkgs;
	  modules = [ ./home.nix ];

          # Passing in configuration variables from above
	  extraSpecialArgs = {
	  inherit userSettings;
	  };
	};
      };
    };
}
