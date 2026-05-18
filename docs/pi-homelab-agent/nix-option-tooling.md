# Nix Option and Documentation Tooling

## Goal

Provide structured tools that let pi discover available Nix options before proposing or editing configuration. The tooling should work across standard NixOS modules, Home Manager modules, and options exposed by flake inputs such as `sops-nix`, `stylix`, and `nvf`.

## Why this matters

Nix agents often guess option names or module shapes. This repo combines several option namespaces:

- NixOS core options.
- Home Manager options.
- Custom `home/options.nix` options.
- Service modules under `systemModules/`.
- Flake input modules from `stylix`, `sops-nix`, `nvf`, and `nixos-hardware`.
- Host-specific `specialArgs` such as `userSettings` and `systemSettings`.

A structured tool should make pi query the option surface instead of guessing.

## Proposed tools

### `nix_option_search`

Search available options for a given context.

Parameters:

```text
context: nixos | home-manager | host | flake-input
host: optional flake config name, such as gaia or lxc-monitor
query: search string, such as services.grafana or stylix
input: optional flake input name, such as sops-nix or nvf
```

Returns:

- matching option paths
- type
- default
- example when available
- declaration file
- description excerpt

### `nix_option_show`

Show one option in full.

Parameters:

```text
context
host optional
option path
```

Returns full metadata and declaration locations.

### `nix_config_eval`

Evaluate a host's resolved config path safely.

Examples:

```text
config.services.openssh.enable
config.networking.firewall.allowedTCPPorts
config.myHome.ai.enableCodex
```

Should support both NixOS and Home Manager configurations.

### `nix_flake_inventory`

Summarize flake outputs:

- `nixosConfigurations`
- `homeConfigurations`
- formatters
- relevant packages/apps/checks if added later

For this repo, it should identify host config names and their imported module roots.

### `nix_module_trace`

Given an option or file, identify where it enters a host config.

Examples:

- Which hosts import `systemModules/matrix.nix`?
- Which hosts use `hosts/lxc-base/default.nix`?
- Which profiles import `home/modules/ai-codex.nix`?

## Possible implementation approaches

### Option JSON generation

Use Nix's option documentation builders where possible to produce JSON. Candidate commands depend on context and may require experimentation:

- `nix eval .#nixosConfigurations.<host>.options.<path>`
- `nix eval .#nixosConfigurations.<host>.config.<path>`
- `nix eval .#homeConfigurations.<name>.options.<path>`
- custom helper expressions that import `<nixpkgs/nixos>` or Home Manager modules and output option metadata

The extension should hide command complexity behind stable tool output.

### Repository-specific helper expressions

This repo may benefit from checked-in helper files under a future path such as:

```text
.pi/nix/
  options.nix
  host-inventory.nix
  home-options.nix
```

These helpers can expose machine-readable JSON for pi without forcing the LLM to write ad hoc Nix expressions each time.

### Cache option indexes

Option metadata can be large. The extension should cache generated indexes by:

- flake lock hash
- host config name
- context type
- timestamp

Cache invalidation can be based on `flake.lock`, `flake.nix`, and module file mtimes.

## Suggested behavior

Before editing Nix config, pi should prefer this flow:

1. Identify target context: NixOS host, Home Manager profile, or shared module.
2. Query candidate options with `nix_option_search`.
3. Inspect exact option metadata with `nix_option_show`.
4. Evaluate current resolved config if relevant.
5. Propose or edit config.
6. Run formatting and a targeted eval/dry-build.

## Useful repo-specific contexts

### NixOS hosts

From `flake.nix`:

- `gaia`
- `proxmoxBase`
- `initialProxmoxVMA`
- `proxmoxVM`
- `nvr`
- `llama`
- `matrix`
- `git`
- `fitness`
- `homeassistant`
- `media`
- `vpn`
- `monitor`
- `nas`
- `nixos-builder`
- `agent-sandbox`
- `agentVMA`
- `gaming`
- `initialLXC`
- `lxc-matrix`
- `lxc-monitor`
- `lxc-git`
- `lxc-homeassistant`
- `lxc-nas`

### Home Manager profiles

- `sandmhan`
- `macman`
- `wslman`
- `terminalman`

### Important flake inputs

- `nixpkgs`
- `home-manager`
- `stylix`
- `nvf`
- `sops-nix`
- `nixos-hardware`

## Open questions

- Should option indexes be generated globally per nixpkgs revision or per project?
- Should pi expose raw option metadata to the model or summarize it first?
- How should custom repo options under `home/options.nix` and future systemModules options be indexed?
- Can this be packaged as a reusable global Nix extension with repo-local adapters?
