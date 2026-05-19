Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Main {
  $tool = "ssh"
  if (Get-Command $tool -ErrorAction SilentlyContinue) {
    Write-Host "[OK] $tool is available"
    return
  }

  if ($IsMacOS) { Write-Host "[OK] OpenSSH is built-in" }
  elseif ($IsWindows) { Write-Host "[HINT] Use WSL2, Git Bash, or Windows OpenSSH" }
  elseif ($IsLinux) {
    & sudo apt-get update
    & sudo apt-get install -y openssh-client
    Write-Host "[OK] openssh installed"
  }
}

Main
