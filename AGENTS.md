# Repository Guidelines

## Project Structure & Module Organization

This repository is a flake-based Nix configuration for NixOS hosts and Home Manager profiles.

- `flake.nix` defines inputs, shared helpers, and exported `nixosConfigurations` and Home Manager profiles.
- `hosts/` contains machine-specific NixOS configs such as `hosts/gaia/`, `hosts/media/`, and `hosts/server/`.
- `systemModules/` contains reusable service modules. Add new services here, especially when native NixOS modules are missing and an OCI container is required.
- `home/modules/` and `home/profiles/` contain the option-based Home Manager setup; `home/options.nix` defines user-facing options.
- `themes/` stores theme definitions, `docs/` holds operational docs, and `secrets/` stores encrypted secret material by service or host.

All Proxmox VMs should extend `hosts/server/default.nix` and include `qemuGuest.enable`.

## Build, Test, and Development Commands

- `make sandmhan` applies the main Linux desktop Home Manager profile.
- `make macman`, `make wslman`, `make terminalman` apply the other supported Home Manager profiles.
- `make gaia` rebuilds the local NixOS host.
- `make update` refreshes flake inputs.
- `nix build --dry-run .#nixosConfigurations.<host>.config.system.build.toplevel` validates a host configuration before deployment.
- `nixos-rebuild switch --target-host <host> --flake .#<host>` deploys to a remote machine.

## Coding Style & Naming Conventions

Format all Nix files with `nixfmt`. Use two-space indentation and keep attribute sets readable. Prefer `lib.mkIf`, `lib.mkMerge`, `lib.optionals`, and `lib.optionalAttrs` for conditional logic. Use `lib.mkEnableOption` for boolean flags and `lib.mkPackageOption` for package selections. Pass shared settings through `specialArgs` or `extraSpecialArgs`.

Name hosts and modules by responsibility: `hosts/<machine>/default.nix`, `systemModules/<service>.nix`, and `home/modules/<feature>.nix`.

## Testing Guidelines

There is no separate unit test suite; evaluation is the primary safety check. Run `nix build --dry-run` for any affected host or profile before opening a PR. For Home Manager changes, also run the relevant `make <profile>` target locally when safe.

Editor/NVF behavior changes must include validation evidence in the PR body or under `docs/test/evidence/`: the phase check scripts run, Home Manager dry-runs for affected profiles, and runtime `nvim --headless "+checkhealth" "+qa"` or scoped `checkhealth` output when plugin, LSP, Treesitter, DAP, AI bridge, or startup behavior changes. If validation is skipped, state the reason and list the affected profiles explicitly.

## Commit & Pull Request Guidelines

Follow the existing Conventional Commit style visible in history: `feat:`, `fix:`, and `docs:`. Keep commits scoped to one logical change. PRs should include the target host or profile, a short risk summary, validation commands run, and screenshots only for UI-facing changes such as Waybar or theming updates. For NVF import changes, confirm `README.md` and `docs/neovim-ide.md` stayed synchronized with `home/modules/nvf/default.nix`.

## Security & Configuration Tips

Never commit decrypted secrets. Keep secret changes under the appropriate `secrets/` subtree and document any required host-specific rollout steps in `docs/` when behavior changes.
