# 🧩 NixOS & Home Manager Configuration

This directory contains all configuration files for managing both **NixOS** systems and **Home Manager** environments using a unified **flake-based** setup.

---

## 🗂 Folder Structure

```plaintext
├── configuration.nix # System-level configuration (for NixOS)
├── hardware-configuration.nix # Auto-generated hardware config (for NixOS)
├── home.nix # User-level Home Manager configuration
├── flake.nix # Main Nix flake definition (entry point)
├── flake.lock # Version lock for reproducibility
├── themes/ # Color schemes, fonts, or Stylix-related files
├── Makefile # Simple build shortcuts
└── README.md # This documentation
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


