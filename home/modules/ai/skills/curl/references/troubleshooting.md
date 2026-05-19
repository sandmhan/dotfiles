# curl Troubleshooting

## Exit Code Reference

Common curl exit codes:

| Code | Meaning |
| --- | --- |
| 6 | Could not resolve host |
| 7 | Failed to connect to host |
| 22 | HTTP page not retrieved with `--fail` enabled |
| 28 | Operation timeout |
| 35 | TLS or SSL connect error |
| 47 | Too many redirects |
| 60 | Peer certificate cannot be authenticated |

## DNS and Connection Failures

### Symptom

`curl: (6) Could not resolve host` or `curl: (7) Failed to connect`

### Checks

```bash
nslookup example.com
curl --verbose https://example.com
```

Confirm:

- hostname spelling
- DNS reachability
- proxy requirements
- firewall or outbound network policy

## HTTP 4xx or 5xx Responses

Use `--fail-with-body` so the body is available for diagnosis.

```bash
curl --fail-with-body --location https://example.com/api/items
```

Capture status and body separately:

```bash
curl --silent --show-error \
  --output error-body.txt \
  --write-out "%{http_code}\n" \
  https://example.com/api/items
```

## Redirect Loops

### Symptom

`curl: (47) Maximum redirects followed`

### Fix

```bash
curl --head https://example.com
curl --head --location https://example.com
```

Inspect the `Location` headers and confirm the target URL is correct before raising `--max-redirs`.

## TLS and Certificate Errors

### Symptom

`curl: (60) SSL certificate problem`

### Checks

```bash
curl --verbose https://example.com
curl --cacert /path/to/internal-ca.pem https://internal.example.com
```

Prefer:

- fixing the CA store
- adding the correct internal CA
- correcting the system clock

Avoid keeping `--insecure` in production commands.

## Quoting Problems

Malformed JSON and headers are often shell quoting issues.

```bash
curl --fail-with-body --location \
  --header "Content-Type: application/json" \
  --data '{"name":"demo"}' \
  https://example.com/api/items
```

If the payload grows, store it in a file:

```bash
curl --fail-with-body --location \
  --header "Content-Type: application/json" \
  --data @payload.json \
  https://example.com/api/items
```

## Proxy Issues

### Symptom

Requests work in a browser but fail in curl.

### Checks

```bash
echo "$HTTPS_PROXY"
curl --proxy http://proxy.example.com:8080 https://example.com
```

Confirm:

- proxy URL
- auth requirements
- `NO_PROXY` exclusions for internal hosts

## Body Printed to Terminal

Binary output or large responses should go to a file.

```bash
curl --fail --location --output artifact.zip https://example.com/download/artifact.zip
```

## Auth Problems

### Common causes

- expired token
- missing `Authorization` header
- incorrect Basic auth user or password
- credentials sent to the wrong host after redirects

### Checks

```bash
curl --verbose --location \
  --header "Authorization: Bearer $API_TOKEN" \
  https://example.com/api/secure
```

Redact traces before sharing them.

## Timeout Tuning

```bash
curl --fail --location \
  --connect-timeout 10 \
  --max-time 60 \
  https://example.com/api/items
```

Increase timeouts only after confirming the target service is healthy.

## Resources

- `man curl`
- curl exit codes: <https://ec.haxx.se/cmdline/exitcode.html>
