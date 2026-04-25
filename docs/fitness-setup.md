# wger Fitness Tracking Setup Guide

## Overview

wger is a self-hosted fitness tracking application for exercise logging, nutrition planning, and biometric measurements. It is deployed as a stack of OCI containers: the wger Django application, PostgreSQL, Redis, a Celery background worker, and an Nginx reverse proxy.

## Features

- **Exercise Tracking**: Log workouts, manage exercise database with images and videos
- **Nutrition Planning**: Track meals, calculate macros, barcode scanning via Flutter mobile app
- **Biometric Measurements**: Weight, body fat, and custom measurements over time
- **REST API**: Full API at `/api/v2/` for third-party integration
- **Prometheus Metrics**: Native `/metrics` endpoint for Grafana dashboards
- **Mobile Apps**: Native Flutter apps for Android and iOS with offline support

## Architecture

```
┌─────────────────┐   HTTP :80    ┌──────────────────┐   proxy :8000  ┌─────────────────┐
│   Web Browser   │◄────────────►│     Nginx        │◄──────────────►│   wger (Django) │
│   Mobile App    │              │  Reverse Proxy   │               │   Application   │
└─────────────────┘              └──────────────────┘               └─────────────────┘
                                                                        │         │
                                                           SQL :5432    │         │ Redis :6379
                                                                        ▼         ▼
                                                                   ┌──────────┐ ┌──────────┐
                                                                   │PostgreSQL│ │  Redis   │
                                                                   │   DB     │ │  Cache   │
                                                                   └──────────┘ └──────────┘
                                                                        ▲
                                                                        │ SQL
                                                                   ┌──────────┐
                                                                   │  Celery  │
                                                                   │  Worker  │
                                                                   └──────────┘
```

All containers run on a shared podman network (`wger-net`) and communicate by container name.

## Prerequisites

### 1. Secrets Configuration

Generate and configure wger secrets:

```bash
# Generate Django secret key and PostgreSQL password
DJANGO_SECRET_KEY=$(openssl rand -base64 64)
POSTGRES_PASSWORD=$(openssl rand -base64 32)

# Create unencrypted secrets file
cat > secrets/fitness/secrets.yaml << EOF
wger/django-secret-key: $DJANGO_SECRET_KEY
wger/postgres-password: $POSTGRES_PASSWORD
EOF

# Encrypt with sops
sops -e -i secrets/fitness/secrets.yaml

# Verify encryption
sops -d secrets/fitness/secrets.yaml
```

### 2. Age Key Setup

Ensure the fitness host has an age key for secret decryption:

```bash
# Generate age key on fitness host
ssh user@fitness-host "sudo mkdir -p /var/lib/sops-nix"
ssh user@fitness-host "sudo age-keygen -o /var/lib/sops-nix/key.txt"

# Get public key for .sops.yaml
ssh user@fitness-host "sudo age-keygen -y /var/lib/sops-nix/key.txt"
```

## Deployment

### VM Deployment (Phase 3 - Gaming PC Node)

```bash
# 1. Deploy base VM using proven VMA pattern
qmrestore /var/lib/vz/dump/vzdump-qemu-nixos-*.vma.zst 107 --storage local-zfs

# 2. Configure VM resources
qm set 107 --cores 2 --memory 2048 --name fitness
qm set 107 --net0 virtio,bridge=vmbr0,firewall=1

# 3. Start VM and get IP
qm start 107

# 4. Deploy wger configuration
nixos-rebuild switch --target-host sandmhan@[VM_IP] --flake .#fitness --sudo

# 5. Verify services
curl http://[VM_IP]:80/            # Nginx proxy
curl http://[VM_IP]:8000/api/v2/   # wger API (direct)
```

## Configuration

### Module Options

The wger module (`systemModules/wger.nix`) provides these options under `homelab.wger`:

| Option | Default | Description |
|--------|---------|-------------|
| `enable` | `false` | Enable wger fitness tracker |
| `deploymentType` | `"vm"` | `vm` or `container` |
| `resourceProfile` | `"standard"` | `minimal`, `standard`, or `high` |
| `domain` | `"fitness.homelab.local"` | Domain name for wger |
| `httpPort` | `8000` | HTTP port for Django app |
| `reverseProxy.enable` | `true` | Nginx reverse proxy |
| `monitoring.enable` | `true` | Prometheus node exporter |
| `images.wger` | `"wger/server:latest"` | wger container image |
| `images.postgres` | `"postgres:15-alpine"` | PostgreSQL container image |
| `images.redis` | `"redis:7-alpine"` | Redis container image |
| `database.name` | `"wger"` | PostgreSQL database name |
| `database.user` | `"wger"` | PostgreSQL database user |

### Container Stack

| Container | Image | Purpose | Port |
|-----------|-------|---------|------|
| `wger` | `wger/server:latest` | Django application | 8000:80 |
| `wger-db` | `postgres:15-alpine` | PostgreSQL database | internal |
| `wger-redis` | `redis:7-alpine` | Cache and session store | internal |
| `wger-celery` | `wger/server:latest` | Background task worker | none |

### Systemd Resource Limits

| Service | Container Deploy | VM Minimal | VM Standard/High |
|---------|-----------------|------------|------------------|
| wger | 512M / 50% CPU | 768M / 75% CPU | No hard limits |
| wger-db | 256M / 25% CPU | 512M / 50% CPU | No hard limits |
| wger-redis | 64M / 10% CPU | No limits | No hard limits |
| wger-celery | 256M / 25% CPU | No limits | No hard limits |

## Network Access

### Firewall Configuration

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| SSH | 22 | TCP | Host SSH access |
| HTTP | 80 | TCP | Nginx reverse proxy |
| wger | 8000 | TCP | Django direct access (when no proxy) |
| Node Exporter | 9100 | TCP | Prometheus system metrics |

### DNS Configuration

```bash
# Add to your DNS server or /etc/hosts
10.0.20.107 fitness.homelab.local
```

## Usage

### Initial Setup

After first deployment, wger will run initial database migrations automatically. Create an admin user:

```bash
ssh user@fitness-host
sudo podman exec -it wger python3 manage.py createsuperuser
```

### Mobile App Setup

1. Install the wger Flutter app from the App Store or Google Play
2. In the app settings, set the server URL to `http://fitness.homelab.local`
3. Log in with your admin credentials
4. Use barcode scanning for nutrition tracking

### API Access

```bash
# List exercises
curl http://fitness.homelab.local/api/v2/exercise/

# Get workout sessions
curl -H "Authorization: Token YOUR_TOKEN" http://fitness.homelab.local/api/v2/workoutsession/
```

## Monitoring Integration

### Prometheus Targets

The fitness VM is included in the monitoring configuration:

```nix
# In systemModules/monitoring.nix
"node-exporters" = [
  "10.0.20.107:9100"  # fitness VM (provisional IP)
];
```

wger also exposes a native `/metrics` endpoint when `ENABLE_PROMETHEUS=True`, which can be scraped directly by Prometheus for application-level metrics (request counts, response times, etc.).

## Maintenance

### Backup

```bash
# Backup PostgreSQL data volume
ssh fitness-host "sudo podman volume export wger-postgres-data" > /backup/wger-postgres.tar

# Backup media files (user uploads)
ssh fitness-host "sudo podman volume export wger-media" > /backup/wger-media.tar
```

### Updates

```bash
# Pull latest container images
ssh fitness-host "sudo podman pull wger/server:latest"
ssh fitness-host "sudo podman pull postgres:15-alpine"
ssh fitness-host "sudo podman pull redis:7-alpine"

# Restart the stack
nixos-rebuild switch --target-host user@fitness-host --flake .#fitness --sudo
```

### Database Migrations

wger runs migrations automatically on container start. If manual migration is needed:

```bash
ssh fitness-host "sudo podman exec wger python3 manage.py migrate"
```

## Troubleshooting

### Common Issues

#### wger Not Starting
```bash
# Check container status
ssh fitness-host "sudo podman ps -a --filter name=wger"

# Check container logs
ssh fitness-host "sudo podman logs wger"
ssh fitness-host "sudo podman logs wger-db"
ssh fitness-host "sudo podman logs wger-redis"
```

#### Database Connection Issues
```bash
# Check PostgreSQL container health
ssh fitness-host "sudo podman healthcheck run wger-db"

# Check database connectivity from wger container
ssh fitness-host "sudo podman exec wger python3 -c 'import django; django.setup(); from django.db import connection; connection.ensure_connection(); print(\"DB OK\")'"
```

#### Redis Connection Issues
```bash
# Check Redis container health
ssh fitness-host "sudo podman healthcheck run wger-redis"

# Test Redis connectivity
ssh fitness-host "sudo podman exec wger-redis redis-cli ping"
```

#### Secret Decryption Failed
```bash
# Verify age key
ssh fitness-host "sudo ls -la /var/lib/sops-nix/key.txt"

# Test secret decryption
sops -d secrets/fitness/secrets.yaml

# Check secret files at runtime
ssh fitness-host "sudo ls -la /run/secrets/"
```

### Log Analysis

```bash
# All wger container logs
ssh fitness-host "sudo podman logs --tail 50 wger"
ssh fitness-host "sudo podman logs --tail 50 wger-db"
ssh fitness-host "sudo podman logs --tail 50 wger-redis"
ssh fitness-host "sudo podman logs --tail 50 wger-celery"

# Nginx logs
ssh fitness-host "sudo journalctl -u nginx -f"

# Health check results
ssh fitness-host "sudo journalctl -u wger-health-check"
```

## Integration with Other Services

### Grafana Dashboards

wger exposes Prometheus metrics at `/metrics` which can be visualized in Grafana:
- Request rate and response times
- Active user sessions
- Database query performance
- Celery task queue depth

### Home Assistant Integration

wger weight and body measurement data can be pulled into Home Assistant via the REST API for health dashboards.
