# ssh-client Troubleshooting

## Common Errors

### "Permission denied (publickey)"

**Cause:** Wrong key or server not configured for this key.

**Fix:**

```bash
ssh -vvv user@host  # Verbose output shows which key tried

# Check public key on server
cat ~/.ssh/id_ed25519.pub | ssh user@host "cat >> ~/.ssh/authorized_keys"
```

### "Host key verification failed"

**Cause:** Host not in known_hosts or key changed.

**Fix:**

```bash
ssh-keyscan -p 22 host >> ~/.ssh/known_hosts
ssh user@host
```

### "Connection refused"

**Cause:** SSH service not running or wrong port.

**Fix:**

```bash
ssh -p 2222 user@host  # Try alternate port
ssh -v user@host       # Check if service is running
```

## Resources

- Manual: man ssh
