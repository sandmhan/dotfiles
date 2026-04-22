# Nix Dotfiles Repository — Structure & Cleanup Analysis

**Revision 2 — April 22, 2026**  
Covers current state, existing technical debt, and how the architecture should evolve to support additional NixOS hosts, nix-darwin systems, and the agent VM roadmap.

---

## 1. Architectural Overview

### What exists today

```
flake.nix
├── nixosConfigurations
│   ├── gaia           → ./configuration.nix  (desktop — Framework 13 AMD)
│   ├── initialProxmoxVMA → ./hosts/server     (base image)
│   ├── proxmoxVM      → ./hosts/server + hw   (generic VM)
│   ├── nvr            → ./hosts/server + hw + ./hosts/nvr
│   ├── llama          → ./hosts/server + hw + ./hosts/llama
│   ├── matrix         → ./hosts/server + hw + ./systemModules/matrix.nix
│   ├── agent-sandbox  → ./hosts/agent + HM inline
│   └── agentVMA       → ./hosts/agent/image.nix
│
├── homeConfigurations
│   ├── sandmhan    → desktop profile  (x86_64-linux)
│   ├── macman      → macos profile    (aarch64-darwin)
│   ├── wslman      → wsl profile      (x86_64-linux)
│   └── terminalman → terminal profile (x86_64-linux)
```

### Two parallel Home Manager systems

The single most consequential structural issue: two layered module systems exist in parallel.

| Layer | Location | Role |
|-------|----------|------|
| **Legacy modules** | `homeModules/*.nix` | Do the actual work — define programs, packages, configs |
| **New option facade** | `home/{options,profiles,implementations}/*.nix` | Define `myHome.*` options; implementations import legacy modules and gate packages behind options |

The new system **wraps** the old one rather than replacing it. Every implementation file contains `import ../../homeModules/foo.nix`. This means the legacy modules are still load-bearing — they are not dead code, they are the actual configuration. The "implementations" are thin wrappers that add conditional logic on top.

**Exception**: `moonlight.nix` and `sunshine.nix` have been fully reimplemented in `home/implementations/` and the legacy versions in `homeModules/` are now orphaned (never imported anywhere).

### Desktop NixOS config lives outside hosts/

`gaia` (the desktop) is defined in root-level `configuration.nix` and `hardware-configuration.nix`, while every other NixOS host lives under `hosts/`. This is the only host that doesn't follow the `hosts/<name>/` convention.

---

## 2. Concrete Issues

### 2.1 Duplicate content (identical files)

These three root-level directories are byte-for-byte copies of content already inside `homeModules/claude/`:

| Root copy | Canonical location | Notes |
|-----------|--------------------|-------|
| `agents/` | `homeModules/claude/agents/` | Identical — 2 files |
| `assets/` | `homeModules/claude/assets/` | Identical — 5 template files |
| `skills/` | `homeModules/claude/skills/` | Near-identical — claude/ has 2 extra files (`nix-best-practices.md`, `nix-homelab.md`) |

These appear to be leftovers from extracting a zip archive. Nothing in the codebase imports from the root copies.

### 2.2 Orphaned files

| File | Evidence | Notes |
|------|----------|-------|
| `home.nix` | Not imported by flake.nix or any module | Superseded by `home/profiles/`. Imports all legacy homeModules directly — the old entry point before the profile system was created. |
| `homeModules/moonlight.nix` | Not imported by any `.nix` file | Replaced by `home/implementations/moonlight.nix` |
| `homeModules/sunshine.nix` | Not imported by any `.nix` file | Replaced by `home/implementations/sunshine.nix` |
| `homeModules/3d_printing.nix` | Not imported by any `.nix` file | Functionality now inline in `home/implementations/desktop.nix` (the `enable3DPrinting` option) |
| `homeModules/nvim.nix` | Commented out in `home.nix`; not imported elsewhere | Replaced by `homeModules/nvf/` |
| `scratch.md` | Development notes | Not documentation |
| `homeModules/claude/skills/nix-flake-original.md.bak` | `.bak` file in git staging | Rename artifact |

### 2.3 Build artifacts and missing .gitignore

There is **no `.gitignore` file** in this repository.

Files that should not be tracked:
- `agent-sandbox.qcow2` (11.3 MB) — QEMU disk image generated during testing
- `result` symlink — Nix build output (currently a tracked symlink)
- Any future `*.qcow2`, `*.vma`, `*.vma.zst` build outputs

### 2.4 Misplaced documentation

| File | Current location | Suggested location |
|------|------------------|--------------------|
| `MOONLIGHT_SUNSHINE_SETUP.md` | Root | `docs/` |
| `homeModules/REMOTE_DESKTOP.md` | `homeModules/` | `docs/` |
| `notes/refactor_suggestions.md` | `notes/` | `docs/` (then remove `notes/` dir) |

### 2.5 Flake repetition — the `systemSettings //` pattern

Six NixOS configurations repeat nearly identical boilerplate:

```nix
specialArgs = {
  userSettings = baseUserSettings;
  systemSettings = systemSettings // { hostname = "nvr"; };
};
```

This copy-paste pattern will worsen as more hosts are added (the llama VM, the agent VM, any future services). A `mkNixosSystem` helper — mirroring the existing `mkHomeConfiguration` — eliminates this.

### 2.6 Both nixvim and nvf loaded everywhere

Every `homeConfiguration` loads both `nixvim.homeModules.nixvim` and `nvf.homeManagerModules.default`. The repository uses nvf for Neovim configuration (`homeModules/nvf/`), and nixvim appears unused. This adds unnecessary evaluation overhead and a confusing extra input.

### 2.7 Git configuration defined three times on agent VM

The agent VM has git configured at three different layers:
1. **System level**: `hosts/agent/agent-tools.nix:201` — `programs.git.config.user`
2. **HM level (claude-agent.nix)**: `homeModules/claude-agent.nix:348` — `programs.git.userName/userEmail` with `mkForce`
3. **HM level (git.nix)**: `homeModules/git.nix:5` — `programs.git.settings.user` (imported via `core.nix`)

Layers 2 and 3 conflict (resolved by `mkForce`), and layer 1 sets the system-wide git config which may or may not be overridden by the user-level config depending on git's config precedence. This is fragile.

### 2.8 `configuration.nix` imports matrix on gaia

Line 18: `./systemModules/matrix.nix` is imported into the desktop system configuration. Matrix is supposed to be its own dedicated VM — having it in the desktop config is likely a leftover from development.

### 2.9 Minor issues from existing `notes/refactor_suggestions.md`

The following issues were already identified by a prior agent analysis and remain valid:
- `nix flake check` fails — `initialProxmoxVMA` and friends lack `fileSystems."/"` 
- `nixfmt` fails on tracked files
- `home/implementations/terminal.nix:44` uses `home.keyboard` which is not a valid Home Manager option (NixOS-only)
- `home/implementations/core.nix:7` declares `cfg = config.myHome` but never uses it
- `system.stateVersion = "26.05"` in `hosts/server/default.nix` — release doesn't exist yet (likely `25.05`)
- `nixpkgs.config.allowBroken = true` set globally in `home/implementations/core.nix`
- `home/profiles/desktop.nix` uses raw `true`/`false` while `terminal.nix` uses `mkDefault` — inconsistent override semantics
- No `formatter`, `devShells`, `checks`, or `templates` flake outputs
- `experimental-features` uses string form in `configuration.nix` vs list form in `hosts/server/default.nix`

### 2.10 `themes/` directory: 50+ directories, zero references

The `themes/` directory contains 58 subdirectories, each with a base16 YAML, wallpaper URL, and metadata. **None of this is referenced by any Nix code.** Stylix uses `pkgs.base16-schemes` (a nixpkgs package) directly:

```nix
base16Scheme = "${pkgs.base16-schemes}/share/themes/${userSettings.theme}.yaml";
```

The local `themes/` directory appears to be a personal collection/reference, not functional configuration. It adds significant noise to the repository.

---

## 3. Future-Proofing: How This Needs to Evolve

### 3.1 Adding more NixOS hosts

The current pattern for adding a new Proxmox VM is:
1. Create `hosts/<name>/default.nix` importing `../server/default.nix`
2. Add a ~15-line block in `flake.nix` with copy-pasted `specialArgs`

**With a helper**, adding a host becomes:

```nix
# Proposed mkNixosSystem helper
mkNixosSystem = { hostname, extraModules ? [], userSettings ? baseUserSettings }:
  nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./hosts/server
      ./hosts/server/hardware-configuration.nix
    ] ++ extraModules;
    specialArgs = {
      inherit userSettings;
      systemSettings = systemSettings // { inherit hostname; };
    };
  };
```

Then each host is one line:
```nix
nvr = mkNixosSystem { hostname = "nvr"; extraModules = [ ./hosts/nvr ]; };
llama = mkNixosSystem { hostname = "llama"; extraModules = [ ./hosts/llama ]; };
matrix = mkNixosSystem { hostname = "matrix"; extraModules = [ ./systemModules/matrix.nix ]; };
```

The agent-sandbox config with inline HM would be a slightly extended variant.

### 3.2 Adding nix-darwin support

Currently `macman` is a standalone Home Manager configuration with no system-level management. To support nix-darwin:

**Required additions:**
1. Add `nix-darwin` input to flake:
   ```nix
   inputs.nix-darwin = {
     url = "github:LnL7/nix-darwin";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   ```
2. Add `darwinConfigurations` output alongside `nixosConfigurations`
3. Create a `hosts/darwin/` (or `hosts/mac/`) directory for system-level macOS config
4. The existing `home/profiles/macos.nix` slots in as the HM layer

**Impact on current structure:**
- The `mkHomeConfiguration` helper needs no changes — it already handles `aarch64-darwin`
- A similar `mkDarwinSystem` helper should be created alongside `mkNixosSystem`
- The `macos.nix` profile already correctly sets `enableDarwinSpecific = true` and `enableLinuxSpecific = false`
- `Makefile` targets need updating to support `darwin-rebuild`

**The `home/options.nix` system is already well-prepared for this** — it has `platform.enableDarwinSpecific` and `platform.enableLinuxSpecific` options. The main gap is the system-level configuration.

### 3.3 Multiple machines per platform

As more hosts accumulate, the `hosts/` directory needs clear conventions:

```
hosts/
├── gaia/                 # Desktop (currently root-level configuration.nix)
│   ├── default.nix
│   └── hardware-configuration.nix
├── server/               # Base template for Proxmox VMs (not a host itself)
│   ├── default.nix
│   ├── hardware-configuration.nix
│   ├── ssh.nix
│   └── networking.nix
├── agent/                # Agent sandbox VM
├── llama/                # LLM inference VM
├── nvr/                  # Network video recorder VM
├── mac/                  # macOS system-level (nix-darwin)
└── <future-service>/
```

**Key consideration**: `hosts/server/` is a **template**, not a host. Every VM imports it as a base. This distinction should be clearer — either rename it to `hosts/_base-vm/` or `lib/base-server/`, or document the convention clearly.

### 3.4 The legacy module migration path

Given that the implementations wrap legacy modules, the migration is straightforward **per module**:

1. **Inline the legacy module content** into the implementation file
2. **Gate it** behind the appropriate `myHome.*` option (most already are)
3. **Delete** the legacy file
4. **Test** that profile builds identically

Modules ready for immediate inlining (the implementation already duplicates or trivially wraps them):
- `homeModules/git.nix` → inline into `home/implementations/core.nix` (6 lines)
- `homeModules/stylix.nix` → inline into `home/implementations/theming.nix` (already nearly identical)

Modules requiring more care (substantial configuration):
- `homeModules/terminal.nix` → tmux, bash, alacritty config — move into `home/implementations/terminal.nix`
- `homeModules/wm.nix` → large sway+waybar config — gate behind `enableWindowManager` in desktop implementation
- `homeModules/browser.nix` → move into desktop implementation
- `homeModules/claude.nix` → already properly structured with HM module

**Do not rush this**. Each migration should be a single commit that can be tested independently.

### 3.5 Claude Code module architecture

The standard `homeModules/claude.nix` uses the proper `programs.claude-code` HM module API. The agent `homeModules/claude-agent.nix` bypasses this entirely and writes raw `home.file` entries. This means the agent doesn't benefit from any upstream module improvements.

**Recommended approach**: Make `claude-agent.nix` extend `claude.nix` rather than replacing it. Override specific settings (permissions, model) while inheriting the skill/rule loading infrastructure.

---

## 4. Recommended Cleanup Order

### Phase 0: Housekeeping (zero risk, no functional changes)

```
Action                                              Risk
────────────────────────────────────────────────────────
Create .gitignore (result, *.qcow2, *.vma*)         None
Delete agent-sandbox.qcow2                           None
Delete orphaned: home.nix, scratch.md                None
Delete orphaned: homeModules/{moonlight,sunshine,3d_printing,nvim}.nix  None
Delete duplicate dirs: agents/, assets/, skills/     None
Delete: homeModules/claude/skills/nix-flake-original.md.bak  None
Move docs: MOONLIGHT_SUNSHINE_SETUP.md → docs/       None
Move docs: homeModules/REMOTE_DESKTOP.md → docs/     None
Move docs: notes/refactor_suggestions.md → docs/     None
Remove notes/ directory                              None
```

### Phase 1: Flake correctness (fixes broken `nix flake check`)

```
Action                                              Risk
────────────────────────────────────────────────────────
Fix stateVersion "26.05" → "25.05"                   Low
Add stub fileSystems."/" for image-only configs       Low
Remove matrix import from configuration.nix           Low
Fix experimental-features to list form                Low
Remove home.keyboard from HM module                   Low
Remove unused cfg binding in core.nix                 Low
Remove allowBroken = true                             Low
Run nixfmt across all tracked .nix files              Low
```

### Phase 2: Flake structure (reduces maintenance burden)

```
Action                                              Risk
────────────────────────────────────────────────────────
Add mkNixosSystem helper to flake.nix                 Medium
Move gaia config into hosts/gaia/                     Medium
Drop nixvim input (keep nvf only)                     Medium
Add formatter/devShells/checks outputs                Low
Add forAllSystems helper                              Low
Update Makefile with check/fmt targets                Low
```

### Phase 3: Module consolidation (one system, not two)

```
Action                                              Risk
────────────────────────────────────────────────────────
Inline git.nix into core.nix                          Low
Inline stylix.nix into theming.nix                    Low
Inline terminal.nix into terminal implementation      Medium
Inline browser.nix into desktop implementation        Medium
Inline wm.nix into desktop implementation             Medium
Refactor claude-agent.nix to extend claude.nix        Medium
Consolidate agent VM git config to single layer       Low
```

### Phase 4: Future readiness

```
Action                                              Risk
────────────────────────────────────────────────────────
Add nix-darwin input and darwinConfigurations          Medium
Create hosts/gaia/ (move from root)                   Medium
Clarify hosts/server/ as template (rename or doc)     Low
Evaluate themes/ — archive or delete                  Low
Add consistent mkDefault usage in all profiles        Low
```

---

## 5. Validation Protocol

Before and after each phase:

```bash
# Must pass
nix flake check
nix build --dry-run .#nixosConfigurations.gaia.config.system.build.toplevel
nix build --dry-run .#homeConfigurations.sandmhan.activationPackage
nix build --dry-run .#homeConfigurations.macman.activationPackage
nix build --dry-run .#homeConfigurations.terminalman.activationPackage

# Should pass after Phase 1
nixfmt --check $(git ls-files '*.nix')

# Full functional test (after Phase 2+)
make sandmhan  # or whichever profile is on this machine
```

---

## 6. Summary

| Category | Count | Severity |
|----------|-------|----------|
| Duplicate directories | 3 | High — maintenance confusion |
| Orphaned files | 7 | Low — clutter |
| Missing .gitignore | 1 | Medium — repo hygiene |
| Flake check failures | 2+ | High — broken CI |
| Copy-pasted flake boilerplate | 6 blocks | Medium — scales poorly |
| Dual module system | ~10 modules | Medium — technical debt |
| Unused input (nixvim) | 1 | Low — eval overhead |
| Unused directory (themes/) | 58 subdirs | Low — noise |
| Misplaced documentation | 3 files | Low — discoverability |

The repository has a solid architectural foundation in the new profile/options system. The main debt is the incomplete migration from the legacy module structure, combined with the organic growth of duplicate content and missing repository hygiene (.gitignore, formatter, flake checks). The flake structure will become a bottleneck as more hosts are added — the `mkNixosSystem` helper is the single highest-leverage refactor for future scalability.

None of these changes alter any user-facing functionality. They are purely structural improvements that make the codebase easier to navigate, maintain, extend, and reason about — for both humans and AI assistants.
