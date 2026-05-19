#!/usr/bin/env bash
set -euo pipefail

detect_platform() {
  local system=$(uname -s)
  [[ "$system" == "Darwin" ]] && echo "macos" && return
  [[ "$system" == "Linux" ]] && [[ -f /etc/os-release ]] && source /etc/os-release && echo "${ID:-linux}" && return
  echo "unknown"
}

main() {
  command -v rg >/dev/null && echo "[OK] rg is available" && return 0

  local platform=$(detect_platform)
  case "$platform" in
    macos) brew install rg 2>/dev/null && echo "[OK] rg installed" ;;
    debian|ubuntu) apt-get update && apt-get install -y rg && echo "[OK] rg installed" ;;
    fedora|rhel|centos) dnf install -y rg && echo "[OK] rg installed" ;;
    arch) pacman -S --noconfirm rg && echo "[OK] rg installed" ;;
    alpine) apk add --no-cache rg && echo "[OK] rg installed" ;;
    *) echo "[ERROR] Unsupported: $platform"; exit 1 ;;
  esac
}

main "$@"
