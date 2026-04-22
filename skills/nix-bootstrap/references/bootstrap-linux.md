# Bootstrap Nix on Linux

## Determinate Nix on Non-NixOS Linux

For any Linux distribution (Ubuntu, Fedora, Arch, etc.), the Determinate Nix installer is the recommended approach:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

This performs a **multi-user** installation:

- Creates the `nixbld` group and builder users.
- Sets up the `nix-daemon` systemd service.
- Enables flakes and `nix-command` by default.
- Configures shell integration for bash and zsh.
- Provides an uninstaller (`/nix/nix-installer uninstall`).

Open a new shell session after installation.

## NixOS Installation

If you are installing NixOS as your operating system, follow the official installer:

- Graphical installer ISO: <https://nixos.org/download/#nixos-iso>
- Manual installation guide: <https://nixos.org/manual/nixos/stable/#sec-installation>

The rest of this document covers non-NixOS Linux where Nix is installed as a package manager alongside the host distribution.

## nix.conf

System-wide: `/etc/nix/nix.conf` (managed by the installer, requires root to edit).

User overrides: `~/.config/nix/nix.conf`.

Key settings (Determinate sets these by default):

```ini
experimental-features = nix-command flakes
trusted-users = root @wheel
max-jobs = auto
```

For additional binary caches:

```ini
substituters = https://cache.nixos.org https://nix-community.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
```

On multi-user installs, changes to `/etc/nix/nix.conf` require restarting the daemon:

```bash
sudo systemctl restart nix-daemon
```

## Shell Integration

The installer adds a sourcing snippet to `/etc/bash.bashrc` and `/etc/zshrc` (or distribution-specific equivalents). The profile script is at:

```
/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

Verify:

```bash
nix --version
which nix
```

If `nix` is not on your PATH, source the profile manually:

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

Then check your shell RC file (`~/.bashrc` or `~/.zshrc`) to ensure nothing overrides PATH after the Nix snippet.

## Direnv + nix-direnv on Linux

### Install direnv

```bash
nix profile install nixpkgs#direnv
```

Or via home-manager:

```nix
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;
};
```

### Shell Hook

Add to `~/.bashrc`:

```bash
eval "$(direnv hook bash)"
```

Or to `~/.zshrc`:

```bash
eval "$(direnv hook zsh)"
```

### Install nix-direnv

Skip this step if you enabled `nix-direnv` through home-manager above.

```bash
nix profile install nixpkgs#nix-direnv
```

Create or update `~/.config/direnv/direnvrc`:

```bash
source $HOME/.nix-profile/share/nix-direnv/direnvrc
```

### Per-Project Usage

Create `.envrc` in your project root:

```bash
use flake
```

Then:

```bash
direnv allow
```

## SELinux Considerations

On distributions with SELinux enforcing (Fedora, RHEL, CentOS), the Nix store and daemon may trigger SELinux denials.

### Common Issues

- **nix-daemon cannot bind socket**: The daemon socket at `/nix/var/nix/daemon-socket/socket` may need a custom SELinux context.
- **Builder sandbox denied**: Nix build sandboxing uses Linux namespaces, which SELinux may restrict.

### Workarounds

Check for denials:

```bash
sudo ausearch -m avc -ts recent
```

Generate and apply a local policy module:

```bash
sudo ausearch -m avc -ts recent | audit2allow -M nix-daemon
sudo semodule -i nix-daemon.pp
```

If problems persist, you can set the Nix store context:

```bash
sudo semanage fcontext -a -t nix_store_t "/nix/store(/.*)?"
sudo restorecon -Rv /nix/store
```

As a last resort (not recommended for production), set SELinux to permissive to confirm it is the cause:

```bash
sudo setenforce 0
```

## Systemd Service Management

The multi-user Nix installation runs `nix-daemon` as a systemd service.

### Common Commands

```bash
# Check daemon status
systemctl status nix-daemon

# Restart after nix.conf changes
sudo systemctl restart nix-daemon

# View daemon logs
journalctl -u nix-daemon -f

# Enable daemon at boot (the installer does this)
sudo systemctl enable nix-daemon
```

### Socket Activation

Determinate Nix configures socket activation, so the daemon starts on demand:

```bash
systemctl status nix-daemon.socket
```

If the daemon is not responding, ensure the socket unit is active:

```bash
sudo systemctl restart nix-daemon.socket
```

## Verification

```bash
# Nix is installed and flakes work
nix --version
nix flake metadata nixpkgs

# Daemon is running
systemctl status nix-daemon

# Direnv is active
direnv status

# nix-direnv works (from a project directory with .envrc)
cd my-project && direnv status
```

## Upgrading Determinate Nix

```bash
sudo /nix/nix-installer self-update
sudo nix upgrade-nix
```

Or reinstall:

```bash
/nix/nix-installer uninstall
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```
