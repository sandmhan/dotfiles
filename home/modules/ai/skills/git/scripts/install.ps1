#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Platform {
  if ($IsWindows) { return 'windows' }
  if ($IsMacOS) { return 'macos' }
  if ($IsLinux) { return 'linux' }
  return 'unknown'
}

function Main {
  $platform = Get-Platform

  # Check if git is already installed
  if (Get-Command git -ErrorAction SilentlyContinue) {
    $version = & git --version
    Write-Host "[OK] $version already installed"
    Write-Host "[HINT] See 'references/install-and-setup.md' for post-install configuration"
    return
  }

  switch ($platform) {
    'windows' {
      Write-Host "[INFO] Installing Git on Windows via winget..."
      if (Get-Command winget -ErrorAction SilentlyContinue) {
        & winget install Git.Git
        Write-Host "[OK] Git installed successfully"
      } else {
        Write-Host "[ERROR] winget not found. Download Git from https://git-scm.com/download/win"
        exit 1
      }
    }

    'macos' {
      Write-Host "[INFO] Installing Git on macOS via Homebrew..."
      if (Get-Command brew -ErrorAction SilentlyContinue) {
        & brew install git
        Write-Host "[OK] Git installed successfully"
      } else {
        Write-Host "[ERROR] Homebrew not found. Install from https://brew.sh"
        exit 1
      }
    }

    'linux' {
      Write-Host "[INFO] Installing Git on Linux..."
      # Detect distro and use appropriate package manager
      if (Test-Path '/etc/os-release') {
        $osInfo = Get-Content /etc/os-release | ConvertFrom-StringData
        $distro = $osInfo.ID

        switch ($distro) {
          { $_ -in 'debian', 'ubuntu' } {
            & sudo apt update
            & sudo apt install -y git
          }
          { $_ -in 'fedora', 'rhel', 'centos' } {
            & sudo dnf install -y git
          }
          'arch' {
            & sudo pacman -S --noconfirm git
          }
          'alpine' {
            & sudo apk add git
          }
          default {
            Write-Host "[WARN] Unknown distro: $distro"
            Write-Host "[HINT] Install git manually for your distro"
            exit 1
          }
        }
        Write-Host "[OK] Git installed successfully"
      } else {
        Write-Host "[ERROR] Cannot detect Linux distro"
        exit 1
      }
    }

    default {
      Write-Host "[ERROR] Unsupported platform: $platform"
      exit 1
    }
  }

  # Verify installation
  if (Get-Command git -ErrorAction SilentlyContinue) {
    & git --version
    Write-Host "[OK] Installation verified"
    Write-Host ""
    Write-Host "[HINT] Configure git with: git config --global user.name 'Your Name'"
    Write-Host "[HINT] See 'references/install-and-setup.md' for complete setup steps"
  } else {
    Write-Host "[ERROR] Installation verification failed"
    exit 1
  }
}

Main
