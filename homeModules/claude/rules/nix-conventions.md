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
