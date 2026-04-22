---
name: nix-best-practices
description: "Use when establishing Nix project structure, coding standards, or development workflows"
---

# Nix Best Practices

## Module Organization

### Directory Structure

```
.
├── flake.nix                    # Entry point and outputs
├── flake.lock                  # Locked input revisions
├── home/                       # Home Manager profiles and options
│   ├── profiles/              # Composable configuration profiles
│   ├── implementations/       # Implementation modules
│   └── options.nix           # Centralized option definitions
├── homeModules/               # Legacy user environment modules
├── systemModules/             # System-level NixOS modules
├── hosts/                     # Host-specific configurations
│   └── <hostname>/
│       ├── configuration.nix
│       ├── hardware-configuration.nix
│       └── networking.nix
└── assets/                    # Templates and shared resources
```

### Module Responsibilities

1. **homeModules/**: User-level configuration modules
   - Keep modules focused and single-purpose
   - Use conditional logic for platform differences
   - Prefer options over direct configuration

2. **systemModules/**: System-level NixOS modules
   - Service configurations
   - Homelab and infrastructure services
   - Hardware-specific settings

3. **hosts/<hostname>/**: Host-specific configurations
   - Hardware configuration
   - Hostname-specific overrides
   - Import relevant modules

## Settings Pattern

### Centralized Configuration

Define shared settings in `flake.nix` and pass to all modules:

```nix
# In flake.nix
let
  userSettings = {
    username = "user";
    email = "user@example.com";
    dotfilesDir = "/home/user/dotfiles";
    gitUsername = "user";
  };

  systemSettings = {
    hostname = "myhost";
    timezone = "America/New_York";
    locale = "en_US.UTF-8";
  };
in {
  nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
    specialArgs = { inherit userSettings systemSettings inputs; };
    # ...
  };

  homeConfigurations.user = home-manager.lib.homeManagerConfiguration {
    extraSpecialArgs = { inherit userSettings inputs; };
    # ...
  };
}
```

### Module Access Pattern

```nix
# In modules
{ config, lib, pkgs, userSettings, systemSettings ? null, ... }:

{
  # Use settings throughout the module
  programs.git = {
    enable = true;
    userName = userSettings.gitUsername;
    userEmail = userSettings.email;
  };
}
```

## Platform Support

### Cross-Platform Compatibility

Always check platform when defining packages or configurations:

```nix
{ config, lib, pkgs, ... }:

let
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
  isWSL = builtins.getEnv "WSL_DISTRO_NAME" != "";
in
{
  # Platform-specific packages
  home.packages = with pkgs; [
    # Common packages
    git
    neovim
  ] ++ lib.optionals isLinux [
    # Linux-specific
    xclip
    linux-package
  ] ++ lib.optionals isDarwin [
    # macOS-specific
    pbcopy
    darwin-package
  ] ++ lib.optionals isWSL [
    # WSL-specific
    wsl-package
  ];

  # Platform-specific configuration
  programs.tool.settings = {
    common = "value";
  } // lib.optionalAttrs isLinux {
    linuxOnly = "linux-value";
  } // lib.optionalAttrs isDarwin {
    darwinOnly = "darwin-value";
  };
}
```

### Multi-System Flake Outputs

Use the `forAllSystems` pattern for outputs that need to work across architectures:

```nix
let
  forAllSystems = nixpkgs.lib.genAttrs [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];
in {
  packages = forAllSystems (system:
    let pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.hello;
      myPackage = pkgs.callPackage ./pkgs/mypackage { };
    }
  );

  devShells = forAllSystems (system:
    let pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [ nixfmt-rfc-style nil ];
      };
    }
  );
}
```

## Code Quality Standards

### Formatting

1. **Use nixfmt-rfc-style** for consistent formatting:
   ```bash
   nixfmt .                    # Format all .nix files
   nixfmt --check .            # Check formatting without changes
   ```

2. **Pre-commit checks**:
   ```nix
   # In devShell
   shellHook = ''
     echo "Run 'nixfmt .' before committing"
   '';
   ```

### Option Definitions

Always provide clear, typed options:

```nix
{ config, lib, ... }:

let
  cfg = config.myModule;
in
{
  options.myModule = {
    enable = lib.mkEnableOption "my module";

    package = lib.mkPackageOption pkgs "package-name" { };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port to listen on";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Configuration settings";
      example = { key = "value"; };
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra configuration lines";
    };
  };

  config = lib.mkIf cfg.enable {
    # Implementation
  };
}
```

### Error Prevention

1. **Use lib functions** instead of raw logic:
   ```nix
   # Good
   lib.mkIf cfg.enable { ... }
   lib.optionals condition [ item ]
   lib.optionalAttrs condition { attr = value; }

   # Avoid
   if cfg.enable then { ... } else { }
   ```

2. **Validate inputs**:
   ```nix
   options.myOption = lib.mkOption {
     type = lib.types.enum [ "option1" "option2" "option3" ];
     # Instead of just lib.types.str
   };
   ```

## Development Workflow

### Testing and Validation

Before committing changes:

```bash
# 1. Check flake validity
nix flake check

# 2. Test configuration builds
nix build --dry-run .#nixosConfigurations.<hostname>.config.system.build.toplevel
nix build --dry-run .#homeConfigurations.<user>.activationPackage

# 3. Format check
nixfmt --check .

# 4. Evaluate specific options
nix eval .#nixosConfigurations.<hostname>.config.services.myservice.enable
```

### Incremental Development

1. **Use nix develop** for consistent environments:
   ```nix
   devShells.default = pkgs.mkShell {
     packages = with pkgs; [
       nixfmt-rfc-style
       nil  # Nix LSP
       statix  # Nix linter
     ];
   };
   ```

2. **Test changes in isolation**:
   ```bash
   # Test just Home Manager
   home-manager build --flake .#<user>

   # Test just NixOS
   nixos-rebuild build --flake .#<hostname>
   ```

## Documentation Standards

### Module Documentation

1. **Always describe options**:
   ```nix
   myOption = lib.mkOption {
     type = lib.types.bool;
     default = false;
     description = ''
       Enable my feature. This will install the required packages
       and configure the service.
     '';
     example = true;
   };
   ```

2. **Comment complex logic**:
   ```nix
   # Generate service configuration based on user preferences
   # Combines base config with user overrides
   serviceConfig = baseConfig // userOverrides // {
     # Always override these for security
     User = "nobody";
     Group = "nobody";
   };
   ```

### Project Documentation

Maintain project-specific documentation:

1. **CLAUDE.md**: Claude Code instructions and common commands
2. **README.md**: Project overview and setup instructions
3. **Module READMEs**: For complex module subdirectories

### Version Management

1. **Pin inputs in flake.lock**: Always commit lock file changes
2. **Update inputs carefully**:
   ```bash
   nix flake update              # Update all inputs
   nix flake update nixpkgs      # Update specific input
   ```
3. **Test after updates**: Run full build tests after input updates

## Security Considerations

### Least Privilege

1. **User vs system packages**: Prefer user-level installation
2. **Service isolation**:
   ```nix
   systemd.services.myservice = {
     serviceConfig = {
       User = "myservice";
       Group = "myservice";
       PrivateTmp = true;
       ProtectSystem = "strict";
       ProtectHome = true;
       NoNewPrivileges = true;
     };
   };
   ```

### Input Validation

1. **Validate external inputs**:
   ```nix
   assertions = [
     {
       assertion = cfg.port > 1024;
       message = "Port must be > 1024 for non-root services";
     }
   ];
   ```

2. **Use proper types**: Prefer `lib.types.port` over `lib.types.int` for ports