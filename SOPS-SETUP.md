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

## Design decisions

**Domain is not a SOPS secret.** Nginx virtualHost attribute names must be known at Nix evaluation time. SOPS secrets only resolve at activation time. The domain stays as a `let` binding in `systemModules/matrix.nix`.

**Frigate camera URLs use hardcoded IPs for now.** The NixOS `services.frigate` module generates config at build time. When cameras need authentication, switch to the OCI container approach with a `sops.templates`-generated config file.

**`validateSopsFiles = false` in base module.** Set to false so builds succeed before secrets files are created. Set to `true` once your secrets are in place.

## Troubleshooting

**"failed to decrypt" errors:** Verify your age key is at `~/.config/sops/age/keys.txt` and its public key is in `.sops.yaml`.

**"No such file" on secrets:** Secrets don't exist until after `nixos-rebuild switch`. Check with `sudo ls /run/secrets/`.

**Build fails referencing secrets files:** The `sops.defaultSopsFile` path must exist at build time when `validateSopsFiles = true`. Either create the encrypted file first or keep validation disabled.
