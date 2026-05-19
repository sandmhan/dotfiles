# openssl Advanced Usage

## Key Generation

```bash
# RSA keys
openssl genrsa -out private.pem 2048
openssl rsa -in private.pem -pubout -out public.pem

# ECDSA keys
openssl ecparam -name prime256v1 -genkey -noout -out ec_key.pem
```

## Certificate Operations

```bash
# Create self-signed certificate
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem

# Inspect certificate chain
openssl s_client -connect host:443 -showcerts
```

## Encryption

```bash
# Symmetric encryption
openssl enc -aes-256-cbc -salt -in file -out file.enc

# Asymmetric encryption
openssl rsautl -encrypt -inkey public.pem -in file -out file.enc
```

## Hashing and Digests

```bash
# Compute digest
openssl dgst -sha256 file

# HMAC
openssl dgst -sha256 -hmac "key" file
```

## TLS Diagnostics

```bash
# Test connection
openssl s_client -connect host:443

# Check certificate expiration
openssl x509 -in cert.pem -noout -enddate
```

## Resources

- OpenSSL Manual: <https://www.openssl.org/docs/>
