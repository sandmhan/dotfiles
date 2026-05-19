# ssh-client Installation and Setup

## Overview

OpenSSH client is standard on Unix systems.

## Platform-Specific Installation

### macOS

Built-in. Verify with: `ssh -V`

### Debian / Ubuntu

```bash
apt-get update
apt-get install -y openssh-client
```

### Fedora / RHEL / CentOS

```bash
dnf install -y openssh-clients
```

### Arch Linux

```bash
pacman -S --noconfirm openssh
```

### Alpine Linux

```bash
apk add --no-cache openssh
```

### Windows

Use WSL2, Git Bash, or OpenSSH for Windows.

## Verification

```bash
ssh -V
which ssh
```

## Resources

- Manual: man ssh
- OpenSSH: <https://www.openssh.com/>
