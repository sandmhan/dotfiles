# Nix Code Conventions

- Format all Nix files with `nixfmt`
- Use `lib.mkIf` for conditional configuration
- Use `lib.mkMerge` for combining multiple conditional blocks
- Use `lib.optionals` for conditional list items
- Use `lib.optionalAttrs` for conditional attribute sets
- Prefer `lib.mkEnableOption` for boolean enable flags
- Use `lib.mkPackageOption` for package options
- Pass settings through `specialArgs`/`extraSpecialArgs`
- Check platform with `pkgs.stdenv.isLinux` and `pkgs.stdenv.isDarwin`
- Before claiming confirmed Nix changes, run a safe build/dry-run that evaluates each affected configuration, e.g. `nix build --dry-run .#nixosConfigurations.<host>.config.system.build.toplevel --show-trace` or `nix build --dry-run .#homeConfigurations.<profile>.activationPackage --show-trace`
- Do not validate by activating or deploying (`home-manager switch`, `nixos-rebuild switch`, `make <profile>`, deploy commands) unless the user explicitly asks for it
