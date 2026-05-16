{
  description = "Project development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # Add project dependencies here, for example:
              # nodejs
              # python3
              # rustc
              # cargo
            ];

            shellHook = ''
              echo "Development environment loaded"
            '';
          };
        }
      );

      # Uncomment to add buildable packages:
      # packages = forAllSystems (system:
      #   let pkgs = nixpkgs.legacyPackages.${system};
      #   in {
      #     default = pkgs.callPackage ./package.nix { };
      #   }
      # );

      # Uncomment to add checks (run with `nix flake check`):
      # checks = forAllSystems (system:
      #   let pkgs = nixpkgs.legacyPackages.${system};
      #   in {
      #     formatting = pkgs.runCommand "check-formatting" { } ''
      #       # Add formatting/linting checks here
      #       touch $out
      #     '';
      #   }
      # );
    };
}
