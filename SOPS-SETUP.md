# SOPS-nix Secrets Management Setup

SOPS (Secrets OPerationS) encrypts secrets that can be safely committed to git and decrypted at runtime by NixOS hosts.

## Prerequisites

```bash
nix-shell -p sops age ssh-to-age
```

## Initial Setup

### 1. Generate your admin age key

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt  # prints public key
```

### 2. Get host age keys from SSH

On each target host (or remotely):

```bash
# Local
sudo ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub

# Remote
ssh user@hostname 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age
```

### 3. Update .sops.yaml

Replace the placeholder `age1...` values with real public keys from steps 1 and 2.

### 4. Create encrypted secret files

```bash
# Copy example and edit (SOPS encrypts on save)
cp secrets/matrix/secrets.yaml.example secrets/matrix/secrets.yaml
sops secrets/matrix/secrets.yaml
```

Generate values for secrets that need randomness:

```bash
# TURN secret, registration secret, etc.
openssl rand -hex 32

# Password hashes for user accounts
mkpasswd -m sha-512
```

## Secret file layout

```
secrets/
  gaia/secrets.yaml       # Desktop-specific (dev tokens, wifi)
  nvr/secrets.yaml        # Camera RTSP URLs, MQTT credentials
  matrix/secrets.yaml     # TURN secret, ACME email, registration secret
  shared/secrets.yaml     # SSH keys, shared service credentials
  user/personal.yaml      # Git config, personal info
```

Each directory has a `.example` file showing the expected YAML structure.

## How it works

1. `systemModules/sops.nix` configures sops-nix to derive age keys from SSH host keys
2. Each host selects its secrets file via `sops.defaultSopsFile` based on hostname
3. Service modules declare `sops.secrets.<name>` entries with ownership and permissions
4. At activation time, sops-nix decrypts secrets to `/run/secrets/<name>`
5. Services reference secrets via `config.sops.secrets.<name>.path`

## Common operations

```bash
# Edit existing secrets
sops secrets/matrix/secrets.yaml

# Add a new host's key to .sops.yaml, then re-encrypt
sops updatekeys secrets/matrix/secrets.yaml

# Check which keys can decrypt a file
sops filestatus secrets/matrix/secrets.yaml

# Test decryption manually
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d secrets/matrix/secrets.yaml

# Verify runtime secrets after rebuild
sudo ls -la /run/secrets/
```

## Service-specific secret workflows

### YAML key format

sops-nix uses slashes in secret names (e.g. `tailscale/auth-key`) to map to nested YAML keys. The secrets file must use nested structure, not flat keys with literal slashes:

```yaml
# CORRECT — sops-nix finds this as "tailscale/auth-key"
tailscale:
  auth-key: tskey-auth-...

# WRONG — sops-nix cannot find the key
tailscale/auth-key: tskey-auth-...
```

Flat keys like `user-password` (no slash) work as top-level YAML keys.

### User password (NixOS `hashedPasswordFile`)

Linux authentication requires a hashed password in `/etc/shadow`, not plaintext. The sops-encrypted file stores the hash; NixOS copies it into shadow at activation time.

1. Generate a SHA-512 password hash:

```bash
mkpasswd -m sha-512
```

2. Verify the hash by running `mkpasswd` again with the same salt (the portion between the second and third `$`):

```bash
mkpasswd -m sha-512 --salt "SALT_FROM_HASH"
```

Compare the output to your original hash — they should be identical.

3. Create the encrypted secrets file:

```bash
sops secrets/gaia/secrets.yaml
```

Add the hash as:

```yaml
user-password: "$6$rounds=4096$salt$hash..."
```

Save and quit (sops encrypts on save).

4. The NixOS config in `hosts/gaia/default.nix` references it as:

```nix
sops.secrets.user-password = {
  neededForUsers = true;
};

users.mutableUsers = false;
users.users.sandmhan.hashedPasswordFile = config.sops.secrets.user-password.path;
```

5. Rebuild: `make gaia`

> **Warning:** `mutableUsers = false` means `passwd` will no longer work. If the hash is wrong, you'll need to boot into single-user mode to fix it. Always verify your hash before rebuilding.

### Tailscale auth key

1. Generate an auth key at [Tailscale admin console](https://login.tailscale.com/admin/settings/keys):
   - Reusable: yes
   - Ephemeral: no (nodes are long-lived)
   - Expiry: 90 days (regenerate before expiry)

2. Create the encrypted secrets file (use nested YAML — see key format section above):

```bash
sops secrets/tailscale/secrets.yaml
```

```yaml
tailscale:
  auth-key: tskey-auth-YOUR_KEY
```

3. Ensure the host's age key is in `.sops.yaml` under the tailscale creation rule, then:

```bash
sops updatekeys secrets/tailscale/secrets.yaml
git add secrets/tailscale/secrets.yaml
```

4. The host config just needs:

```nix
imports = [ ../../systemModules/tailscale.nix ];

homelab.tailscale = {
  enable = true;
  advertiseRoutes = [ "10.0.0.0/24" ]; # optional, for subnet routing (add more subnets when VLANs are implemented)
};
```

## Design decisions

**Domain is not a SOPS secret.** Nginx virtualHost attribute names must be known at Nix evaluation time. SOPS secrets only resolve at activation time. The domain stays as a `let` binding in `systemModules/matrix.nix`.

**Frigate camera URLs use hardcoded IPs for now.** The NixOS `services.frigate` module generates config at build time. When cameras need authentication, switch to the OCI container approach with a `sops.templates`-generated config file.

**`validateSopsFiles = false` in base module.** Set to false so builds succeed before secrets files are created. Set to `true` once your secrets are in place.

## Troubleshooting

**"failed to decrypt" errors:** Verify your age key is at `~/.config/sops/age/keys.txt` and its public key is in `.sops.yaml`.

**"No such file" on secrets:** Secrets don't exist until after `nixos-rebuild switch`. Check with `sudo ls /run/secrets/`.

**Build fails referencing secrets files:** The `sops.defaultSopsFile` path must exist at build time when `validateSopsFiles = true`. Either create the encrypted file first or keep validation disabled.
