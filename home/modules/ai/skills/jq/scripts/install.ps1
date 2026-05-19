Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Main {
  if (Get-Command jq -ErrorAction SilentlyContinue) {
    Write-Host "[OK] jq is available"
    return
  }

  if ($IsMacOS) {
    & brew install jq
    Write-Host "[OK] jq installed"
  } elseif ($IsLinux) {
    & sudo apt-get update
    & sudo apt-get install -y jq
    Write-Host "[OK] jq installed"
  } else {
    Write-Host "[HINT] Install via package manager"
    exit 1
  }
}

Main
