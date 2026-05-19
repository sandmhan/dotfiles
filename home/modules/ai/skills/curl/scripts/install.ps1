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
  if (Get-Command curl -ErrorAction SilentlyContinue) {
    $version = & curl --version 2>&1 | Select-Object -First 1
    Write-Host "[OK] $version already installed"
    Write-Host "[HINT] See 'references/install-and-setup.md' for CA and proxy setup"
    return
  }

  $platform = Get-Platform

  switch ($platform) {
    'windows' {
      if (Get-Command winget -ErrorAction SilentlyContinue) {
        & winget install --id cURL.cURL --exact --accept-source-agreements --accept-package-agreements
      } else {
        Write-Host "[ERROR] winget not found. Install curl from your package manager or https://curl.se/windows/"
        exit 1
      }
    }
    'macos' {
      if (Get-Command brew -ErrorAction SilentlyContinue) {
        & brew install curl
      } else {
        Write-Host "[ERROR] Homebrew not found. Install from https://brew.sh"
        exit 1
      }
    }
    'linux' {
      if (Test-Path '/etc/os-release') {
        $osInfo = Get-Content /etc/os-release | ConvertFrom-StringData
        $distro = $osInfo.ID

        switch ($distro) {
          { $_ -in 'debian', 'ubuntu' } {
            & sudo apt-get update
            & sudo apt-get install -y curl ca-certificates
          }
          { $_ -in 'fedora', 'rhel', 'centos' } {
            & sudo dnf install -y curl ca-certificates
          }
          'arch' {
            & sudo pacman -S --noconfirm curl ca-certificates
          }
          'alpine' {
            & sudo apk add --no-cache curl ca-certificates
          }
          default {
            Write-Host "[ERROR] Unsupported Linux distribution: $distro"
            exit 1
          }
        }
      } else {
        Write-Host "[ERROR] Cannot detect Linux distribution"
        exit 1
      }
    }
    default {
      Write-Host "[ERROR] Unsupported platform: $platform"
      exit 1
    }
  }

  if (Get-Command curl -ErrorAction SilentlyContinue) {
    & curl --version 2>&1 | Select-Object -First 1
    Write-Host "[OK] Installation verified"
  } else {
    Write-Host "[ERROR] Installation verification failed"
    exit 1
  }
}

Main