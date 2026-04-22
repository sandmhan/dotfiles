{ config, lib, pkgs, ... }:

let
  cfg = config.services.llama-cpp;
in
{
  options.services.llama-cpp = {
    enable = lib.mkEnableOption "llama.cpp inference server";

    package = lib.mkPackageOption pkgs "llama-cpp" { };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host to bind the server to";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port to listen on";
    };

    models = {
      modelsPath = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/llama-cpp/models";
        description = "Path to store model files";
      };

      defaultModel = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Default model to load on startup";
        example = "llama-2-7b-chat.gguf";
      };
    };

    acceleration = lib.mkOption {
      type = lib.types.enum [ "cpu" "cuda" "opencl" "metal" ];
      default = "cpu";
      description = "Hardware acceleration backend";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional command line arguments";
      example = [ "--ctx-size" "4096" "--threads" "8" ];
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Environment file containing additional configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create the models directory
    systemd.tmpfiles.rules = [
      "d '${cfg.models.modelsPath}' 0755 llama-cpp llama-cpp - -"
    ];

    # Create system user
    users.users.llama-cpp = {
      isSystemUser = true;
      group = "llama-cpp";
      home = "/var/lib/llama-cpp";
      createHome = true;
      description = "llama.cpp inference server user";
    };

    users.groups.llama-cpp = { };

    # Systemd service
    systemd.services.llama-cpp = {
      description = "llama.cpp inference server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "exec";
        User = "llama-cpp";
        Group = "llama-cpp";
        WorkingDirectory = "/var/lib/llama-cpp";
        StateDirectory = "llama-cpp";
        StateDirectoryMode = "0755";

        # Security settings
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/var/lib/llama-cpp" ];

        # Resource limits
        LimitNOFILE = 65536;
        MemoryHigh = "6G";  # Soft limit
        MemoryMax = "7G";   # Hard limit for 8GB system

        # Restart policy
        Restart = "always";
        RestartSec = 10;

        # Environment
        EnvironmentFile = lib.optionalString (cfg.environmentFile != null) cfg.environmentFile;

        ExecStart = let
          modelArg = lib.optionalString (cfg.models.defaultModel != null)
            "--model ${cfg.models.modelsPath}/${cfg.models.defaultModel}";

          accelerationArgs = {
            cuda = [ "--n-gpu-layers" "999" ];
            opencl = [ "--opencl" ];
            metal = [ "--metal" ];
            cpu = [ ];
          }.${cfg.acceleration};

          allArgs = [
            "--host" cfg.host
            "--port" (toString cfg.port)
            "--models-path" cfg.models.modelsPath
          ] ++ lib.optional (cfg.models.defaultModel != null) modelArg
            ++ accelerationArgs
            ++ cfg.extraArgs;
        in
        "${cfg.package}/bin/llama-server ${lib.escapeShellArgs allArgs}";
      };

      # GPU access for CUDA
      environment = lib.mkIf (cfg.acceleration == "cuda") {
        CUDA_VISIBLE_DEVICES = "0";
      };
    };

    # Firewall
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    # Log rotation
    services.logrotate.settings.llama-cpp = {
      files = "/var/log/llama-cpp/*.log";
      rotate = 7;
      daily = true;
      compress = true;
      delaycompress = true;
      missingok = true;
      notifempty = true;
      create = "644 llama-cpp llama-cpp";
    };
  };
}