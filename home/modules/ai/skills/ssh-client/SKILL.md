---
name: ssh-client
description: Establish secure SSH connections with strict host verification and key management. Use when the agent needs remote access, Git-over-SSH operations, or key pair validation.
---

# ssh (client)

Secure remote access with strict host key verification and known_hosts management.

## Prerequisite Check

Run this before proposing remote access steps:

```bash
command -v ssh >/dev/null 2>&1 || ssh -V
```

If `ssh` is missing, surface that first and point to `scripts/install.sh` or `scripts/install.ps1`. Do not suggest insecure fallbacks such as disabling host verification or using plaintext remote shells.

## Quick Start

1. Verify `ssh` is available: `ssh -V` or `man ssh`
2. Establish the command surface: `man ssh` or `ssh -h`
3. Start with connectivity check: `ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new host`

## Intent Router

Load only the reference file needed for the active request.

- `references/install-and-setup.md` — Installing OpenSSH on macOS, Linux, Windows
- `references/cheatsheet.md` — Common options, authentication, host key management
- `references/advanced-usage.md` — Strict verification, key forwarding, config files
- `references/troubleshooting.md` — Authentication errors, host key issues, permission problems

## Core Workflow

1. Verify ssh is available: `ssh -V`
2. Capture host keys before first connection: `ssh-keyscan host >> ~/.ssh/known_hosts`
3. Use strict host checking: `ssh -o StrictHostKeyChecking=accept-new user@host`
4. Debug with verbose logging: `ssh -vvv user@host`

## Quick Command Reference

```bash
ssh -V                                 # Check version
ssh-keyscan -p 22 github.com >> ~/.ssh/known_hosts  # Capture host keys
ssh -o StrictHostKeyChecking=accept-new user@host   # Connect with verification
ssh -o StrictHostKeyChecking=yes user@host          # Strict verification
ssh -vvv user@host                     # Verbose debugging (3x)
ssh-keygen -R hostname                 # Remove hostname from known_hosts
man ssh                                # Full manual
```

```bash
# Probe connectivity without interactive password prompts
ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new user@host true

# Inspect the host key before a first connection
ssh-keyscan -p 22 host | tee -a ~/.ssh/known_hosts
```

## Safety Notes

| Area | Guardrail |
| --- | --- |
| **Host key verification** | Always use StrictHostKeyChecking=accept-new or yes. Never use no. Prevents MITM attacks. |
| **Private key permissions** | Restrict to 600 (chmod 600 ~/.ssh/id_rsa). SSH refuses keys with wrong permissions. |
| **known_hosts management** | Verify host keys before adding. Use ssh-keyscan carefully from trusted networks only. |
| **Key passphrase** | Protect private keys with strong passphrases. Use ssh-agent for convenient access. |
| **Agent forwarding** | Be cautious with -A. Forwarding agent is high-risk on untrusted hosts. |
| **Config file** | Restrict permissions (chmod 600 ~/.ssh/config). May contain sensitive information. |

Recovery note: if the runtime has no `ssh` client, stop at install guidance. Do not route around that by suggesting telnet-like substitutes or `StrictHostKeyChecking=no`.

## Source Policy

- Treat the installed `ssh` behavior and `man ssh` as runtime truth.
- Use OpenSSH documentation for security best practices.

## Resource Index

- `scripts/install.sh` — Install OpenSSH on macOS or Linux.
- `scripts/install.ps1` — Install OpenSSH on Windows or any platform via PowerShell.
