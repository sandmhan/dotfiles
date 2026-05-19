# ssh-client Advanced Usage

## Host Key Verification

```bash
# Accept new keys automatically
ssh -o StrictHostKeyChecking=accept-new user@host

# Strict verification (requires known_hosts)
ssh -o StrictHostKeyChecking=yes user@host

# Capture keys
ssh-keyscan host >> ~/.ssh/known_hosts
```

## Key Agent and Forwarding

```bash
# Start agent
eval $(ssh-agent -s)

# Add key
ssh-add ~/.ssh/id_ed25519

# Forward agent (use cautiously)
ssh -A user@host
```

## Config File

```bash
# ~/.ssh/config permissions must be 600
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
```

## Debugging

```bash
ssh -vvv user@host    # Verbose output
ssh -G user@host      # Show final config
```

## Resources

- Manual: man ssh
