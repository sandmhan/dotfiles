#!/usr/bin/env bash
set -euo pipefail

detect_platform() {
  local system=$(uname -s)
  [[ "$system" == "Darwin" ]] && echo "macos" && return
  [[ "$system" == "Linux" ]] && [[ -f /etc/os-release ]] && source /etc/os-release && echo "${ID:-linux}" && return
  echo "unknown"
}

main() {
  command -v openssl >/dev/null && echo "[OK] openssl is available" && openssl version && return 0

  local platform=$(detect_platform)
  case "$platform" in
    macos) echo "[OK] openssl is built-in" ;;
    debian|ubuntu) apt-get update && apt-get install -y openssl && echo "[OK] openssl installed" ;;
    fedora|rhel|centos) dnf install -y openssl && echo "[OK] openssl installed" ;;
    arch) pacman -S --noconfirm openssl && echo "[OK] openssl installed" ;;
    alpine) apk add --no-cache openssl && echo "[OK] openssl installed" ;;
    *) echo "[ERROR] Unsupported: $platform"; exit 1 ;;
  esac
}

main "$@"
