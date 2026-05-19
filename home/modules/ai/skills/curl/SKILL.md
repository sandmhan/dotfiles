---
name: curl
description: >
  Transfer data with URL syntax using curl for HTTP requests, API calls, downloads,
  uploads, headers, authentication, redirects, and response inspection. Use when
  the agent needs to fetch an endpoint, send JSON or form data, inspect HTTP status
  and headers, download a file with precise request control, or troubleshoot TLS,
  proxy, and redirect behavior from the command line.
---

# curl

Transfer data with URL syntax for HTTP, HTTPS, and related protocols.

## Quick Start

1. Verify `curl` is available: `curl --version`
2. Establish the command surface: `curl --help` or `man curl`
3. Start with a safe probe: `curl --head --fail --location https://example.com`

## Intent Router

Load only the reference file needed for the active request.

- `references/install-and-setup.md` — Installing curl, checking versions, CA store, and proxy basics
- `references/cheatsheet.md` — Common flags, GET and POST requests, headers, output capture, and status extraction
- `references/advanced-usage.md` — Multipart uploads, auth flows, retries, resume, proxies, APIs, and structured response output
- `references/troubleshooting.md` — DNS, TLS, redirect, quoting, proxy, timeout, and HTTP failure recovery

## Core Workflow

1. Verify the installed build and TLS backend: `curl --version`
2. Inspect the target safely first with `--head` or a simple GET before sending data
3. Add request details explicitly: `--request`, `--header`, `--data`, `--user`, `--location`
4. Fail clearly on HTTP errors with `--fail` or `--fail-with-body`
5. Separate body, headers, and status output intentionally with `--output`, `--dump-header`, and `--write-out`

## Quick Workflows

### Read-only endpoint check

```bash
curl --head --fail --location https://example.com
```

### JSON API request

```bash
curl --fail-with-body --location --request POST \
  --header "Content-Type: application/json" \
  --data '{"name":"demo"}' \
  https://example.com/api/items
```

### File download with explicit output

```bash
curl --fail --location --output artifact.zip https://example.com/download/artifact.zip
```

## Quick Command Reference

```bash
curl --version
curl --head --fail --location https://example.com
curl --fail --location https://example.com/api/items
curl --fail --location --header "Accept: application/json" https://example.com/api/items
curl --fail-with-body --location --request POST \
  --header "Content-Type: application/json" \
  --data '{"name":"demo"}' \
  https://example.com/api/items
curl --fail --location --output artifact.zip https://example.com/download/artifact.zip
curl --silent --show-error --output response.json \
  --write-out "%{http_code}\n" \
  https://example.com/api/items
curl --fail --location --user "$API_USER:$API_PASS" https://example.com/api/secure
man curl
```

## Safety Notes

| Area | Guardrail |
| --- | --- |
| **Initial probe** | Start with `--head` or a read-only GET before mutating requests or large downloads. |
| **HTTP failures** | Prefer `--fail` or `--fail-with-body` so scripts stop on 4xx and 5xx responses. |
| **Redirects** | Add `--location` only when redirect following is intended; unexpected redirects can hide the true target. |
| **Secrets** | Avoid inline credentials when shell history, process listings, or logs are exposed. Prefer environment variables, netrc, config files, or prompting. |
| **TLS verification** | Keep certificate verification enabled. Use `--insecure` only for a temporary diagnostic step and remove it after identifying the issue. |
| **Output paths** | Set `--output` explicitly for files to avoid mixing binary payloads into terminal logs or pipelines. |
| **Request bodies** | Confirm method, content type, and payload before sending writes to production services. |
| **Structured output** | Use `--write-out` and `--dump-header` to separate status and headers from the body for reliable automation. |

## Scope Boundary

This skill does not cover full-site mirroring or recursive crawling. Use `wget` for those workflows.

## Source Policy

- Treat the installed `curl` behavior and `curl --help` or `man curl` as runtime truth.
- Use the local build output from `curl --version` to confirm TLS backend and supported protocols.
- Validate advanced flags against the official curl manual before documenting them.
- Prefer explicit flags over shorthand when documenting reproducible request behavior.

## Resource Index

- `scripts/install.sh` — Install curl on macOS or Linux.
- `scripts/install.ps1` — Install curl on Windows or any platform via PowerShell.
