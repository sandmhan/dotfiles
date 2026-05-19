# curl Install and Setup

## Prerequisites

- Network access to the target host or package repository
- Permission to install packages on the local system
- A trusted CA store for HTTPS validation

## Install by Platform

| macOS | Debian/Ubuntu | Fedora/RHEL | Arch Linux | Alpine | Windows |
| --- | --- | --- | --- | --- | --- |
| `brew install curl` | `apt-get install -y curl ca-certificates` | `dnf install -y curl ca-certificates` | `pacman -S --noconfirm curl ca-certificates` | `apk add --no-cache curl ca-certificates` | `winget install --id cURL.cURL --exact` |

## Verify Installation

```bash
curl --version
curl --help
curl --head --fail --location https://example.com
```

Check the first `curl --version` line for:

- curl version
- libcurl version
- TLS backend such as Schannel, OpenSSL, LibreSSL, or Secure Transport
- supported protocols and features

## CA Certificates and TLS

HTTPS requests fail if the local CA bundle is missing or stale.

```bash
curl --head --fail https://example.com
```

If the environment uses a custom CA:

```bash
curl --cacert /path/to/internal-ca.pem https://internal.example.com
```

Prefer fixing the CA trust store over adding `--insecure`.

## Proxy Basics

curl respects standard proxy environment variables:

```bash
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
export NO_PROXY=localhost,127.0.0.1,.internal.example.com
```

One-off proxy use:

```bash
curl --proxy http://proxy.example.com:8080 https://example.com
```

## Authentication Setup

Avoid placing secrets directly in shell history.

```bash
export API_TOKEN="replace-me"
curl --fail --location \
  --header "Authorization: Bearer $API_TOKEN" \
  https://example.com/api/items
```

For Basic auth:

```bash
export API_USER="alice"
export API_PASS="replace-me"
curl --fail --location --user "$API_USER:$API_PASS" https://example.com/api/secure
```

## Common Setup Checks

### Confirm Redirect Handling

```bash
curl --head https://example.com
curl --head --location https://example.com
```

### Confirm Body and Status Separation

```bash
curl --silent --show-error \
  --output /tmp/response.json \
  --write-out "%{http_code}\n" \
  https://example.com/api/items
```

### Confirm Header Capture

```bash
curl --silent --show-error \
  --dump-header /tmp/headers.txt \
  --output /tmp/body.txt \
  https://example.com/api/items
```

## Notes for Windows

- Windows 10 and later often ship with curl already available.
- Some environments provide multiple curl binaries. Verify the actual command with `where curl`.
- Schannel-backed builds use the Windows certificate store instead of a PEM bundle.

## Troubleshooting Setup

### curl Not Found

```bash
which curl
curl --version
```

On Windows:

```powershell
Get-Command curl
where.exe curl
```

### HTTPS Fails Immediately

- Confirm system clock correctness.
- Confirm CA certificates are installed.
- Confirm proxy or outbound TLS interception requirements.

### Wrong curl Binary

Multiple installations can lead to unexpected behavior.

```bash
which curl
type -a curl
```

## Resources

- `man curl` — Full manual
- curl docs: <https://curl.se/docs/>
- curl SSL certs: <https://curl.se/docs/sslcerts.html>
