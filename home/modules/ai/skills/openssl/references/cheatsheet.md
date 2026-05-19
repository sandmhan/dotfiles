# openssl Cheatsheet

## High-value options

- `x509`: Inspect and transform X.509 certificates.

- `dgst`: Compute cryptographic digests.

- `rand`: Generate random bytes.

- `s_client`: Inspect live TLS endpoint handshakes.

## Common one-liners

1. Check CSR details

```bash

openssl req -in req.csr -noout -text

```

1. Convert cert to DER

```bash

openssl x509 -in cert.pem -outform der -out cert.der

```

1. Probe TLS cert chain

```bash

openssl s_client -connect example.com:443 -servername example.com </dev/null

```

## Input/output patterns

- Input: Key/cert files, binary/text payloads, and network endpoints for TLS probes.

- Output: Digests, key material transforms, certificate fields, and TLS diagnostics.

## Troubleshooting quick checks

- If command fails with unsupported algorithm, confirm OpenSSL build capabilities.

- If certificate parsing fails, verify PEM boundaries and file integrity.

- If TLS handshake output is noisy, add focused flags and capture only required sections.

## When not to use this command

- Do not use `openssl` as a substitute for full PKI policy validation tooling.
