#!/bin/bash
# changelog skill installer
# Checks for git-cliff (optional) and offers to install if missing

set -e

echo "🔍 Checking for git-cliff..."

# Check if git-cliff is already installed
if command -v git-cliff &> /dev/null; then
    VERSION=$(git-cliff --version 2>&1 | cut -d' ' -f2 || echo "unknown")
    echo "✅ git-cliff is installed (version $VERSION)"
    exit 0
fi

echo "ℹ️  git-cliff is not installed, but the changelog skill works fine without it."
echo ""
echo "git-cliff is optional and useful for:"
echo "  - Automating changelog generation from commit messages"
echo "  - Enforcing conventional commit structure (feat:, fix:, etc.)"
echo "  - Bulk-adding entries to [Unreleased] before release"
echo ""

# Offer to install
read -p "Would you like to install git-cliff now? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping git-cliff installation. You can always install it later."
    exit 0
fi

# Detect OS and install
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew not found. Install git-cliff manually:"
        echo "   brew install git-cliff"
        exit 1
    fi
    echo "📦 Installing git-cliff via Homebrew..."
    brew install git-cliff
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if command -v apt-get &> /dev/null; then
        echo "📦 Installing git-cliff via apt..."
        sudo apt-get update
        sudo apt-get install -y git-cliff
    elif command -v dnf &> /dev/null; then
        echo "📦 Installing git-cliff via dnf..."
        sudo dnf install -y git-cliff
    elif command -v pacman &> /dev/null; then
        echo "📦 Installing git-cliff via pacman..."
        sudo pacman -S --noconfirm git-cliff
    elif command -v zypper &> /dev/null; then
        echo "📦 Installing git-cliff via zypper..."
        sudo zypper install -y git-cliff
    elif command -v cargo &> /dev/null; then
        echo "📦 Installing git-cliff via cargo..."
        cargo install git-cliff
    else
        echo "❌ Could not determine package manager. Install git-cliff manually:"
        echo "   See: https://github.com/orhun/git-cliff#installation"
        exit 1
    fi
else
    echo "❌ Unsupported OS. Install git-cliff manually from:"
    echo "   https://github.com/orhun/git-cliff#installation"
    exit 1
fi

# Verify installation
if command -v git-cliff &> /dev/null; then
    VERSION=$(git-cliff --version 2>&1 | cut -d' ' -f2 || echo "unknown")
    echo "✅ git-cliff installed successfully (version $VERSION)"
    exit 0
else
    echo "❌ Installation failed. Check the error messages above."
    exit 1
fi
