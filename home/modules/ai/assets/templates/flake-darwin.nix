{
  description = "nix-darwin system configuration with Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs"; # Use the same nixpkgs throughout
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nix-darwin,
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

      # Change these to match your system
      hostname = "hostname";
      username = "username";
      system = "aarch64-darwin";
    in
    {
      # nix-darwin configuration entrypoint.
      # Activate with: `darwin-rebuild switch --flake .#hostname`
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        inherit system;

        # Pass custom values to all nix-darwin modules (darwin.nix, etc.)
        specialArgs = {
          inherit username hostname;
        };

        modules = [
          # System-level configuration
          ./darwin.nix

          # Home Manager as a nix-darwin module.
          # This integrates HM into the darwin-rebuild workflow so you
          # don't need to run `home-manager switch` separately.
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true; # Use the system-level nixpkgs
              useUserPackages = true; # Install to /etc/profiles instead of ~/.nix-profile

              # Pass custom values to all Home Manager modules (home.nix, etc.)
              extraSpecialArgs = {
                inherit username hostname;
              };

              users.${username} = import ./home.nix;
            };
          }
        ];
      };

      # Optional: dev shell for working on this configuration
      devShells = forAllSystems (
        sys:
        let
          pkgs = nixpkgs.legacyPackages.${sys};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nixfmt-rfc-style
            ];
          };
        }
      );
    };
}
