# nix-darwin Setup

## Prerequisites

- Nix installed (see `nix-bootstrap` skill)
- macOS 12 Monterey or later
- Flakes enabled (`experimental-features = nix-command flakes` in `~/.config/nix/nix.conf`)

## Flake-Based Installation from Scratch

### 1. Create `flake.nix`

```nix
{
  description = "macOS system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
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
    {
      darwinConfigurations.hostname = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./darwin.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.username = import ./home.nix;
          }
        ];
      };
    };
}
```

Replace `hostname` with your Mac's hostname (`scutil --get LocalHostName`) and `username` with your user.

### 2. Create `darwin.nix` with Minimal Config

```nix
{ pkgs, ... }:
{
  # Required: declare the platform
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable nix-daemon
  services.nix-daemon.enable = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # System packages available to all users
  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  # Set your primary user
  users.users.username = {
    name = "username";
    home = "/Users/username";
  };

  # Used for backward compatibility
  system.stateVersion = 5;
}
```

### 3. First-Time Build

```sh
nix run nix-darwin -- switch --flake .#hostname
```

This bootstraps nix-darwin and activates the configuration.

### 4. Subsequent Rebuilds

```sh
darwin-rebuild switch --flake .#hostname
```

## Migration from Standalone Home Manager

If you currently run standalone HM (`home-manager switch --flake .#username`):

1. **Create the nix-darwin flake** as shown above, adding `home-manager.darwinModules.home-manager` to modules.
2. **Move your HM config** into the `home-manager.users.username` attribute (or import your existing `home.nix`).
3. **Remove the standalone HM flake output** (`homeConfigurations.username`).
4. **Uninstall standalone HM generation** before first darwin-rebuild:
   ```sh
   home-manager uninstall
   ```
5. **Build nix-darwin** which now manages HM as a module:
   ```sh
   nix run nix-darwin -- switch --flake .#hostname
   ```

After migration, `darwin-rebuild switch` handles both system config and home-manager in one command.

## Updating

```sh
nix flake update
darwin-rebuild switch --flake .#hostname
```

To update a single input:

```sh
nix flake update nix-darwin
darwin-rebuild switch --flake .#hostname
```

## Uninstalling nix-darwin

```sh
darwin-rebuild --list-generations  # review what exists
nix run nix-darwin#darwin-uninstaller
```

This reverts system changes made by nix-darwin (environment files, launchd plists, etc.). Nix itself remains installed.

## Troubleshooting

### PATH Issues

nix-darwin manages `/etc/zshenv` and `/etc/zshrc`. If PATH is wrong after switching:

- Check `/etc/static/zshenv` — nix-darwin symlinks this.
- Ensure `programs.zsh.enable = true;` is set in `darwin.nix`.
- Verify `environment.systemPath` includes needed directories.

### Activation Script Failures

```
error: activating system... <some-error>
```

- Read the full error — activation scripts are sequential and the failing one is named.
- Common cause: a `system.defaults` value rejected by macOS. Revert the setting and rebuild.
- If the system is in a broken state, `darwin-rebuild switch` with a known-good config will recover.

### nixbld Users

nix-darwin expects `_nixbld1` through `_nixbldN` users for multi-user Nix. If these are missing or misconfigured:

```sh
# Check existing build users
dscl . -list /Users | grep nixbld
```

The Nix installer normally creates these. If missing, re-run the Nix installer or create them manually per the [Nix manual](https://nixos.org/manual/nix/stable/installation/multi-user).

### Conflicts with Existing Files

nix-darwin may fail if `/etc/nix/nix.conf`, `/etc/shells`, or `/etc/zshrc` already exist and aren't managed by nix-darwin. Back them up and remove them, then rebuild:

```sh
sudo mv /etc/zshrc /etc/zshrc.backup
sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.backup
darwin-rebuild switch --flake .#hostname
```
