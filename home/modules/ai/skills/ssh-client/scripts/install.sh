#!/usr/bin/env bash
set -euo pipefail

detect_platform() {
  local system=$(uname -s)
  [[ "$system" == "Darwin" ]] && echo "macos" && return
  [[ "$system" == "Linux" ]] && [[ -f /etc/os-release ]] && source /etc/os-release && echo "${ID:-linux}" && return
  echo "unknown"
}

main() {
  local tool="ssh"
  command -v $tool >/dev/null && echo "[OK] $tool is available" && return 0

  local platform=$(detect_platform)
  case "$platform" in
    macos) echo "[OK] OpenSSH is built-in" ;;
    debian|ubuntu) apt-get update && apt-get install -y openssh-client && echo "[OK] openssh installed" ;;
    fedora|rhel|centos) dnf install -y openssh-clients && echo "[OK] openssh installed" ;;
    arch) pacman -S --noconfirm openssh && echo "[OK] openssh installed" ;;
    alpine) apk add --no-cache openssh && echo "[OK] openssh installed" ;;
    *) echo "[ERROR] Unsupported: $platform"; exit 1 ;;
  esac
}

main "$@"
