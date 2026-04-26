# SOPS Secrets Management Setup Guide

## Overview

SOPS (Secrets OPerationS) provides encrypted secret management for the homelab infrastructure. Secrets are encrypted in git repositories and automatically decrypted on target hosts using age encryption keys.

## Architecture

```
┌─────────────────────┐    age keys    ┌─────────────────────┐    decrypt     ┌─────────────────┐
│   Git Repository    │◄──────────────►│   .sops.yaml Config │◄──────────────►│   Target Hosts   │
│                     │                │                     │                │                 │
│ • Encrypted Secrets │                │ • Key Mappings      │                │ • age Keys      │
│ • Public in Git     │                │ • Path Rules        │                │ • Service Access│
│ • Multiple Files    │                │ • Access Control    │                │ • Auto Decrypt  │
└─────────────────────┘                └─────────────────────┘                └─────────────────┘
                                                  │
                                                  │ Rules
                                                  ▼
                                        ┌─────────────────────┐
                                        │   Secret Categories │
                                        │                     │
                                        │ • Per-Host Secrets  │
                                        │ • Shared Secrets    │
                                        │ • Service Secrets   │
                                        │ • User Secrets      │
                                        └─────────────────────┘
```

## Secret Categories

### Host-Specific Secrets
- **gaia/**: Desktop/laptop secrets (personal configs, development keys)
- **nvr/**: Network Video Recorder secrets (camera credentials, API keys)
- **matrix/**: Matrix homeserver secrets (registration keys, database passwords)
- **monitoring/**: Grafana passwords, SMTP credentials
- **wireguard/**: VPN server and client keys

### Shared Secrets
- **shared/**: Cross-service credentials, API tokens, certificates
- **user/**: Personal user configuration, git credentials

## Configuration Structure

### .sops.yaml Configuration

The `.sops.yaml` file defines which age keys can decrypt which secret files:

```yaml
keys:
  # Admin key for managing all secrets
  - &admin_age age1your_admin_public_key_here
  
  # Host keys derived from SSH host keys  
  - &gaia_key age1gaia_host_public_key_here
  - &nvr_key age1nvr_host_public_key_here
  - &matrix_key age1matrix_host_public_key_here
  - &monitor_key age1monitor_host_public_key_here
  - &vpn_key age1vpn_host_public_key_here

creation_rules:
  # Host-specific secrets
  - path_regex: secrets/gaia/[^/]+\.(yaml|json|env|ini)$
    key_groups:
    - age:
      - *admin_age
      - *gaia_key
      
  - path_regex: secrets/matrix/[^/]+\.(yaml|json|env|ini)$
    key_groups:
    - age:
      - *admin_age
      - *matrix_key
  
  # Add rules for each service...
  
  # Shared secrets accessible by multiple hosts
  - path_regex: secrets/shared/[^/]+\.(yaml|json|env|ini)$
    key_groups:
    - age:
      - *admin_age
      - *gaia_key
      - *matrix_key
      - *monitor_key
```

### Secret File Structure

```
secrets/
├── gaia/
│   ├── secrets.yaml.example     # Template
│   └── secrets.yaml            # Encrypted secrets
├── matrix/  
│   ├── secrets.yaml.example    
│   └── secrets.yaml
├── monitoring/
│   ├── secrets.yaml.example
│   └── secrets.yaml
├── wireguard/
│   ├── secrets.yaml.example
│   └── secrets.yaml
├── shared/
│   ├── secrets.yaml.example
│   └── secrets.yaml
└── user/
    ├── personal.yaml.example
    └── personal.yaml
```

## Setup Process

### 1. Admin Key Generation

Generate your personal admin key for managing all secrets:

```bash
# Install required tools
nix-shell -p age sops

# Generate admin age key
age-keygen -o ~/.config/sops/age/keys.txt

# Get public key for .sops.yaml
age-keygen -y ~/.config/sops/age/keys.txt
# Output: age1abc123... (use this in .sops.yaml)

# Set SOPS_AGE_KEY_FILE environment variable
echo 'export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"' >> ~/.bashrc
source ~/.bashrc
```

### 2. Host Key Generation

For each host that needs to decrypt secrets:

```bash
# On target host, generate age key
sudo mkdir -p /var/lib/sops-nix
sudo age-keygen -o /var/lib/sops-nix/key.txt

# Get public key to add to .sops.yaml
sudo age-keygen -y /var/lib/sops-nix/key.txt

# Alternative: Derive from SSH host key
ssh user@target-host 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age
```

### 3. Update .sops.yaml Configuration

Add all generated public keys to `.sops.yaml`:

```bash
# Edit .sops.yaml with actual public keys
# Replace age1... placeholders with real keys from step 2

# Verify configuration
sops updatekeys secrets/*/secrets.yaml
```

### 4. Create Secret Files

Create and encrypt secrets for each service:

#### Matrix Secrets
```bash
# Create unencrypted matrix secrets
cat > secrets/matrix/secrets.yaml << EOF
registration_shared_secret: $(openssl rand -base64 32)
postgres_password: $(openssl rand -base64 24)
coturn_static_auth_secret: $(openssl rand -base64 32)
agent_bot_access_token: $(openssl rand -base64 32)
EOF

# Encrypt with sops
sops -e -i secrets/matrix/secrets.yaml

# Verify encryption worked
sops -d secrets/matrix/secrets.yaml
```

#### Monitoring Secrets
```bash
# Create monitoring secrets
cat > secrets/monitoring/secrets.yaml << EOF
grafana-admin-password: $(openssl rand -base64 24)
# smtp-password: your_smtp_password_here  # Uncomment if using email alerts
EOF

sops -e -i secrets/monitoring/secrets.yaml
```

#### WireGuard Secrets
```bash
# Generate WireGuard keys
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo $SERVER_PRIVATE_KEY | wg pubkey)

# Generate client keys for each device
LAPTOP_PRIVATE_KEY=$(wg genkey)  
LAPTOP_PUBLIC_KEY=$(echo $LAPTOP_PRIVATE_KEY | wg pubkey)

PHONE_PRIVATE_KEY=$(wg genkey)
PHONE_PUBLIC_KEY=$(echo $PHONE_PRIVATE_KEY | wg pubkey)

# Create WireGuard secrets file
cat > secrets/wireguard/secrets.yaml << EOF
server-private-key: $SERVER_PRIVATE_KEY

clients: |
  [
    {
      "name": "laptop-framework",
      "publicKey": "$LAPTOP_PUBLIC_KEY", 
      "allowedIPs": ["10.100.0.2/32"],
      "comment": "Framework laptop"
    },
    {
      "name": "phone-android",
      "publicKey": "$PHONE_PUBLIC_KEY",
      "allowedIPs": ["10.100.0.3/32"], 
      "comment": "Android phone"
    }
  ]
EOF

sops -e -i secrets/wireguard/secrets.yaml

# Save client private keys securely for device configuration
echo "Laptop private key: $LAPTOP_PRIVATE_KEY" > ~/.ssh/wireguard-client-keys.txt
echo "Phone private key: $PHONE_PRIVATE_KEY" >> ~/.ssh/wireguard-client-keys.txt
chmod 600 ~/.ssh/wireguard-client-keys.txt
```

#### Personal User Secrets
```bash
# Create user secrets (git config, API keys, etc.)
cat > secrets/user/personal.yaml << EOF
git_user_name: "Your Name"
git_user_email: "you@example.com"
github_username: "yourusername" 
# github_token: "ghp_your_github_token_here"  # For private repos
# openai_api_key: "sk-your_openai_key"       # If using external AI
EOF

sops -e -i secrets/user/personal.yaml
```

## Usage in NixOS Configurations

### Basic Secret Access

```nix
# In any NixOS configuration
{ config, ... }: {
  # Import sops module
  imports = [ ../systemModules/sops.nix ];
  
  # Define secrets this host needs
  sops.secrets = {
    "service/password" = {
      owner = "service-user";
      group = "service-group"; 
      mode = "0600";
    };
    
    "api/key" = {
      owner = "root";
      mode = "0400";
    };
  };
  
  # Use secrets in service configuration
  services.myservice = {
    enable = true;
    passwordFile = config.sops.secrets."service/password".path;
    # File path: /run/secrets/service/password
  };
}
```

### Template Generation

For services that need multiple secrets in one file:

```nix
sops.templates."service-config" = {
  content = ''
    [database]
    password = ${config.sops.placeholder."db/password"}
    
    [api]
    key = ${config.sops.placeholder."api/key"}
    secret = ${config.sops.placeholder."api/secret"}
  '';
  
  owner = "service-user";
  group = "service-group";
};

# Use template in service
services.myservice.configFile = config.sops.templates."service-config".path;
```

### Environment Variables

```nix
# Load secrets as environment variables
systemd.services.myservice = {
  serviceConfig = {
    EnvironmentFile = config.sops.secrets."service/env".path;
  };
};

# Secret file format (key=value pairs):
# API_KEY=secret-value
# DATABASE_URL=postgresql://user:pass@host/db
```

## Service-Specific Integration Examples

### Matrix Homeserver

```nix
# In systemModules/matrix.nix
sops.secrets = {
  "matrix/registration-secret" = {
    owner = "matrix-synapse";
    group = "matrix-synapse";
  };
  "matrix/postgres-password" = {
    owner = "postgres";
    group = "postgres"; 
  };
};

services.matrix-synapse.settings = {
  registration_shared_secret_path = config.sops.secrets."matrix/registration-secret".path;
};

services.postgresql = {
  # Use secret in database configuration
  authentication = ''
    local matrix-synapse matrix-synapse password
  '';
  # Password loaded from secret file
};
```

### Grafana

```nix
# In systemModules/monitoring.nix  
sops.secrets."monitoring/grafana-admin-password" = {
  owner = "grafana";
  group = "grafana";
};

services.grafana.settings.security = {
  admin_password = "$__file{${config.sops.secrets."monitoring/grafana-admin-password".path}}";
};
```

### WireGuard VPN

```nix
# In systemModules/wireguard.nix
sops.secrets = {
  "wireguard/server-private-key" = {
    owner = "root";
    group = "root";
  };
  "wireguard/clients" = {
    owner = "root"; 
    group = "root";
  };
};

networking.wireguard.interfaces.wg0 = {
  privateKeyFile = config.sops.secrets."wireguard/server-private-key".path;
  # Client configuration loaded from encrypted JSON
};
```

## Security Best Practices

### Key Management

1. **Separate Admin Keys**: Don't use admin keys on production hosts
2. **Key Rotation**: Regularly rotate age keys (annually)
3. **Backup Keys**: Store admin keys in secure, offline backup
4. **Access Control**: Limit admin key access to essential personnel

### Secret Rotation

```bash
# Rotate a secret across all hosts
# 1. Generate new secret
NEW_SECRET=$(openssl rand -base64 32)

# 2. Update secret file
sops secrets/service/secrets.yaml --set '["password"]' "$NEW_SECRET"

# 3. Deploy to all affected hosts
for host in matrix monitor vpn; do
  nixos-rebuild switch --target-host user@$host --flake .#$host --sudo
done

# 4. Restart services as needed
ssh matrix-host "sudo systemctl restart matrix-synapse"
```

### Audit and Monitoring

```bash
# Check who can access which secrets
sops -d secrets/matrix/secrets.yaml --extract '["password"]'

# Verify secret file integrity
for file in secrets/*/secrets.yaml; do
  echo "Checking $file..."
  sops -d "$file" > /dev/null && echo "✓ OK" || echo "✗ FAILED"
done

# Monitor secret access on hosts
sudo journalctl -u sops-nix -f
```

## Troubleshooting

### Common Issues

#### Permission Denied
```bash
# Check age key file exists and is readable
ls -la /var/lib/sops-nix/key.txt
sudo cat /var/lib/sops-nix/key.txt

# Verify key matches .sops.yaml
sudo age-keygen -y /var/lib/sops-nix/key.txt

# Check sops service status
sudo systemctl status sops-nix
```

#### Failed to Decrypt
```bash
# Verify admin key is correct
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
sops -d secrets/test/secrets.yaml

# Check if host key has access
# Compare output of: sudo age-keygen -y /var/lib/sops-nix/key.txt
# With keys listed in .sops.yaml
```

#### Service Can't Read Secret
```bash
# Check secret file exists
ls -la /run/secrets/

# Verify ownership and permissions  
sudo ls -la /run/secrets/service/password

# Check service user can read
sudo -u service-user cat /run/secrets/service/password
```

### Key Recovery

If admin keys are lost:

```bash
# 1. Generate new admin key
age-keygen -o ~/.config/sops/age/new-keys.txt

# 2. Add new key to .sops.yaml
# 3. Re-encrypt all secrets with new key
sops updatekeys secrets/*/secrets.yaml

# 4. Remove old key from .sops.yaml
# 5. Deploy updated configurations
```

## Migration from Plain Text Secrets

### Automated Migration Script

```bash
#!/bin/bash
# migrate-to-sops.sh

migrate_secret() {
    local service="$1"
    local secret_name="$2"
    local secret_value="$3"
    
    # Create/update secret file
    if [ ! -f "secrets/$service/secrets.yaml" ]; then
        echo "{}" | sops -e /dev/stdin > "secrets/$service/secrets.yaml"
    fi
    
    # Add secret
    sops --set "secrets/$service/secrets.yaml" "[\"$secret_name\"]" "$secret_value"
    
    echo "Added $secret_name to secrets/$service/secrets.yaml"
}

# Example migrations
migrate_secret "matrix" "postgres-password" "$(cat /etc/matrix/db-password)"
migrate_secret "monitoring" "grafana-admin-password" "admin123" 
migrate_secret "wireguard" "server-private-key" "$(cat /etc/wireguard/private.key)"

echo "Migration complete. Update NixOS configurations to use sops secrets."
```

### Configuration Updates

```nix
# Before (plain text)
services.matrix-synapse.settings = {
  registration_shared_secret = "plain-text-secret";
};

# After (sops)
sops.secrets."matrix/registration-secret" = {};
services.matrix-synapse.settings = {
  registration_shared_secret_path = config.sops.secrets."matrix/registration-secret".path;
};
```

## Integration with External Tools

### Ansible Vault Migration

```bash
# Extract from Ansible Vault
ansible-vault decrypt vault.yml --output=-

# Convert to sops format
# Manual process - copy secrets to appropriate sops files
```

### Kubernetes Secrets

```bash  
# Export from Kubernetes
kubectl get secret mysecret -o yaml

# Convert to sops (manual process)
# Extract base64 values and add to sops files
```

### 1Password/Bitwarden Integration

```bash
# Example: Populate from Bitwarden CLI
bw get password "Grafana Admin" | sops --set 'secrets/monitoring/secrets.yaml' '["grafana-admin-password"]'

# Batch import script
#!/bin/bash
declare -A secrets=(
    ["monitoring/grafana-admin-password"]="Grafana Admin"
    ["matrix/postgres-password"]="Matrix DB Password"
    ["wireguard/server-private-key"]="WireGuard Server Key"
)

for sops_path in "${!secrets[@]}"; do
    bw_item="${secrets[$sops_path]}"
    service=$(dirname "$sops_path")
    
    # Get secret from Bitwarden
    secret_value=$(bw get password "$bw_item")
    
    # Store in sops
    sops --set "secrets/$service/secrets.yaml" "[\"$(basename "$sops_path")\"]" "$secret_value"
done
```

This SOPS setup provides secure, auditable secret management across your entire homelab infrastructure while maintaining the convenience of declarative configuration.