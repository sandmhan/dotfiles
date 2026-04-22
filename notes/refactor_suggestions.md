  I just test-drove the nix-linux agent on this repo. Highlights:

  Architecture (as found)

  - flake.nix exposes nixosConfigurations (gaia, initialProxmoxVMA, proxmoxVM, nvr, matrix) and homeConfigurations
  (sandmhan, macman, wslman, terminalman). No devShells, formatter, checks, or templates outputs.
  - Two parallel HM systems: legacy homeModules/* does the real work; new home/{options,profiles,implementations} is
  an options façade that imports the legacy modules and gates packages.
  - All NixOS hosts share hosts/server/ with per-host systemSettings // { hostname = ...; } overrides, copy-pasted
  four times.

  Top fixes (concrete)

  Blockers
  1. nix flake check fails — initialProxmoxVMA (and friends) lack fileSystems."/". Add a stub in
  hosts/server/default.nix or move image-only configs out of default checks.
  2. nixfmt --check . fails on 26 tracked files. Run nixfmt $(git ls-files '*.nix').
  3. result symlink is tracked + nix-agent-skills.zip, *.md.bak, and stray top-level agents/ assets/ skills/ (zip
  leftovers duplicating homeModules/claude/*) are in the working tree. Gitignore + delete.

  Flake hygiene
  4. flake.nix:82-154 — four near-identical nixpkgs.lib.nixosSystem blocks. Add mkNixosSystem = { hostname,
  extraModules ? [] }: ... mirroring mkHomeConfiguration. Removes ~60 lines.
  5. Add formatter, devShells (nixfmt, deadnix, statix, nil, nix-tree), and checks outputs with a forAllSystems
  helper. Currently missing entirely.
  6. Add make check / make fmt targets and a CI workflow — flake check is silently broken right now.

  Antipatterns
  7. nixpkgs.config set in two places: home/implementations/core.nix:19 and configuration.nix:358. Also allowBroken =
  true globally — drop it.
  8. home/implementations/core.nix:7 declares cfg = config.myHome; but never uses it. deadnix will flag.
  9. configuration.nix:18 imports ./systemModules/matrix.nix even though matrix is its own NixOS host — gaia shouldn't
   run matrix.
  10. configuration.nix:361 uses string form experimental-features = "flakes nix-command" — canonical is the list
  (which hosts/server/default.nix:45 already does correctly).
  11. Both nixvim.homeModules.nixvim and nvf.homeManagerModules.default are loaded for every HM config
  (flake.nix:162-189). Pick one — CLAUDE.md says nvf is the stack.
  12. home/implementations/terminal.nix:44 uses home.keyboard which isn't a Home Manager option (NixOS-only).
  13. hosts/server/default.nix sets system.stateVersion = "26.05" — that release doesn't exist yet (today is
  2026-04-07). Likely typo for 25.05.
  14. Agent description claims aarch64-linux support but every NixOS config hardcodes system = "x86_64-linux".

  Smaller wins
  15. home/profiles/desktop.nix uses raw true/false while terminal uses mkDefault — inconsistent override semantics.
  16. nix-linux.md rule #6 says "use the template from assets/templates/" but no templates flake output is exposed.
  Add one pointing at homeModules/claude/assets/templates/.

  Suggested order of attack

  1. Gitignore result, delete the zip + .bak + stray top-level dirs.
  2. Run nixfmt over the tree.
  3. Fix the 26.05 typo and the matrix cross-import.
  4. Add stub fileSystems."/" so nix flake check runs.
  5. Refactor with mkNixosSystem, then add formatter/devShells/checks outputs.
  6. Drop nixvim if you're committed to nvf.

  Want me to execute any of these fixes? I'd suggest starting with 1-4 in one PR.

