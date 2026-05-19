#!/usr/bin/env bash
set -euo pipefail

# git installer for macOS, Linux, Windows (WSL2/Git Bash)

detect_platform() {
  local system=$(uname -s)
  if [[ "$system" == "Darwin" ]]; then
    echo "macos"
  elif [[ "$system" == "Linux" ]]; then
    if [[ -f /etc/os-release ]]; then
      source /etc/os-release
      echo "${ID:-linux}"
    else
      echo "linux"
    fi
  elif [[ "$system" == "MINGW64_NT"* || "$system" == "MSYS_NT"* ]]; then
    echo "git-bash"
  else
    echo "unknown"
  fi
}

main() {
  local platform=$(detect_platform)

  # Check if git is already installed
  if command -v git &>/dev/null; then
    local version=$(git --version)
    echo "[OK] $version already installed"
    echo "[HINT] Run 'references/install-and-setup.md' for post-install configuration"
    return 0
  fi

  case "$platform" in
    macos)
      echo "[INFO] Installing git on macOS via Homebrew..."
      if command -v brew &>/dev/null; then
        brew install git
        echo "[OK] git installed successfully"
      else
        echo "[ERROR] Homebrew not found. Install from https://brew.sh"
        exit 1
      fi
      ;;

    debian|ubuntu)
      echo "[INFO] Installing git on Debian/Ubuntu..."
      sudo apt update
      sudo apt install -y git
      echo "[OK] git installed successfully"
      ;;

    fedora|rhel|centos)
      echo "[INFO] Installing git on Fedora/RHEL..."
      sudo dnf install -y git
      echo "[OK] git installed successfully"
      ;;

    arch)
      echo "[INFO] Installing git on Arch Linux..."
      sudo pacman -S --noconfirm git
      echo "[OK] git installed successfully"
      ;;

    alpine)
      echo "[INFO] Installing git on Alpine..."
      sudo apk add git
      echo "[OK] git installed successfully"
      ;;

    git-bash|unknown)
      echo "[WARN] Git Bash or unknown platform detected"
      echo "[HINT] Git usually comes with Git for Windows. Download from https://git-scm.com/download/win"
      exit 1
      ;;

    *)
      echo "[ERROR] Unsupported platform: $platform"
      exit 1
      ;;
  esac

  # Verify installation
  if command -v git &>/dev/null; then
    git --version
    echo "[OK] Installation verified"
    echo ""
    echo "[HINT] Configure git with: git config --global user.name 'Your Name'"
    echo "[HINT] See references/install-and-setup.md for complete setup steps"
  else
    echo "[ERROR] Installation verification failed"
    exit 1
  fi
}

main "$@"
