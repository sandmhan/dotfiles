{
  description = "NixOS system configuration with Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # Use the same nixpkgs throughout
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

      # Change these to match your system
      hostname = "hostname";
      username = "username";
      system = "x86_64-linux"; # Change to "aarch64-linux" for ARM servers
    in
    {
      # NixOS configuration entrypoint.
      # Activate with: `sudo nixos-rebuild switch --flake .#hostname`
      # Remote deploy: `nixos-rebuild switch --target-host root@hostname --flake .#hostname`
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;

        # Pass custom values to all NixOS modules (configuration.nix, etc.)
        specialArgs = {
          inherit username hostname;
        };

        modules = [
          # System-level configuration
          ./configuration.nix

          # Home Manager as a NixOS module.
          # This integrates HM into the nixos-rebuild workflow so you
          # don't need to run `home-manager switch` separately.
          home-manager.nixosModules.home-manager
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
