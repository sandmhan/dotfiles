#!/usr/bin/env python3
"""
Homelab Matrix Bot - Autonomous agent control and notification bridge.

Connects to a Matrix homeserver, listens for commands in a control room,
and runs a webhook HTTP server for receiving alerts from Prometheus
Alertmanager and other services.

Configuration is read from environment variables:
  HOMESERVER_URL       - Matrix homeserver URL (default: http://localhost:8008)
  BOT_ACCESS_TOKEN     - Matrix access token (required)
  BOT_USER_ID          - Full Matrix user ID (e.g. @homelab-bot:sandmhan.dev)
  ROOM_AGENT_STATUS    - Room for agent status messages
  ROOM_AGENT_CONTROL   - Room for issuing commands
  ROOM_HOMELAB_ALERTS  - Room for monitoring alerts
  WEBHOOK_ENABLE       - Enable webhook server (default: true)
  WEBHOOK_PORT         - Webhook listen port (default: 9800)
  WEBHOOK_SECRET       - Shared secret for webhook auth
  ALLOWED_USERS        - Comma-separated list of allowed command users
  COMMAND_PREFIX       - Command prefix (default: !)
"""

import asyncio
import json
import logging
import os
import signal
import sys
import time
from datetime import datetime, timezone

import aiohttp
from aiohttp import web
from nio import (
    AsyncClient,
    AsyncClientConfig,
    LoginResponse,
    MatrixRoom,
    RoomMessageText,
    InviteMemberEvent,
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    stream=sys.stdout,
)
logger = logging.getLogger("homelab-bot")

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

def get_config():
    """Build configuration from environment variables."""
    return {
        "homeserver_url": os.environ.get("HOMESERVER_URL", "http://localhost:8008"),
        "access_token": os.environ.get("BOT_ACCESS_TOKEN", ""),
        "bot_user_id": os.environ.get("BOT_USER_ID", "@homelab-bot:sandmhan.dev"),
        "rooms": {
            "agent_status": os.environ.get("ROOM_AGENT_STATUS", "#agent-status:sandmhan.dev"),
            "agent_control": os.environ.get("ROOM_AGENT_CONTROL", "#agent-control:sandmhan.dev"),
            "homelab_alerts": os.environ.get("ROOM_HOMELAB_ALERTS", "#homelab-alerts:sandmhan.dev"),
        },
        "webhook": {
            "enable": os.environ.get("WEBHOOK_ENABLE", "true").lower() == "true",
            "port": int(os.environ.get("WEBHOOK_PORT", "9800")),
            "secret": os.environ.get("WEBHOOK_SECRET", ""),
        },
        "allowed_users": [
            u.strip()
            for u in os.environ.get("ALLOWED_USERS", "@sandmhan:sandmhan.dev").split(",")
            if u.strip()
        ],
        "command_prefix": os.environ.get("COMMAND_PREFIX", "!"),
    }


# ---------------------------------------------------------------------------
# Bot core
# ---------------------------------------------------------------------------

class HomelabBot:
    """Matrix bot for homelab management and notifications."""

    def __init__(self, config: dict):
        self.config = config
        self.start_time = time.monotonic()
        self.room_ids: dict[str, str] = {}  # alias -> room_id
        self.client: AsyncClient | None = None

    # -- lifecycle ----------------------------------------------------------

    async def start(self):
        """Connect to homeserver and start listening."""
        client_config = AsyncClientConfig(
            max_limit_exceeded=0,
            max_timeouts=0,
            store_sync_tokens=True,
        )
        self.client = AsyncClient(
            self.config["homeserver_url"],
            self.config["bot_user_id"],
            config=client_config,
        )
        self.client.access_token = self.config["access_token"]

        # Register callbacks
        self.client.add_event_callback(self._on_message, RoomMessageText)
        self.client.add_event_callback(self._on_invite, InviteMemberEvent)

        # Join configured rooms
        for name, alias in self.config["rooms"].items():
            try:
                resp = await self.client.join(alias)
                if hasattr(resp, "room_id"):
                    self.room_ids[name] = resp.room_id
                    logger.info("Joined room %s (%s)", alias, resp.room_id)
                else:
                    logger.warning("Could not join %s: %s", alias, resp)
            except Exception as exc:
                logger.error("Failed to join %s: %s", alias, exc)

        logger.info("Bot started, syncing...")
        # Do an initial sync to skip old messages
        await self.client.sync(timeout=10000, full_state=True)
        # Now enter the long-poll sync loop
        while True:
            try:
                await self.client.sync(timeout=30000)
            except Exception as exc:
                logger.error("Sync error: %s, retrying in 5s", exc)
                await asyncio.sleep(5)

    async def stop(self):
        """Gracefully disconnect."""
        if self.client:
            await self.client.close()
            logger.info("Bot disconnected")

    # -- message handling ---------------------------------------------------

    async def _on_invite(self, room: MatrixRoom, event: InviteMemberEvent):
        """Auto-accept invites for the bot user."""
        if event.state_key == self.config["bot_user_id"]:
            await self.client.join(room.room_id)
            logger.info("Accepted invite to %s", room.room_id)

    async def _on_message(self, room: MatrixRoom, event: RoomMessageText):
        """Handle incoming messages, dispatch commands."""
        # Ignore own messages
        if event.sender == self.config["bot_user_id"]:
            return

        # Only process commands in the control room
        control_room_id = self.room_ids.get("agent_control")
        if room.room_id != control_room_id:
            return

        prefix = self.config["command_prefix"]
        body = event.body.strip()
        if not body.startswith(prefix):
            return

        # Check authorization
        if event.sender not in self.config["allowed_users"]:
            await self._send(room.room_id, f"Unauthorized: {event.sender}")
            return

        parts = body[len(prefix):].split()
        if not parts:
            return

        cmd = parts[0].lower()
        args = parts[1:]

        handler = {
            "status": self._cmd_status,
            "services": self._cmd_services,
            "deploy": self._cmd_deploy,
            "logs": self._cmd_logs,
            "help": self._cmd_help,
        }.get(cmd)

        if handler:
            await handler(room.room_id, args)
        else:
            await self._send(room.room_id, f"Unknown command: `{cmd}`. Use `{prefix}help` for available commands.")

    # -- commands -----------------------------------------------------------

    async def _cmd_status(self, room_id: str, args: list[str]):
        uptime_s = int(time.monotonic() - self.start_time)
        h, rem = divmod(uptime_s, 3600)
        m, s = divmod(rem, 60)
        rooms_joined = len(self.room_ids)
        msg = (
            f"**Homelab Bot Status**\n"
            f"- Uptime: {h}h {m}m {s}s\n"
            f"- Rooms joined: {rooms_joined}\n"
            f"- Webhook server: {'enabled' if self.config['webhook']['enable'] else 'disabled'}\n"
            f"- Homeserver: `{self.config['homeserver_url']}`"
        )
        await self._send(room_id, msg)

    async def _cmd_services(self, room_id: str, args: list[str]):
        services = {
            "matrix": ("10.0.0.6", 8008, "/_matrix/client/versions"),
            "prometheus": ("10.0.0.10", 9090, "/-/ready"),  # lxc-monitor
            "grafana": ("10.0.0.10", 3000, "/api/health"),  # lxc-monitor
        }
        lines = ["**Homelab Services**\n"]
        for name, (host, port, path) in services.items():
            url = f"http://{host}:{port}{path}"
            try:
                async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=5)) as session:
                    async with session.get(url) as resp:
                        status = "UP" if resp.status == 200 else f"HTTP {resp.status}"
            except Exception:
                status = "DOWN/UNREACHABLE"
            lines.append(f"- **{name}** ({host}:{port}): {status}")
        await self._send(room_id, "\n".join(lines))

    async def _cmd_deploy(self, room_id: str, args: list[str]):
        if not args:
            await self._send(room_id, "Usage: `!deploy <flake-config>`")
            return
        config_name = args[0]
        logger.info("Deploy requested for config: %s", config_name)
        await self._send(
            room_id,
            f"Deploy request logged for `{config_name}`. "
            f"Automated deployment not yet implemented -- manual action required.",
        )

    async def _cmd_logs(self, room_id: str, args: list[str]):
        if not args:
            await self._send(room_id, "Usage: `!logs <service> [--lines N]`")
            return
        service = args[0]
        lines = 20
        if "--lines" in args:
            idx = args.index("--lines")
            if idx + 1 < len(args):
                try:
                    lines = int(args[idx + 1])
                except ValueError:
                    pass
        logger.info("Log request for %s (last %d lines)", service, lines)
        await self._send(
            room_id,
            f"Log retrieval for `{service}` (last {lines} lines) is a placeholder. "
            f"Remote log fetching will be implemented in a future update.",
        )

    async def _cmd_help(self, room_id: str, args: list[str]):
        p = self.config["command_prefix"]
        msg = (
            f"**Available Commands**\n\n"
            f"- `{p}status` -- Bot status and uptime\n"
            f"- `{p}services` -- Check homelab service health\n"
            f"- `{p}deploy <config>` -- Request a deployment (placeholder)\n"
            f"- `{p}logs <service> [--lines N]` -- Fetch service logs (placeholder)\n"
            f"- `{p}help` -- Show this help message"
        )
        await self._send(room_id, msg)

    # -- messaging helpers --------------------------------------------------

    async def _send(self, room_id: str, message: str):
        """Send a markdown message to a room."""
        try:
            await self.client.room_send(
                room_id,
                message_type="m.room.message",
                content={
                    "msgtype": "m.text",
                    "body": message,
                    "format": "org.matrix.custom.html",
                    "formatted_body": self._markdown_to_html(message),
                },
            )
        except Exception as exc:
            logger.error("Failed to send message to %s: %s", room_id, exc)

    async def send_to_room(self, room_name: str, message: str):
        """Send a message to a named room (used by webhook handler)."""
        room_id = self.room_ids.get(room_name)
        if room_id:
            await self._send(room_id, message)
        else:
            logger.warning("Room '%s' not joined, cannot send message", room_name)

    @staticmethod
    def _markdown_to_html(text: str) -> str:
        """Minimal markdown to HTML conversion for Matrix."""
        import re
        html = text
        html = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", html)
        html = re.sub(r"`(.+?)`", r"<code>\1</code>", html)
        html = re.sub(r"^- ", r"&bull; ", html, flags=re.MULTILINE)
        html = html.replace("\n", "<br/>")
        return html


# ---------------------------------------------------------------------------
# Webhook server
# ---------------------------------------------------------------------------

class WebhookServer:
    """HTTP server for receiving webhooks from external services."""

    def __init__(self, bot: HomelabBot, config: dict):
        self.bot = bot
        self.config = config

    async def start(self):
        """Start the aiohttp webhook server."""
        app = web.Application()
        app.router.add_post("/webhook/alertmanager", self.handle_alertmanager)
        app.router.add_post("/webhook/generic", self.handle_generic)
        app.router.add_get("/health", self.handle_health)

        runner = web.AppRunner(app)
        await runner.setup()
        site = web.TCPSite(runner, "0.0.0.0", self.config["port"])
        await site.start()
        logger.info("Webhook server listening on port %d", self.config["port"])

    def _check_auth(self, request: web.Request) -> bool:
        """Validate webhook shared secret."""
        secret = self.config.get("secret", "")
        if not secret:
            return True  # No secret configured, allow all
        auth = request.headers.get("Authorization", "")
        return auth == f"Bearer {secret}"

    async def handle_health(self, request: web.Request) -> web.Response:
        """Health check endpoint."""
        uptime = int(time.monotonic() - self.bot.start_time)
        return web.json_response({"status": "ok", "uptime_seconds": uptime})

    async def handle_alertmanager(self, request: web.Request) -> web.Response:
        """Receive Prometheus Alertmanager webhook payloads."""
        if not self._check_auth(request):
            return web.Response(status=401, text="Unauthorized")

        try:
            data = await request.json()
        except Exception:
            return web.Response(status=400, text="Invalid JSON")

        alerts = data.get("alerts", [])
        if not alerts:
            return web.Response(status=200, text="No alerts")

        for alert in alerts:
            status = alert.get("status", "unknown").upper()
            labels = alert.get("labels", {})
            annotations = alert.get("annotations", {})
            alertname = labels.get("alertname", "Unknown")
            severity = labels.get("severity", "info")
            instance = labels.get("instance", "unknown")
            summary = annotations.get("summary", "No summary")
            description = annotations.get("description", "")

            emoji = {"firing": "FIRING", "resolved": "RESOLVED"}.get(
                alert.get("status", ""), "INFO"
            )

            message = (
                f"**[{emoji}] {alertname}** (severity: {severity})\n"
                f"- Instance: `{instance}`\n"
                f"- Summary: {summary}\n"
            )
            if description:
                message += f"- Description: {description}\n"

            await self.bot.send_to_room("homelab_alerts", message)

        logger.info("Processed %d alertmanager alerts", len(alerts))
        return web.Response(status=200, text="OK")

    async def handle_generic(self, request: web.Request) -> web.Response:
        """Receive generic JSON webhook payloads."""
        if not self._check_auth(request):
            return web.Response(status=401, text="Unauthorized")

        try:
            data = await request.json()
        except Exception:
            return web.Response(status=400, text="Invalid JSON")

        title = data.get("title", "Webhook Notification")
        body = data.get("body", data.get("message", json.dumps(data, indent=2)))
        room = data.get("room", "agent_status")

        message = f"**{title}**\n{body}"
        await self.bot.send_to_room(room, message)

        logger.info("Processed generic webhook: %s", title)
        return web.Response(status=200, text="OK")


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

async def main():
    config = get_config()

    if not config["access_token"]:
        logger.error("BOT_ACCESS_TOKEN is required")
        sys.exit(1)

    bot = HomelabBot(config)

    # Start webhook server if enabled
    if config["webhook"]["enable"]:
        webhook = WebhookServer(bot, config["webhook"])
        await webhook.start()

    # Handle graceful shutdown
    loop = asyncio.get_event_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, lambda: asyncio.create_task(shutdown(bot)))

    try:
        await bot.start()
    except asyncio.CancelledError:
        pass
    finally:
        await bot.stop()


async def shutdown(bot: HomelabBot):
    """Graceful shutdown handler."""
    logger.info("Shutting down...")
    await bot.stop()
    tasks = [t for t in asyncio.all_tasks() if t is not asyncio.current_task()]
    for task in tasks:
        task.cancel()
    await asyncio.gather(*tasks, return_exceptions=True)
    asyncio.get_event_loop().stop()


if __name__ == "__main__":
    asyncio.run(main())
