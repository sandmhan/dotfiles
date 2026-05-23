# Matrix Agent Bridge Setup

## Architecture Overview

The Matrix Agent Bridge runs as a Python systemd service (`matrix-bot.service`) alongside Synapse on the matrix host (10.0.0.6). It provides two capabilities:

1. **Bot command interface** -- listens in the `#agent-control:sandmhan.dev` room for commands from authorized users
2. **Webhook HTTP server** -- receives POST requests on port 9800 from Prometheus Alertmanager and other services, forwarding them as formatted messages to Matrix rooms

```
                    +-------------------+
                    |   Matrix Host     |
                    |   10.0.0.6        |
                    |                   |
  Matrix clients -->|  Synapse (:8008)  |
                    |                   |
  Alertmanager ---->|  Bot Webhook      |
  CI/CD webhooks -->|  (:9800)          |
                    |                   |
                    |  matrix-bot.service|
                    |  (Python/nio)     |
                    +-------------------+
```

### Rooms

| Room | Alias | Purpose |
|------|-------|---------|
| Agent Status | `#agent-status:sandmhan.dev` | Build progress, deployment notifications |
| Agent Control | `#agent-control:sandmhan.dev` | Issue commands to the bot |
| Homelab Alerts | `#homelab-alerts:sandmhan.dev` | Prometheus/Alertmanager notifications |

---

## Creating the Bot User Account

Register the bot user on Synapse using the admin API or `register_new_matrix_user`:

```bash
# SSH to the matrix host
ssh sandmhan@10.0.0.6

# Register the bot user (requires the registration shared secret)
sudo register_new_matrix_user -u homelab-bot -p '<password>' --no-admin \
  -c /var/lib/matrix-synapse/homeserver.yaml http://localhost:8008
```

---

## Generating and Encrypting the Access Token

1. **Get an access token** by logging in as the bot:

```bash
curl -X POST http://localhost:8008/_matrix/client/r0/login \
  -H 'Content-Type: application/json' \
  -d '{
    "type": "m.login.password",
    "user": "homelab-bot",
    "password": "<password>"
  }'
```

The response contains `"access_token": "syt_..."`. Save this value.

2. **Add secrets to SOPS**:

```bash
# Edit the matrix secrets file
sops secrets/matrix/secrets.yaml
```

Add these keys:

```yaml
bot-access-token: syt_<actual_token>
webhook-secret: <generate with: openssl rand -base64 32>
```

3. **Verify decryption**:

```bash
sops -d secrets/matrix/secrets.yaml | grep bot-access-token
```

---

## Room Creation and Configuration

Create the rooms manually via a Matrix client (Element) or via the admin API:

```bash
# Create rooms (run as your admin user)
# Using Element: Create room -> set alias -> invite @homelab-bot:sandmhan.dev

# Or via API with your admin access token:
for room in agent-status agent-control homelab-alerts; do
  curl -X POST "http://localhost:8008/_matrix/client/r0/createRoom" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"room_alias_name\": \"$room\",
      \"name\": \"$room\",
      \"visibility\": \"private\",
      \"invite\": [\"@homelab-bot:sandmhan.dev\"]
    }"
done
```

---

## Enabling the Module

The module is imported in `flake.nix` for the `matrix` nixosConfiguration. Enable it in the matrix host config or directly in `flake.nix` specialArgs:

```nix
# In the matrix host configuration or an overlay:
homelab.matrixAgentBridge = {
  enable = true;
  # All defaults are suitable for co-located deployment
  # Override only if needed:
  # webhook.port = 9800;
  # agentControl.allowedUsers = [ "@sandmhan:sandmhan.dev" ];
};
```

Deploy:

```bash
nixos-rebuild switch --target-host sandmhan@10.0.0.6 --flake .#matrix --sudo
```

---

## Alertmanager Integration

Configure Prometheus Alertmanager to send webhooks to the bot:

```yaml
# In alertmanager.yml or the NixOS alertmanager config:
receivers:
  - name: matrix
    webhook_configs:
      - url: "http://10.0.0.6:9800/webhook/alertmanager"
        http_config:
          authorization:
            type: Bearer
            credentials: "<webhook-secret>"

route:
  receiver: matrix
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
```

---

## Available Commands

All commands are issued in the `#agent-control:sandmhan.dev` room with the `!` prefix:

| Command | Description |
|---------|-------------|
| `!status` | Report bot uptime and connection status |
| `!services` | Check health of known homelab services |
| `!deploy <config>` | Request a deployment (logs request, placeholder) |
| `!logs <service> [--lines N]` | Fetch service logs (placeholder) |
| `!help` | List available commands |

Only users listed in `agentControl.allowedUsers` can issue commands (default: `@sandmhan:sandmhan.dev`).

---

## Webhook API

### POST /webhook/alertmanager

Receives Prometheus Alertmanager webhook payloads and forwards formatted alerts to `#homelab-alerts:sandmhan.dev`.

**Headers:**
- `Authorization: Bearer <webhook-secret>`
- `Content-Type: application/json`

**Body:** Standard Alertmanager webhook JSON payload.

### POST /webhook/generic

Receives generic JSON messages and forwards them to a specified room.

**Headers:**
- `Authorization: Bearer <webhook-secret>`
- `Content-Type: application/json`

**Body:**
```json
{
  "title": "Build Complete",
  "body": "NixOS configuration built successfully for host monitor",
  "room": "agent_status"
}
```

`room` values: `agent_status`, `agent_control`, `homelab_alerts`

### GET /health

Returns JSON health status. No authentication required.

```json
{"status": "ok", "uptime_seconds": 3600}
```

---

## Troubleshooting

### Bot won't start

```bash
# Check service status and logs
sudo systemctl status matrix-bot
sudo journalctl -u matrix-bot -f

# Common causes:
# - Missing or invalid access token in SOPS
# - Synapse not running yet (bot waits for it but check ordering)
# - Python dependency issues
```

### Bot can't join rooms

- Verify rooms exist and the bot user has been invited
- Check that room aliases match the configured values
- The bot auto-accepts invites, so invite it from your admin account

### Webhook not receiving alerts

```bash
# Test webhook endpoint
curl -X POST http://localhost:9800/webhook/generic \
  -H "Authorization: Bearer $(sudo cat /run/secrets/webhook-secret)" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","body":"Hello from curl"}'

# Check firewall
sudo iptables -L -n | grep 9800
```

### Health check failures

```bash
# Run health check manually
sudo systemctl start matrix-bot-health
sudo journalctl -u matrix-bot-health --since "1 minute ago"
```

### Secrets not available

```bash
# Verify SOPS decryption
sudo ls -la /run/secrets/
sudo cat /run/secrets/bot-access-token  # Should show the token

# Re-run SOPS
sudo systemctl restart sops-nix
```
