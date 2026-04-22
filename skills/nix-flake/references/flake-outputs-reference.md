# Flake Outputs Reference

## Standard Output Types

### `packages.<system>.<name>`

Derivations buildable with `nix build`.

```nix
packages.x86_64-linux.default = pkgs.callPackage ./pkg.nix { };
packages.x86_64-linux.myTool = pkgs.writeShellApplication { name = "mytool"; text = "echo hi"; };
```
```bash
nix build .#myTool
nix build .#packages.x86_64-linux.myTool
```

### `devShells.<system>.<name>`

Development environments entered with `nix develop`.

```nix
devShells.x86_64-linux.default = pkgs.mkShell {
  packages = [ pkgs.nodejs pkgs.nixfmt-rfc-style ];
};
```
```bash
nix develop
nix develop .#myShell
```

### `apps.<system>.<name>`

Runnable programs (thin wrapper over a package binary).

```nix
apps.x86_64-linux.default = {
  type = "app";
  program = "${self.packages.x86_64-linux.myTool}/bin/mytool";
};
```
```bash
nix run .#default
```

### `checks.<system>.<name>`

CI checks run by `nix flake check`.

```nix
checks.x86_64-linux.test = pkgs.runCommand "test" { } ''
  ${pkgs.myTool}/bin/mytool --check && touch $out
'';
```
```bash
nix flake check
nix build .#checks.x86_64-linux.test
```

### `nixosConfigurations.<hostname>`

Full NixOS system configurations.

```nix
nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [ ./hosts/myhost/configuration.nix ];
  specialArgs = { inherit inputs; };
};
```
```bash
nixos-rebuild switch --flake .#myhost
nixos-rebuild build --flake .#myhost
nixos-rebuild test --flake .#myhost
nix build .#nixosConfigurations.myhost.config.system.build.toplevel --dry-run
nix eval .#nixosConfigurations.myhost.config.services.openssh.enable
```

### `darwinConfigurations.<hostname>`

nix-darwin system configurations (macOS).

```nix
darwinConfigurations.macbook = nix-darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = [ ./hosts/macbook/configuration.nix ];
  specialArgs = { inherit inputs; };
};
```
```bash
darwin-rebuild switch --flake .#macbook
```

### `homeConfigurations.<name>`

Standalone Home Manager configurations.

```nix
homeConfigurations.user = home-manager.lib.homeManagerConfiguration {
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  modules = [ ./home.nix ];
  extraSpecialArgs = { inherit inputs; };
};
```
```bash
home-manager switch --flake .#user
home-manager build --flake .#user
nix build .#homeConfigurations.user.activationPackage --dry-run
```

### `overlays.<name>`

Nixpkgs overlays — modify or add packages.

```nix
overlays.default = final: prev: {
  myPkg = final.callPackage ./pkgs/mypkg { };
};
```

Apply in a configuration:
```nix
nixpkgs.overlays = [ self.overlays.default ];
```

### `nixosModules.<name>`

Reusable NixOS modules for import by consumers.

```nix
nixosModules.default = import ./modules/myservice.nix;
nixosModules.myservice = { config, lib, pkgs, ... }: { /* ... */ };
```

Import in a consumer flake:
```nix
modules = [ inputs.myflake.nixosModules.default ];
```

### `lib`

Library functions exported for use by other flakes.

```nix
lib = {
  mkHost = args: nixpkgs.lib.nixosSystem (args // { /* defaults */ });
};
```

### `templates.<name>`

Flake templates for `nix flake init`.

```nix
templates.default = {
  path = ./templates/default;
  description = "A basic project template";
};
```
```bash
nix flake init -t github:user/repo#default
```

## NixOS Rebuild Commands

| Command | Purpose |
|---|---|
| `sudo nixos-rebuild switch --flake .#host` | Build and activate immediately |
| `nixos-rebuild build --flake .#host` | Build only, no activation |
| `sudo nixos-rebuild test --flake .#host` | Activate but revert on reboot |
| `nixos-rebuild switch --target-host user@host --flake .#host --use-remote-sudo` | Remote deployment |
| `nixos-rebuild build-image --image-variant proxmox --flake .#host` | Build Proxmox VMA image |

## Common Flake Input Patterns

### Nixpkgs follows (share single nixpkgs)

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  nix-darwin = {
    url = "github:lnl7/nix-darwin";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

### Multiple nixpkgs channels

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
};

# In outputs, create both package sets:
# pkgs = nixpkgs.legacyPackages.${system};
# pkgs-stable = nixpkgs-stable.legacyPackages.${system};
```

### Custom overlay input

```nix
inputs.my-overlay = {
  url = "github:user/overlay-repo";
  inputs.nixpkgs.follows = "nixpkgs";
};

# Apply: nixpkgs.overlays = [ inputs.my-overlay.overlays.default ];
```

### Non-flake input

```nix
inputs.my-source = {
  url = "github:user/repo/main";
  flake = false;
};

# Use as path: src = inputs.my-source;
```
