# openssl Installation and Setup

## Overview

OpenSSL is the standard cryptography library on Unix systems.

## Platform-Specific Installation

### macOS

```bash
# openssl is built-in
which openssl

# Or install via Homebrew for latest version
brew install openssl
```

### Debian / Ubuntu

```bash
apt-get update
apt-get install -y openssl
```

### Fedora / RHEL / CentOS

```bash
dnf install -y openssl
```

### Arch Linux

```bash
pacman -S --noconfirm openssl
```

### Alpine Linux

```bash
apk add --no-cache openssl
```

## Verification

```bash
openssl version
openssl help
```

## Resources

- Official: <https://www.openssl.org/>
- Manual: man openssl
