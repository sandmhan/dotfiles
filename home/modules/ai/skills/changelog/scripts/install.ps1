# changelog skill installer
# Checks for git-cliff (optional) and offers to install if missing

$ErrorActionPreference = "Stop"

Write-Host "🔍 Checking for git-cliff..."

# Check if git-cliff is installed
$gitCliffExists = $null -ne (Get-Command git-cliff -ErrorAction SilentlyContinue)

if ($gitCliffExists) {
    try {
        $version = git-cliff --version 2>&1 | Select-Object -First 1
        Write-Host "✅ git-cliff is installed ($version)"
        exit 0
    } catch {
        Write-Host "✅ git-cliff is installed"
        exit 0
    }
}

Write-Host "ℹ️  git-cliff is not installed, but the changelog skill works fine without it."
Write-Host ""
Write-Host "git-cliff is optional and useful for:"
Write-Host "  - Automating changelog generation from commit messages"
Write-Host "  - Enforcing conventional commit structure (feat:, fix:, etc.)"
Write-Host "  - Bulk-adding entries to [Unreleased] before release"
Write-Host ""

# Offer to install
$response = Read-Host "Would you like to install git-cliff now? (y/n)"

if ($response -notmatch '^[Yy]$') {
    Write-Host "Skipping git-cliff installation. You can always install it later."
    exit 0
}

# Determine OS and install method
$isWindows = $PSVersionTable.Platform -eq "Win32NT" -or $null -eq $PSVersionTable.Platform
$isMacOS = $PSVersionTable.OS -like "*Darwin*"
$isLinux = $PSVersionTable.OS -like "*Linux*"

if ($isWindows) {
    # Try winget first
    $wingetExists = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)
    if ($wingetExists) {
        Write-Host "📦 Installing git-cliff via winget..."
        winget install git-cliff
    } else {
        # Try scoop
        $scoopExists = $null -ne (Get-Command scoop -ErrorAction SilentlyContinue)
        if ($scoopExists) {
            Write-Host "📦 Installing git-cliff via scoop..."
            scoop install git-cliff
        } else {
            # Try cargo
            $cargoExists = $null -ne (Get-Command cargo -ErrorAction SilentlyContinue)
            if ($cargoExists) {
                Write-Host "📦 Installing git-cliff via cargo..."
                cargo install git-cliff
            } else {
                Write-Host "❌ Could not find winget, scoop, or cargo. Install git-cliff manually:"
                Write-Host "   See: https://github.com/orhun/git-cliff#installation"
                exit 1
            }
        }
    }
} elseif ($isMacOS) {
    # Try Homebrew
    $brewExists = $null -ne (Get-Command brew -ErrorAction SilentlyContinue)
    if ($brewExists) {
        Write-Host "📦 Installing git-cliff via Homebrew..."
        brew install git-cliff
    } else {
        # Try cargo
        $cargoExists = $null -ne (Get-Command cargo -ErrorAction SilentlyContinue)
        if ($cargoExists) {
            Write-Host "📦 Installing git-cliff via cargo..."
            cargo install git-cliff
        } else {
            Write-Host "❌ Could not find Homebrew or cargo. Install git-cliff manually:"
            Write-Host "   brew install git-cliff"
            exit 1
        }
    }
} elseif ($isLinux) {
    # Try apt first
    $aptExists = $null -ne (Get-Command apt-get -ErrorAction SilentlyContinue)
    if ($aptExists) {
        Write-Host "📦 Installing git-cliff via apt..."
        sudo apt-get update
        sudo apt-get install -y git-cliff
    } else {
        # Try cargo
        $cargoExists = $null -ne (Get-Command cargo -ErrorAction SilentlyContinue)
        if ($cargoExists) {
            Write-Host "📦 Installing git-cliff via cargo..."
            cargo install git-cliff
        } else {
            Write-Host "❌ Could not find package manager or cargo. Install git-cliff manually:"
            Write-Host "   See: https://github.com/orhun/git-cliff#installation"
            exit 1
        }
    }
} else {
    Write-Host "❌ Unsupported OS. Install git-cliff manually from:"
    Write-Host "   https://github.com/orhun/git-cliff#installation"
    exit 1
}

# Verify installation
$gitCliffExists = $null -ne (Get-Command git-cliff -ErrorAction SilentlyContinue)
if ($gitCliffExists) {
    try {
        $version = git-cliff --version 2>&1 | Select-Object -First 1
        Write-Host "✅ git-cliff installed successfully ($version)"
        exit 0
    } catch {
        Write-Host "✅ git-cliff installed successfully"
        exit 0
    }
} else {
    Write-Host "❌ Installation failed. Check the error messages above."
    exit 1
}
