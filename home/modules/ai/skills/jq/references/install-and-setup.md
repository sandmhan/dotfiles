# jq Installation and Setup

## Overview

jq is available on most platforms.

## Platform-Specific Installation

### macOS

```bash
brew install jq
```

### Debian / Ubuntu

```bash
apt-get update
apt-get install -y jq
```

### Fedora / RHEL / CentOS

```bash
dnf install -y jq
```

### Arch Linux

```bash
pacman -S jq
```

### Alpine Linux

```bash
apk add --no-cache jq
```

## Verification

```bash
which jq
jq --version 2>/dev/null || jq --help | head -3
```

## Resources

- Manual: man jq
