# 🧩 NixOS & Home Manager Configuration

This directory contains all configuration files for managing both **NixOS** systems and **Home Manager** environments using a unified **flake-based** setup.

---

## 🗂 Folder Structure

```plaintext
.
├── configs // Non-nix configurations
│   └── keyboard
│       └── silakka54
│           └── sandmhan
│               ├── config.h
│               └── keymap.c
├── configuration.nix // DD configuration
├── flake.lock
├── flake.nix // High-level flake for defining DD host and homelab
├── hardware-configuration.nix // DD hardware config
├── homeModules // homemanager configurations
│   ├── bluetooth.nix
│   ├── browser.nix
│   ├── git.nix
│   ├── login.nix
│   ├── nvf.nix
│   ├── nvim.nix
│   ├── rofi.nix
│   ├── stylix.nix
│   ├── terminal.nix
│   └── wm.nix
├── home.nix // base homemanager module
├── hosts // hosts defined and organized for homelab
│   ├── nvr // Video recorder
│   │   ├── default.nix
│   │   └── frigate.nix
│   └── server // baseline proxmox server config
│       ├── default.nix
│       ├── hardware-configuration.nix
│       ├── networking.nix
│       └── ssh.nix
├── Makefile // Recipes for easy rebuilds
├── README.md // You are here!
├── scripts // fun script stuff. Should be moved
│   └── webcam.sh
└── systemModules // standard Nix modules
    ├── frigate.nix
    ├── jellyfin.nix
    └── matrix.nix
```


---

## ⚙️ Overview

This repository uses **Nix flakes** to declaratively manage both system and user environments.
It unifies **NixOS**, **Home Manager**, and **Stylix** configuration into one reproducible setup that can be applied to multiple systems or users.

Key components:
- **NixOS** for system-level configuration
- **Home Manager** for user-level configuration
- **Stylix** for theming and font consistency
- **Makefile** for quick rebuild commands

---

## 🧑‍💻 Home Manager

### 🔧 Configuration

Your user configuration lives in [`home.nix`](./home.nix).
It manages:
- Shell setup and environment variables
- Terminal and editor configuration (Alacritty, Nixvim, etc.)
- Fonts and color themes (via Stylix)
- Installed CLI tools and desktop apps

### ▶️ Usage

The provided `Makefile` defines shortcuts for applying specific Home Manager profiles:

```makefile
.PHONY: macman sandmhan

macman sandmhan:
	home-manager switch --flake .#$@

Each target corresponds to a homeConfigurations entry in flake.nix.
Run one of the following commands from the repository root:

```bash
# Apply Home Manager configuration for macOS user
make macman

# Apply Home Manager configuration for Linux user
make sandmhan
```

## 🖥️ NixOS (System-Level)

Your system-level configuration is defined in:
configuration.nix
hardware-configuration.nix
To rebuild your NixOS system:

```bash
sudo nixos-rebuild switch --flake .#sandmhan
```


## HomeLab

This homelab is currently set up on Proxmox with nixos VMs defined for various services deployed for use. This currently includes:

- Frigate for network video recording
- Jellyfin for media serving
- Matrix for anti-discord communication



### Spinning up new VM

This procedure is facilitated through Proxmox's `qmrestore` command that allows for creating a VM through providing a VMA file. This can be created using the `initialProxmoxVMA` host defined in `flake.nix` through the following command: `nixos-rebuild build-image --image-variant proxmox --flake .#initialProxmoxVMA`


This will create a `vma.zst` file that can then be transferred over to the Proxmox host and used to restore a new VM with `qmrestore /var/lib/vz/dump/<transferred_file>.vma.zst <VM_ID> --storage local-zfs --force`

> Note: if provisioned resources need to be modified, CPU cores and RAM can be changed through `qm set <vmid> --<cores/memory> <value>`
> If storage needs to be changed, it may be smoother to just regenerate the VMA with a different disk size

### Copying a flake host configuration to the new VM

Build the config locally and push to the remote host: `nixos-rebuild switch --target-host sandmhan@<target_hostname or ip> --flake .#<target_configuration> --sudo`
