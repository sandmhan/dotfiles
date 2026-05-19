#!/usr/bin/env bash
set -euo pipefail

detect_platform() {
  local system
  system="$(uname -s)"

  if [[ "$system" == "Darwin" ]]; then
    echo "macos"
    return
  fi

  if [[ "$system" == "Linux" ]]; then
    if [[ -f /etc/os-release ]]; then
      # shellcheck disable=SC1091
      source /etc/os-release
      echo "${ID:-linux}"
    else
      echo "linux"
    fi
    return
  fi

  echo "unknown"
}

main() {
  if command -v curl >/dev/null 2>&1; then
    echo "[OK] $(curl --version | head -n 1) already installed"
    echo "[HINT] See references/install-and-setup.md for CA and proxy setup"
    return 0
  fi

  local platform
  platform="$(detect_platform)"

  case "$platform" in
    macos)
      if command -v brew >/dev/null 2>&1; then
        brew install curl
      else
        echo "[ERROR] Homebrew not found. Install from https://brew.sh"
        exit 1
      fi
      ;;
    debian|ubuntu)
      sudo apt-get update
      sudo apt-get install -y curl ca-certificates
      ;;
    fedora|rhel|centos)
      sudo dnf install -y curl ca-certificates
      ;;
    arch)
      sudo pacman -S --noconfirm curl ca-certificates
      ;;
    alpine)
      sudo apk add --no-cache curl ca-certificates
      ;;
    *)
      echo "[ERROR] Unsupported platform: $platform"
      echo "[HINT] Install curl with your platform package manager"
      exit 1
      ;;
  esac

  if command -v curl >/dev/null 2>&1; then
    curl --version | head -n 1
    echo "[OK] Installation verified"
  else
    echo "[ERROR] Installation verification failed"
    exit 1
  fi
}

main "$@"