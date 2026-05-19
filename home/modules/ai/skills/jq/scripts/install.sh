#!/usr/bin/env bash
set -euo pipefail

detect_platform() {
  local system=$(uname -s)
  [[ "$system" == "Darwin" ]] && echo "macos" && return
  [[ "$system" == "Linux" ]] && [[ -f /etc/os-release ]] && source /etc/os-release && echo "${ID:-linux}" && return
  echo "unknown"
}

main() {
  command -v jq >/dev/null && echo "[OK] jq is available" && return 0

  local platform=$(detect_platform)
  case "$platform" in
    macos) brew install jq 2>/dev/null && echo "[OK] jq installed" ;;
    debian|ubuntu) apt-get update && apt-get install -y jq && echo "[OK] jq installed" ;;
    fedora|rhel|centos) dnf install -y jq && echo "[OK] jq installed" ;;
    arch) pacman -S --noconfirm jq && echo "[OK] jq installed" ;;
    alpine) apk add --no-cache jq && echo "[OK] jq installed" ;;
    *) echo "[ERROR] Unsupported: $platform"; exit 1 ;;
  esac
}

main "$@"
