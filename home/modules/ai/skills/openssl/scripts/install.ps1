Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Main {
  if (Get-Command openssl -ErrorAction SilentlyContinue) {
    Write-Host "[OK] openssl is available"
    & openssl version
    return
  }

  if ($IsMacOS) { Write-Host "[OK] openssl is built-in" }
  elseif ($IsLinux) {
    & sudo apt-get update
    & sudo apt-get install -y openssl
    Write-Host "[OK] openssl installed"
  }
  else { Write-Host "[HINT] Install via package manager"; exit 1 }
}

Main
