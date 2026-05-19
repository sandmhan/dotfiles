# rg Installation and Setup

## Overview

rg is available on most platforms.

## Platform-Specific Installation

### macOS

```bash
brew install rg
```

### Debian / Ubuntu

```bash
apt-get update
apt-get install -y rg
```

### Fedora / RHEL / CentOS

```bash
dnf install -y rg
```

### Arch Linux

```bash
pacman -S rg
```

### Alpine Linux

```bash
apk add --no-cache rg
```

## Verification

```bash
which rg
rg --version 2>/dev/null || rg --help | head -3
```

## Resources

- Manual: man rg
