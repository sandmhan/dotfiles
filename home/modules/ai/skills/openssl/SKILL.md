---
name: openssl
description: Perform cryptographic operations including certificate inspection, key generation, hashing, and TLS diagnostics with explicit subcommands. Use when the agent needs certificate validation, key conversion, secure random generation, or encryption operations.
---

# openssl

Cryptographic operations for certificates, keys, hashing, and TLS diagnostics.

## Quick Start

1. Verify `openssl` is available: `openssl version` or `man openssl`
2. Establish the command surface: `openssl help` or `openssl help <subcommand>`
3. Start with read-only inspection: `openssl x509 -in cert.pem -noout -text`

## Intent Router

Load only the reference file needed for the active request.

- `references/install-and-setup.md` — Installing openssl on macOS, Linux, Windows
- `references/cheatsheet.md` — Subcommands, certificate operations, key management
- `references/advanced-usage.md` — Advanced key operations, encryption, scripting patterns
- `references/troubleshooting.md` — Certificate validation errors, key issues, TLS diagnostics

## Core Workflow

1. Verify openssl is available: `openssl version`
2. Identify the subcommand needed (x509, rsa, enc, etc.)
3. Use explicit algorithm parameters (e.g., `-sha256`, `-aes-256-cbc`)
4. Validate certificates and keys before using them
5. Never expose private keys or passphrases in logs

## Quick Command Reference

```bash
openssl version                        # Check version
openssl help                           # List all subcommands
openssl x509 -in cert.pem -noout -text # Inspect certificate
openssl rsa -in key.pem -noout -text   # Inspect private key
openssl dgst -sha256 file.bin          # Compute SHA-256 hash
openssl rand -hex 32                   # Generate random bytes
openssl s_client -connect host:443     # Test TLS connection
man openssl                            # Full manual
```

## Safety Notes

| Area | Guardrail |
| --- | --- |
| **Private keys** | Never expose in logs, history, or files. Use `-noout` for inspection. Restrict file permissions (chmod 600). |
| **Passphrases** | Use interactive password prompt, never command-line arguments. Passphrases visible in history. |
| **Certificate validation** | Verify chain trust, expiration, and hostname separately. Don't trust self-signed unless explicit. |
| **Key generation** | Always use explicit algorithms (RSA, ECDSA with curve). Document key sizes. |
| **TLS diagnostics** | Use `s_client` carefully. Don't verify untrusted certificates. |
| **Encryption** | State algorithm explicitly. Use authenticated encryption when possible. |

## Source Policy

- Treat the installed `openssl` behavior and `man openssl` as runtime truth.
- Use OpenSSL documentation for cryptographic best practices.

## Resource Index

- `scripts/install.sh` — Install openssl on macOS or Linux.
- `scripts/install.ps1` — Install openssl on Windows or any platform via PowerShell.
