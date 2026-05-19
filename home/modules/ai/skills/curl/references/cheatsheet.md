# curl Cheatsheet

## High-value options

- `--fail`: Exit non-zero on HTTP 4xx and 5xx responses without printing the body.
- `--fail-with-body`: Exit non-zero on HTTP errors and still keep the response body.
- `--location`: Follow redirects.
- `--request <METHOD>`: Set an explicit HTTP method.
- `--header "Name: value"`: Add a request header.
- `--data <data>`: Send request body data, typically for POST.
- `--output <file>`: Write the response body to a file.
- `--dump-header <file>`: Write response headers separately.
- `--write-out <format>`: Print metadata such as HTTP status or total time.
- `--user <user:password>`: Send Basic auth credentials.
- `--silent --show-error`: Suppress progress while keeping error output.

## Common one-liners

1. Safe HEAD request

```bash
curl --head --fail --location https://example.com
```

1. JSON GET

```bash
curl --fail --location \
  --header "Accept: application/json" \
  https://example.com/api/items
```

1. JSON POST

```bash
curl --fail-with-body --location \
  --header "Content-Type: application/json" \
  --data '{"name":"demo"}' \
  https://example.com/api/items
```

1. Download to a named file

```bash
curl --fail --location --output artifact.zip https://example.com/download/artifact.zip
```

1. Save body and print status

```bash
curl --silent --show-error \
  --output response.json \
  --write-out "%{http_code}\n" \
  https://example.com/api/items
```

1. Capture headers separately

```bash
curl --silent --show-error \
  --dump-header headers.txt \
  --output body.txt \
  https://example.com/api/items
```

## Input and output patterns

- Input: URL plus optional method, headers, body, auth, and TLS options
- Output: Response body to stdout by default; headers and metadata require explicit flags

## Status and response inspection

```bash
curl --silent --show-error --output /dev/null \
  --write-out "%{http_code}\n" \
  https://example.com/api/items

curl --silent --show-error \
  --write-out "status=%{http_code} time=%{time_total}s\n" \
  --output response.json \
  https://example.com/api/items
```

## Authentication patterns

```bash
curl --fail --location --user "$API_USER:$API_PASS" https://example.com/api/secure

curl --fail --location \
  --header "Authorization: Bearer $API_TOKEN" \
  https://example.com/api/secure
```

## Troubleshooting quick checks

- If the body is missing, inspect the HTTP status with `--write-out`.
- If redirects are expected, add `--location`.
- If binary output hits the terminal, add `--output <file>`.
- If the request fails before reaching the server, add `--verbose`.

## When not to use this command

- Do not use `curl` for site mirroring or recursive crawling. Use `wget` instead.
- Do not disable TLS verification in routine automation.
