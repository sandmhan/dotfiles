# openssl Troubleshooting

## Exit Codes

| Code | Meaning |
| --- | --- |
| 0 | Success |
| 1 | Error |

## Common Issues

### "Cannot read file"

**Cause:** File doesn't exist or no permission.

**Fix:**

```bash
ls -la cert.pem
chmod 400 cert.pem  # For private keys
```

### "Bad decrypt"

**Cause:** Wrong password or corrupted file.

**Fix:**

```bash
# Verify key format
openssl rsa -in key.pem -text -noout

# Try again with correct password
```

### "Certificate verify failed"

**Cause:** CA cert not in trust store.

**Fix:**

```bash
openssl x509 -in cert.pem -noout -verify -CAfile ca.pem
```

## Resources

- Manual: man openssl
