Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Main {
  if (Get-Command rg -ErrorAction SilentlyContinue) {
    Write-Host "[OK] rg is available"
    return
  }

  if ($IsMacOS) {
    & brew install rg
    Write-Host "[OK] rg installed"
  } elseif ($IsLinux) {
    & sudo apt-get update
    & sudo apt-get install -y rg
    Write-Host "[OK] rg installed"
  } else {
    Write-Host "[HINT] Install via package manager"
    exit 1
  }
}

Main
