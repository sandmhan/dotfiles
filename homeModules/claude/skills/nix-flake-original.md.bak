# Nix Flake Development Skill

This skill provides guidance for working with Nix flake-based repositories, including dotfile configurations, NixOS systems, Home Manager, and development environments.

## Documentation Lookup

### Finding Valid Options

When you need to find valid Nix options, use these resources based on the nixpkgs channel:

1. **NixOS Options** (system-level):
   - Search: `https://search.nixos.org/options`
   - For unstable channel: `https://search.nixos.org/options?channel=unstable`
   - For stable (e.g., 24.11): `https://search.nixos.org/options?channel=24.11`

2. **Home Manager Options**:
   - Unstable: `https://home-manager-options.extranix.com/?query=&release=master`
   - Stable: `https://home-manager-options.extranix.com/?query=&release=release-24.11`

3. **Nix Packages Search**:
   - `https://search.nixos.org/packages`

4. **Flake Input Documentation**:
   - Check the flake.lock for exact revisions
   - Use `nix flake metadata` to see input URLs
   - Visit the GitHub/source repo for input-specific options

### Determining Channel from Flake

```bash
# Check which nixpkgs channel is used
nix flake metadata --json | jq '.locks.nodes.nixpkgs.locked.ref // .locks.nodes.nixpkgs.locked.rev'

# Or read flake.lock directly
cat flake.lock | jq '.nodes.nixpkgs.locked'
```

Common patterns:
- `nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"` -> unstable channel
- `nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11"` -> 24.11 stable
- `nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable"` -> unstable (non-NixOS)

## Nix Commands Reference

### Flake Operations

```bash
# Update all flake inputs
nix flake update

# Update specific input
nix flake update <input-name>

# Show flake outputs
nix flake show

# Show flake metadata and inputs
nix flake metadata

# Check flake for errors
nix flake check

# Lock file operations
nix flake lock --update-input <name>
```

### Building and Evaluating

```bash
# Build a flake output
nix build .#<output>

# Build NixOS system
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel

# Evaluate without building (check for syntax/eval errors)
nix eval .#<output> --json

# Show derivation details
nix derivation show .#<output>

# Evaluate NixOS option
nix eval .#nixosConfigurations.<hostname>.config.<option> --json
```

### NixOS Rebuild Commands

```bash
# Local rebuild
sudo nixos-rebuild switch --flake .#<hostname>

# Build without switching
nixos-rebuild build --flake .#<hostname>

# Test configuration (switch back on reboot)
sudo nixos-rebuild test --flake .#<hostname>

# Remote deployment
nixos-rebuild switch --target-host user@host --flake .#<hostname> --use-remote-sudo

# Build Proxmox VMA image
nixos-rebuild build-image --image-variant proxmox --flake .#<hostname>
```

### Home Manager Commands

```bash
# Apply home-manager configuration (standalone)
home-manager switch --flake .#<username>

# Build without applying
home-manager build --flake .#<username>

# Show current generation
home-manager generations

# List available packages in profile
home-manager packages
```

### Debugging and Inspection

```bash
# Enter nix repl with flake loaded
nix repl .#

# In repl, access outputs:
# :lf .  (load flake)
# nixosConfigurations.<hostname>.config.<option>

# Trace evaluation
nix eval .#<output> --show-trace

# Find why a package is included
nix why-depends .#<output> nixpkgs#<package>

# Show runtime dependencies
nix path-info -rsh .#<output>
```

### Development Shells

```bash
# Enter development shell
nix develop

# Enter specific devShell
nix develop .#<shell-name>

# Run command in dev shell without entering
nix develop --command <cmd>

# Use direnv for automatic shell activation
# Add to .envrc: use flake
```

## Module Writing Patterns

### Standard Module Structure

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.myModule.feature;
in
{
  options.myModule.feature = {
    enable = lib.mkEnableOption "my feature";

    package = lib.mkPackageOption pkgs "package-name" { };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Configuration settings";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra configuration lines";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    # Conditional configuration
    services.myService = {
      enable = true;
      settings = cfg.settings;
    };
  };
}
```

### Home Manager Module Pattern

```nix
{ config, lib, pkgs, userSettings, ... }:

let
  cfg = config.myHomeModule;
in
{
  options.myHomeModule = {
    enable = lib.mkEnableOption "my home feature";
  };

  config = lib.mkIf cfg.enable {
    # Platform-specific packages
    home.packages = with pkgs; [
      common-package
    ] ++ lib.optionals pkgs.stdenv.isLinux [
      linux-only-package
    ] ++ lib.optionals pkgs.stdenv.isDarwin [
      macos-only-package
    ];

    programs.myProgram = {
      enable = true;
    };
  };
}
```

### Cross-Platform Module Pattern

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.crossPlatform;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
  isWSL = builtins.getEnv "WSL_DISTRO_NAME" != "";
in
{
  config = lib.mkIf cfg.enable {
    # Platform branching
    home.packages = lib.mkMerge [
      (lib.mkIf isLinux [ pkgs.linux-pkg ])
      (lib.mkIf isDarwin [ pkgs.darwin-pkg ])
      (lib.mkIf isWSL [ pkgs.wsl-pkg ])
    ];

    # Or use conditional attributes
    programs.tool.settings = {
      common = "value";
    } // lib.optionalAttrs isLinux {
      linuxOnly = "value";
    } // lib.optionalAttrs isDarwin {
      darwinOnly = "value";
    };
  };
}
```

### Flake Module Imports Pattern

```nix
# In flake.nix
{
  outputs = { nixpkgs, home-manager, ... }@inputs:
  let
    # Shared settings passed to all modules
    userSettings = {
      username = "user";
      email = "user@example.com";
      dotfilesDir = "/home/user/dotfiles";
    };

    systemSettings = {
      hostname = "myhost";
      timezone = "America/New_York";
    };
  in {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit userSettings systemSettings inputs; };
      modules = [
        ./hosts/myhost/configuration.nix
        ./systemModules/common.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.extraSpecialArgs = { inherit userSettings inputs; };
          home-manager.users.${userSettings.username} = import ./home.nix;
        }
      ];
    };
  };
}
```

## Development Environment Patterns

### Entering a Flake DevShell

When working in a repository that uses Nix for development:

1. **Check for flake.nix with devShells**:
   ```bash
   nix flake show 2>/dev/null | grep -A5 devShells
   ```

2. **Enter the development shell**:
   ```bash
   nix develop
   # Or for a specific shell:
   nix develop .#<shell-name>
   ```

3. **Check for direnv integration**:
   ```bash
   # If .envrc exists with "use flake", direnv handles shell automatically
   cat .envrc
   direnv allow  # Enable if needed
   ```

### DevShell Definition Pattern

```nix
{
  outputs = { nixpkgs, ... }:
  let
    forAllSystems = nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  in {
    devShells = forAllSystems (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nixfmt-rfc-style
            nil  # Nix LSP
            statix  # Nix linter
          ];

          shellHook = ''
            echo "Nix development environment loaded"
          '';
        };
      }
    );
  };
}
```

## Proxmox/Homelab Patterns

### VM Configuration Module

```nix
# hosts/server/default.nix - Base Proxmox VM config
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./ssh.nix
  ];

  # QEMU guest agent for Proxmox integration
  services.qemuGuest.enable = true;

  # Disable unnecessary services for VM
  boot.loader.grub.device = "/dev/vda";

  system.stateVersion = "24.11";
}
```

### VMA Image Configuration

```nix
# hosts/server/image.nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-image.nix")
  ];

  proxmox = {
    qemuConf = {
      cores = 2;
      memory = 2048;
      bios = "ovmf";
      net0 = "virtio=00:00:00:00:00:00,bridge=vmbr0,firewall=1";
    };
  };
}
```

### Service Module Pattern (Homelab)

```nix
# systemModules/myservice.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.myService;
in
{
  options.services.myService = {
    enable = lib.mkEnableOption "My homelab service";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port to listen on";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/myservice";
      description = "Data directory";
    };
  };

  config = lib.mkIf cfg.enable {
    # OCI container example
    virtualisation.oci-containers.containers.myservice = {
      image = "myservice:latest";
      ports = [ "${toString cfg.port}:8080" ];
      volumes = [ "${cfg.dataDir}:/data" ];
    };

    # Or native NixOS service
    systemd.services.myservice = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.myservice}/bin/myservice";
        StateDirectory = "myservice";
      };
    };

    # Firewall
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
```

## Common Flake Input Patterns

### nvf (Neovim Framework)

```nix
{
  inputs.nvf.url = "github:notashelf/nvf";

  outputs = { nvf, ... }: {
    homeConfigurations.user = {
      imports = [ nvf.homeManagerModules.default ];
      programs.nvf = {
        enable = true;
        settings = {
          vim.languages.nix.enable = true;
        };
      };
    };
  };
}
```

### Stylix (Theming)

```nix
{
  inputs.stylix.url = "github:danth/stylix";

  outputs = { stylix, ... }: {
    nixosConfigurations.host = {
      imports = [ stylix.nixosModules.stylix ];
      stylix = {
        enable = true;
        image = ./wallpaper.png;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
      };
    };
  };
}
```

### Home Manager (Standalone)

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { home-manager, nixpkgs, ... }: {
    homeConfigurations.user = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [ ./home.nix ];
    };
  };
}
```

## Verification Commands

Before making changes, verify the current state:

```bash
# Check if flake evaluates without errors
nix flake check

# Test NixOS configuration builds
nix build .#nixosConfigurations.<host>.config.system.build.toplevel --dry-run

# Test Home Manager configuration
nix build .#homeConfigurations.<user>.activationPackage --dry-run

# Verify a specific option value
nix eval .#nixosConfigurations.<host>.config.services.myservice.enable

# List all packages in a configuration
nix eval .#nixosConfigurations.<host>.config.environment.systemPackages --json | jq

# Format check
nixfmt --check .
```

## Troubleshooting

### Common Errors

1. **Infinite recursion**: Usually caused by circular imports or `config` references in `options`
   - Use `lib.mkDefault` or `lib.mkOverride` to break cycles

2. **Attribute not found**: Check the channel version matches documentation
   - Verify input follows: `inputs.nixpkgs.follows = "nixpkgs"`

3. **Hash mismatch**: Update the flake lock
   ```bash
   nix flake update <input>
   ```

4. **Build failures on different platforms**:
   - Use `lib.optionals pkgs.stdenv.isLinux/isDarwin`
   - Check `meta.platforms` for package availability

### Debug Evaluation

```bash
# Verbose evaluation with trace
nix eval .#<output> --show-trace 2>&1 | head -100

# Enter repl to inspect interactively
nix repl
:lf .
# Now tab-complete to explore: nixosConfigurations.<tab>
```

## Best Practices

1. **Module Organization**:
   - `homeModules/` - User-level configuration modules
   - `systemModules/` - System-level NixOS modules
   - `hosts/<hostname>/` - Host-specific configurations
   - Keep modules focused and single-purpose

2. **Settings Pattern**:
   - Define `userSettings`/`systemSettings` in flake.nix
   - Pass via `specialArgs`/`extraSpecialArgs`
   - Access in modules as function arguments

3. **Platform Support**:
   - Always check `pkgs.stdenv.isLinux/isDarwin`
   - Use `forAllSystems` helper for multi-platform outputs
   - Test configurations on target platforms

4. **Formatting**:
   - Use `nixfmt` (nixfmt-rfc-style) for consistent formatting
   - Run before commits: `nixfmt .`

5. **Documentation**:
   - Add `description` to all `mkOption` definitions
   - Comment complex expressions
   - Maintain CLAUDE.md with project-specific commands
