# curl Advanced Usage

## Explicit Methods and Bodies

curl infers `POST` when `--data` is present, but explicit methods are clearer in automation.

```bash
curl --fail-with-body --location \
  --request PUT \
  --header "Content-Type: application/json" \
  --data '{"enabled":true}' \
  https://example.com/api/items/42
```

For raw payload files:

```bash
curl --fail-with-body --location \
  --request POST \
  --header "Content-Type: application/json" \
  --data @payload.json \
  https://example.com/api/items
```

## Multipart Uploads

```bash
curl --fail-with-body --location \
  --form "file=@artifact.zip" \
  --form "name=artifact.zip" \
  https://example.com/api/uploads
```

## Auth Flows

### Basic Auth

```bash
curl --fail --location \
  --user "$API_USER:$API_PASS" \
  https://example.com/api/secure
```

### Bearer Token

```bash
curl --fail --location \
  --header "Authorization: Bearer $API_TOKEN" \
  https://example.com/api/secure
```

### netrc

Use `.netrc` when repeated credentialed access is required.

```bash
curl --fail --location --netrc https://example.com/api/secure
```

Protect the file:

```bash
chmod 600 ~/.netrc
```

## Retries and Timeouts

For transient network failures:

```bash
curl --fail --location \
  --retry 5 \
  --retry-delay 2 \
  --retry-all-errors \
  --connect-timeout 10 \
  --max-time 60 \
  https://example.com/api/items
```

Use bounded retries in automation so jobs fail predictably.

## Resume and Partial Downloads

Resume a partially downloaded file:

```bash
curl --fail --location --continue-at - \
  --output artifact.zip \
  https://example.com/download/artifact.zip
```

Confirm the remote server supports ranged requests before relying on resume behavior.

## Proxy and CA Overrides

One-off proxy:

```bash
curl --proxy http://proxy.example.com:8080 https://example.com
```

Custom CA:

```bash
curl --cacert /path/to/internal-ca.pem https://internal.example.com
```

Client certificate:

```bash
curl --cert client.pem --key client.key https://internal.example.com
```

## Structured Output Patterns

Print metadata in a machine-friendly form:

```bash
curl --silent --show-error \
  --output response.json \
  --write-out '{"status":%{http_code},"size":%{size_download},"time":"%{time_total}"}\n' \
  https://example.com/api/items
```

Capture headers and body separately:

```bash
curl --silent --show-error \
  --dump-header headers.txt \
  --output body.json \
  https://example.com/api/items
```

## Verbose Diagnostics

Use `--verbose` when connection or TLS details matter.

```bash
curl --verbose --fail --location https://example.com/api/items
```

Use `--trace-ascii` for deeper inspection when debugging quoting, redirects, or auth headers.

```bash
curl --trace-ascii trace.log --fail --location https://example.com/api/items
```

Review traces carefully because they may contain secrets.

## API Workflow Example

```bash
export API_TOKEN="replace-me"

curl --silent --show-error --fail-with-body --location \
  --header "Authorization: Bearer $API_TOKEN" \
  --header "Accept: application/json" \
  --output items.json \
  --write-out "status=%{http_code}\n" \
  https://example.com/api/items
```

## Safe Download Workflow

```bash
curl --head --fail --location https://example.com/releases/tool.zip

curl --fail --location \
  --output tool.zip \
  https://example.com/releases/tool.zip
```

Validate checksums after download when the publisher provides them.

## Resources

- `man curl`
- curl command-line options: <https://curl.se/docs/manpage.html>
