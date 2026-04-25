# Untracked Modules — Remaining Work

These modules exist locally but have not been committed. They were written against an older codebase and need updates before they can build.

## Cross-Cutting Blocker

All three service modules were written against:
1. **Old `homelab.sops` option interface** — `systemModules/sops.nix` was rewritten to a simple config. Host configs must use `sops.age.keyFile = "/var/lib/sops-nix/key.txt"` directly instead of `homelab.sops = { enable = true; deploymentType = "vm"; ... }`.
2. **Removed `packages.nix` groups** — `forgejoUtils`, `homeassistant`, `homeassistantUtils`, `matrixBot`, and `sops`/`sopsUtils` were all removed from the centralized package registry. Modules referencing these will fail to evaluate.

Every module and host config below needs both of these fixed before it will build.

---

## 1. Forgejo (`systemModules/forgejo.nix`, `hosts/git/`, `hosts/lxc-git/`)

### Files
- `systemModules/forgejo.nix` — full module with options
- `hosts/git/default.nix` — VM host config
- `hosts/lxc-git/default.nix` — already tracked/rewritten (inlines everything, doesn't use forgejo module)
- `secrets/forgejo/secrets.yaml` — plaintext placeholders
- `docs/forgejo-setup.md` — setup documentation

### To Do
- [ ] Fix `servicePackages.forgejoUtils` reference in `forgejo.nix:229` — group was removed from `packages.nix`; inline the packages (`postgresql`, `forgejo`) or re-add the group
- [ ] Remove `homelab.sops` block from `hosts/git/default.nix:29-33` — replace with `sops.age.keyFile = "/var/lib/sops-nix/key.txt"`
- [ ] Remove `../../systemModules/sops.nix` import from `hosts/git/default.nix:4` — it's now a simple module imported via server base or directly
- [ ] Add `git` and `lxc-git` hostname mappings to `systemModules/sops.nix` defaultSopsFile logic (currently falls through to `shared/secrets.yaml`)
- [ ] Decide: reconcile `hosts/lxc-git/` (tracked, inlines everything) with `systemModules/forgejo.nix` (untracked, option-based) — should the LXC host use the module too?
- [ ] Encrypt `secrets/forgejo/secrets.yaml` with SOPS and real age keys
- [ ] Build-test with `nix build --dry-run`
- [ ] Update `docs/forgejo-setup.md` to reflect changes

---

## 2. Home Assistant (`systemModules/homeassistant.nix`, `hosts/homeassistant/`, `hosts/lxc-homeassistant/`)

### Files
- `systemModules/homeassistant.nix` — full module with options
- `hosts/homeassistant/default.nix` — VM host config
- `hosts/lxc-homeassistant/default.nix` — LXC host config
- `secrets/homeassistant/secrets.yaml` — plaintext placeholders
- `docs/homeassistant-setup.md` — setup documentation

### To Do
- [ ] Fix `servicePackages.homeassistant` and `servicePackages.homeassistantUtils` references in `homeassistant.nix:204-206` — both removed from `packages.nix`; inline `mosquitto` and any other needed packages
- [ ] Remove `homelab.sops` block from `hosts/homeassistant/default.nix:111-115` — replace with `sops.age.keyFile`
- [ ] Remove `homelab.sops` block from `hosts/lxc-homeassistant/default.nix:72-76` — replace with `sops.age.keyFile`
- [ ] Remove `../../systemModules/sops.nix` imports from both host configs
- [ ] Add `homeassistant` and `lxc-homeassistant` hostname mappings to `systemModules/sops.nix`
- [ ] Encrypt `secrets/homeassistant/secrets.yaml` with SOPS and real age keys
- [ ] USB passthrough device paths are placeholders (`/dev/ttyUSB0`, `/dev/ttyUSB1`) — update when physical dongles are connected
- [ ] Build-test with `nix build --dry-run`
- [ ] Update `docs/homeassistant-setup.md` to reflect changes

---

## 3. Matrix Agent Bridge (`systemModules/matrix-agent-bridge.nix`, `systemModules/matrix-bot/`)

### Files
- `systemModules/matrix-agent-bridge.nix` — NixOS module for the bot service
- `systemModules/matrix-bot/bot.py` — Python bot implementation
- `docs/matrix-agent-bridge-setup.md` — setup documentation

### To Do
- [ ] Fix `servicePackages.matrixBot` reference in `matrix-agent-bridge.nix:229` — removed from `packages.nix`; inline the python env (`python3.withPackages (ps: with ps; [ matrix-nio aiohttp pyyaml ])`)
- [ ] No host config exists — create `hosts/matrix/default.nix` or integrate module into an existing matrix host config
- [ ] Verify `secrets/matrix/secrets.yaml` contains `bot-access-token` and `webhook-secret` keys (bot expects these via SOPS)
- [ ] Hardcoded IPs in `bot.py:208-211` (`10.0.0.6`, `10.0.20.107`) — verify these match current deployed service addresses
- [ ] `!deploy` command (`bot.py:224-234`) is a stub — implement or document as future work
- [ ] `!logs` command (`bot.py:236-254`) is a stub — implement or document as future work
- [ ] Build-test with `nix build --dry-run`
- [ ] Update `docs/matrix-agent-bridge-setup.md` to reflect changes

---

## 4. Documentation

- `docs/forgejo-setup.md` — update for SOPS and package changes
- `docs/homeassistant-setup.md` — update for SOPS and package changes
- `docs/matrix-agent-bridge-setup.md` — update for SOPS and package changes
- `docs/nas-setup.md` — review for accuracy against current `systemModules/nas.nix`
- `docs/infrastructure-registry.md` — update with new services once deployed
