# yq Install & Setup

## Installation

yq is available through multiple package managers and can be installed on Linux, macOS, and Windows.

### macOS

```bash
# Using Homebrew
brew install yq

# Using MacPorts
sudo port install yq
```

### Linux

```bash
# Using apt (Debian/Ubuntu)
sudo apt-get install yq

# Using snap
sudo snap install yq

# Using package manager (Alpine, CentOS, Fedora, etc.)
# Check your distro's package manager for yq
```

### Windows

```powershell
# Using Chocolatey
choco install yq

# Using Windows Package Manager
winget install kislyuk.yq

# Using pip (Windows)
python -m pip install yq
```

### Using pip (Universal)

```bash
pip install yq
```

This also installs `xq` (XML processor) and `tomlq` (TOML processor).

### Using Docker

```bash
docker run --rm -i kislyuk/yq yq '.foo' < file.yml
docker run --rm -v "$(pwd):/data" kislyuk/yq yq -i '.version = "2.0"' /data/file.yml
```

### Building from Source

```bash
git clone https://github.com/kislyuk/yq.git
cd yq
python setup.py install
```

## Post-Installation

### Verify Installation

```bash
yq --version
xq --version
tomlq --version
```

### Test Basic Operation

```bash
# Create a test YAML file
echo "foo: bar" > test.yml

# Extract a value
yq .foo test.yml
# Output: bar
```

## Configuration

yq respects standard jq environment variables:

- `YQ_CONFIG` — Path to yq configuration file (if supported)
- `JQFLAGS` — Flags to pass to jq automatically

Most configuration is done via command-line flags at runtime.

## Related Tools

- **jq** — Required dependency; filter engine for all yq operations
- **xq** — Automatically installed with yq; processes XML files
- **tomlq** — Automatically installed with yq; processes TOML files

Ensure jq is installed before running yq:

```bash
# Check if jq is installed
jq --version

# Install jq if needed
# macOS: brew install jq
# Linux: apt-get install jq
# Windows: choco install jq
```
