{
  description = "Home Manager standalone configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # Use the same nixpkgs as the top-level flake
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Change this to your username
      username = "username";

      # Primary platform — change to "x86_64-linux" for Linux
      system = "aarch64-darwin";

      pkgs = nixpkgs.legacyPackages.${system};

      # Custom settings passed to all modules via extraSpecialArgs.
      # Access these in home.nix as function arguments, e.g.:
      #   { config, pkgs, settings, ... }: { ... }
      settings = {
        inherit username;
        email = "user@example.com";
      };
    in
    {
      # Home Manager configuration entrypoint.
      # Activate with: `home-manager switch --flake .#username`
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Pass custom settings to all Home Manager modules
        extraSpecialArgs = {
          inherit settings;
        };

        modules = [
          ./home.nix
        ];
      };

      # Optional: dev shell for working on this configuration
      devShells = forAllSystems (
        sys:
        let
          devPkgs = nixpkgs.legacyPackages.${sys};
        in
        {
          default = devPkgs.mkShell {
            packages = with devPkgs; [
              home-manager.packages.${sys}.default
              nixfmt-rfc-style
            ];
          };
        }
      );
    };
}
