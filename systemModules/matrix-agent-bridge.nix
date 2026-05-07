# Matrix Agent Bridge Module
# Provides autonomous agent control and homelab notifications via Matrix rooms
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  servicePackages = import ./packages.nix { inherit pkgs lib; };
  cfg = config.homelab.matrixAgentBridge;

  botScript = ./matrix-bot/bot.py;

  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      matrix-nio
      aiohttp
      pyyaml
    ]
  );
in
{
  options.homelab.matrixAgentBridge = {
    enable = mkEnableOption "Matrix agent bridge for homelab control and notifications";

    deploymentType = mkOption {
      type = types.enum [
        "vm"
        "container"
        "hybrid"
      ];
      default = "vm";
      description = "Deployment type - affects resource allocation and feature set";
    };

    resourceProfile = mkOption {
      type = types.enum [
        "minimal"
        "standard"
        "high"
      ];
      default = "standard";
      description = "Resource profile for automatic configuration optimization";
    };

    homeserverUrl = mkOption {
      type = types.str;
      default = "http://localhost:8008";
      description = "Matrix homeserver URL (co-located with Synapse by default)";
    };

    botUsername = mkOption {
      type = types.str;
      default = "homelab-bot";
      description = "Matrix bot username (local part)";
    };

    botDisplayName = mkOption {
      type = types.str;
      default = "Homelab Bot";
      description = "Display name for the bot user in Matrix rooms";
    };

    botUserId = mkOption {
      type = types.str;
      default = "@${cfg.botUsername}:sandmhan.dev";
      description = "Full Matrix user ID for the bot";
    };

    # Room configuration
    rooms = {
      agentStatus = mkOption {
        type = types.str;
        default = "#agent-status:sandmhan.dev";
        description = "Room for agent progress and build notifications";
      };

      agentControl = mkOption {
        type = types.str;
        default = "#agent-control:sandmhan.dev";
        description = "Room for issuing commands to agents";
      };

      homelabAlerts = mkOption {
        type = types.str;
        default = "#homelab-alerts:sandmhan.dev";
        description = "Room for monitoring alerts from Prometheus/Alertmanager";
      };
    };

    # Webhook configuration
    webhook = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable HTTP webhook receiver for external services";
      };

      port = mkOption {
        type = types.port;
        default = 9800;
        description = "Webhook HTTP server listen port";
      };

      allowedSources = mkOption {
        type = types.listOf types.str;
        default = [
          "10.0.0.0/24" # TODO: Restrict to services VLAN (10.0.20.0/24) once VLANs are deployed
          "127.0.0.1/32"
        ];
        description = "IP ranges allowed to post webhooks";
      };
    };

    # Alertmanager integration
    alertmanager = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Receive Prometheus Alertmanager webhook notifications";
      };

      webhookPath = mkOption {
        type = types.str;
        default = "/webhook/alertmanager";
        description = "HTTP path for Alertmanager webhook receiver";
      };
    };

    # Agent control features
    agentControl = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Allow bot to manage agents via Matrix commands";
      };

      allowedUsers = mkOption {
        type = types.listOf types.str;
        default = [ "@sandmhan:sandmhan.dev" ];
        description = "Matrix users allowed to issue bot commands";
      };

      commandPrefix = mkOption {
        type = types.str;
        default = "!";
        description = "Prefix character for bot commands";
      };
    };
  };

  config = mkMerge [
    # Core bot service configuration
    (mkIf cfg.enable {
      # SOPS secrets for bot credentials
      # These keys must exist in secrets/matrix/secrets.yaml
      sops.secrets = {
        "bot-access-token" = {
          owner = "matrix-bot";
          group = "matrix-bot";
          mode = "0400";
        };
        "webhook-secret" = {
          owner = "matrix-bot";
          group = "matrix-bot";
          mode = "0400";
        };
      };

      # Create bot system user
      users.users.matrix-bot = {
        isSystemUser = true;
        group = "matrix-bot";
        home = "/var/lib/matrix-bot";
        createHome = true;
        description = "Matrix homelab bot service user";
      };

      users.groups.matrix-bot = { };

      # Main bot systemd service
      systemd.services.matrix-bot = {
        description = "Homelab Matrix Bot - Agent Control & Notifications";
        wantedBy = [ "multi-user.target" ];
        wants = [
          "network-online.target"
          "sops-nix.service"
        ];
        after = [
          "network-online.target"
          "sops-nix.service"
          "matrix-synapse.service"
        ];

        environment = {
          HOMESERVER_URL = cfg.homeserverUrl;
          BOT_USER_ID = cfg.botUserId;
          ROOM_AGENT_STATUS = cfg.rooms.agentStatus;
          ROOM_AGENT_CONTROL = cfg.rooms.agentControl;
          ROOM_HOMELAB_ALERTS = cfg.rooms.homelabAlerts;
          WEBHOOK_ENABLE = if cfg.webhook.enable then "true" else "false";
          WEBHOOK_PORT = toString cfg.webhook.port;
          ALLOWED_USERS = concatStringsSep "," cfg.agentControl.allowedUsers;
          COMMAND_PREFIX = cfg.agentControl.commandPrefix;
        };

        serviceConfig = {
          Type = "simple";
          User = "matrix-bot";
          Group = "matrix-bot";
          WorkingDirectory = "/var/lib/matrix-bot";

          # Security hardening
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          ReadWritePaths = [ "/var/lib/matrix-bot" ];

          # Restart policy with backoff
          Restart = "on-failure";
          RestartSec = "10s";
          RestartMaxDelaySec = "5min";
          StartLimitIntervalSec = "300";
          StartLimitBurst = 5;
        };

        # Wrapper script to load secrets as env vars and exec the bot
        script = ''
          export BOT_ACCESS_TOKEN=$(cat ${config.sops.secrets."bot-access-token".path})
          export WEBHOOK_SECRET=$(cat ${config.sops.secrets."webhook-secret".path})
          exec ${pythonEnv}/bin/python3 ${botScript}
        '';
      };

      # Working directory
      systemd.tmpfiles.rules = [
        "d /var/lib/matrix-bot 0750 matrix-bot matrix-bot -"
      ];

      # Install bot packages from centralized registry
      environment.systemPackages = [ pythonEnv ] ++ servicePackages.base;
    })

    # Webhook firewall rules
    (mkIf (cfg.enable && cfg.webhook.enable) {
      networking.firewall.allowedTCPPorts = [ cfg.webhook.port ];
    })

    # Health check timer
    (mkIf cfg.enable {
      systemd.services.matrix-bot-health = {
        description = "Matrix Bot Health Check";

        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "matrix-bot-health" ''
            # Check bot systemd service is active
            if systemctl is-active --quiet matrix-bot.service; then
              echo "matrix-bot service: active"
            else
              echo "matrix-bot service: INACTIVE"
              exit 1
            fi

            # Check webhook endpoint if enabled
            ${optionalString cfg.webhook.enable ''
              if ${pkgs.curl}/bin/curl -sf http://localhost:${toString cfg.webhook.port}/health >/dev/null 2>&1; then
                echo "webhook server: healthy"
              else
                echo "webhook server: UNREACHABLE"
                exit 1
              fi
            ''}

            echo "Health check passed"
          '';
        };
      };

      systemd.timers.matrix-bot-health = {
        description = "Periodic health check for Matrix Bot";
        wantedBy = [ "timers.target" ];

        timerConfig = {
          OnCalendar = "*:0/15"; # Every 15 minutes
          Persistent = true;
          RandomizedDelaySec = "60";
        };
      };
    })
  ];
}
