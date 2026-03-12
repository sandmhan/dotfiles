# Home Manager Profile System

This directory contains the new profile-based configuration system that uses `mkOption` for flexible, declarative configuration management.

## Available Profiles

- **`terminal.nix`** - Terminal-focused environment (base for all other profiles)
- **`desktop.nix`** - Full desktop environment with GUI applications
- **`macos.nix`** - macOS-optimized terminal configuration
- **`wsl.nix`** - WSL-optimized configuration with container tools

## Creating Custom Profiles

You can create your own profiles by:

1. Creating a new file in this directory
2. Importing the base profile you want to extend
3. Setting custom options

### Example: Gaming Profile

```nix
# gaming.nix
{
  lib,
  ...
}:
{
  imports = [
    ./desktop.nix  # Extend desktop profile
  ];

  myHome = {
    profiles = {
      enableGaming = true;           # Override desktop default
      enableVirtualization = true;  # Enable for game dev
    };

    features = {
      enableContainerTools = true;  # For game servers
    };
  };
}
```

### Example: Development-Only Server

```nix
# devserver.nix
{
  lib,
  ...
}:
{
  imports = [
    ./terminal.nix
  ];

  myHome = {
    profiles = {
      enableDevelopment = true;
      enableVirtualization = true;
    };

    features = {
      enableContainerTools = true;
      enableAdvancedShell = true;
      enableSecurity = true;  # VPN for remote work
    };

    platform = {
      isHeadless = true;
    };
  };
}
```

## Available Options

See `../options.nix` for the complete list of available options.

### Profile Options (`myHome.profiles`)
- `enableDesktop` - GUI applications and window manager
- `enableDevelopment` - Development tools and IDE configs
- `enableGaming` - Gaming packages
- `enableMedia` - Media applications
- `enableOffice` - Office suite and productivity apps
- `enableSocial` - Social applications
- `enableVirtualization` - Virtualization tools

### Feature Options (`myHome.features`)
- `enableAdvancedShell` - Enhanced shell with starship, direnv, zoxide
- `enableGitExtensions` - Advanced git tools (gitui, gh, lazygit)
- `enableTerminalUtils` - Terminal utilities (ripgrep, fd, bat, eza)
- `enableClaudeCode` - Claude Code configuration
- `enableNixvim` - Neovim configuration
- `enableContainerTools` - Docker/Podman tools
- `enableTheming` - Stylix theming system
- `enableSecurity` - Security tools (Bitwarden, VPN)

### Platform Options (`myHome.platform`)
- `isHeadless` - Headless system configuration
- `isWSL` - WSL-specific optimizations
- `enableLinuxSpecific` - Linux-specific packages
- `enableDarwinSpecific` - macOS-specific packages

## Usage Examples

```bash
# Use existing profiles
make sandmhan     # Desktop profile
make macman       # macOS profile
make wslman       # WSL profile
make terminalman  # Terminal-only profile

# Add custom profile to flake.nix:
customProfile = mkHomeConfiguration "x86_64-linux" linuxUserSettings [
  ./home/profiles/custom.nix
  nixvim.homeModules.nixvim
  stylix.homeModules.stylix
  nvf.homeManagerModules.default
];
```