# Bootstrap Nix on macOS

## Install Determinate Nix

The Determinate Nix installer is the recommended path for macOS. It differs from the upstream installer in several ways:

- Automatically creates and manages the APFS volume for `/nix` (no manual `synthetic.conf` or `fstab` edits).
- Enables flakes and the `nix-command` experimental feature by default.
- Provides an uninstaller (`/nix/nix-installer uninstall`).
- Ships a hardened, reproducible install script.

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Open a **new** terminal session after installation completes.

## APFS Volume

Determinate Nix creates a dedicated APFS volume mounted at `/nix`. This is required because macOS System Integrity Protection (SIP) prevents writing to the root filesystem. The volume is configured automatically; no user action is needed.

## nix.conf

Location: `/etc/nix/nix.conf` (system-wide, managed by the installer).

User overrides: `~/.config/nix/nix.conf`.

Key settings (Determinate sets most of these automatically):

```ini
experimental-features = nix-command flakes
trusted-users = root <your-username>
max-jobs = auto
```

If you use substituters (binary caches), add them here:

```ini
substituters = https://cache.nixos.org https://nix-community.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
```

## Shell Integration

The installer adds a sourcing line to `/etc/zshrc` (or creates `/etc/zshrc.d/nix.sh`). Verify Nix is on your PATH:

```bash
nix --version
which nix
```

If `nix` is not found, ensure your `~/.zshrc` does not override `PATH` after the Nix snippet. The Nix profile script is typically at:

```
/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

You can source it manually to debug:

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

## Direnv Installation

Install direnv via nix profile:

```bash
nix profile install nixpkgs#direnv
```

Or, if you use home-manager, add it to your home configuration:

```nix
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;
};
```

### Shell Hook

Add the direnv hook to `~/.zshrc`:

```bash
eval "$(direnv hook zsh)"
```

## nix-direnv Setup

nix-direnv replaces the built-in `use_nix` / `use_flake` with a cached version that avoids re-evaluating on every shell start.

Install via nix profile (skip if using home-manager):

```bash
nix profile install nixpkgs#nix-direnv
```

Create or update `~/.config/direnv/direnvrc`:

```bash
source $HOME/.nix-profile/share/nix-direnv/direnvrc
```

### Per-Project Usage

In your project root, create `.envrc`:

```bash
use flake
```

Then allow it:

```bash
direnv allow
```

The environment will activate automatically when you `cd` into the project.

## Verification

Run these commands to confirm everything works:

```bash
# Nix is installed and flakes are enabled
nix --version
nix flake metadata nixpkgs

# Direnv is active
direnv status

# nix-direnv is working (from inside a project with .envrc)
cd my-project && direnv status
```

## Common macOS Gotchas

### SIP (System Integrity Protection)

SIP prevents writing to `/` directly, which is why Nix uses a dedicated APFS volume. Do **not** disable SIP for Nix — the APFS volume approach works correctly with SIP enabled.

### Xcode Command Line Tools

Some Nix packages (especially those that compile native code) need the Xcode CLI tools:

```bash
xcode-select --install
```

If you see errors about missing `cc` or SDK headers, this is usually the fix.

### PATH Ordering

Ensure Nix paths appear **before** Homebrew or system paths if you want Nix-provided tools to take precedence. The default installer configuration handles this, but custom `~/.zshrc` edits can break the order. Typical correct order:

```
~/.nix-profile/bin
/nix/var/nix/profiles/default/bin
/opt/homebrew/bin   (or /usr/local/bin)
/usr/bin
/bin
```

### macOS Updates

Major macOS upgrades can occasionally break the `/nix` mount. If Nix stops working after an OS update, repair with:

```bash
/nix/nix-installer repair
```

## Upgrading Determinate Nix

```bash
sudo /nix/nix-installer self-update
sudo nix upgrade-nix
```

Or reinstall cleanly:

```bash
/nix/nix-installer uninstall
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```
