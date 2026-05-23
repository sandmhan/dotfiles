# TODO: Enable Matrix Synapse Metrics

## Status: Pending verification

## Change Made
- `systemModules/matrix.nix`: `enable_metrics = false` → `enable_metrics = true` (line 149)
- Dry-run build succeeded (`nix build --dry-run .#matrix`)

## Before Deploying — Verify SSH Target User

The flake currently defaults to `username = "sandmhan"` for the matrix VM (via `baseUserSettings`),
but this config predates a major host refactor. The live VM may still have `matrix` as the primary user.

**From your daily driver (Framework), run:**

```bash
# Try sandmhan first
ssh sandmhan@10.0.0.6 "whoami && id"

# If that fails, try matrix
ssh matrix@10.0.0.6 "whoami && id"
```

## Deploy Command

Once the correct user is confirmed:

```bash
# If user is sandmhan:
nixos-rebuild switch --target-host sandmhan@10.0.0.6 --flake .#matrix --sudo

# If user is matrix — also update flake.nix to set username = "matrix" for the matrix config:
nixos-rebuild switch --target-host matrix@10.0.0.6 --flake .#matrix --sudo
```

## What This Enables
- Synapse exposes `/_synapse/metrics` on port 8008
- Prometheus already has a `matrix-synapse` scrape job targeting `10.0.0.6:8008/_synapse/metrics`
- Metrics should start flowing to Grafana immediately after deploy

## Data Safety
- PostgreSQL config is unchanged — no schema or data migration
- Only Synapse restarts briefly (seconds) to pick up new `homeserver.yaml`
- No data loss expected
