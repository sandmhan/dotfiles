# Matrix Homeserver LXC Container Configuration
# Lightweight Matrix deployment optimized for resource efficiency
{
  config,
  lib,
  pkgs,
  userSettings,
  systemSettings,
  ...
}:
{
  imports = [
    ../lxc-base
    ../../systemModules/matrix.nix
  ];

  # Container-specific hostname
  networking.hostName = "lxc-matrix";

  # Matrix-specific firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22    # SSH management
      80    # HTTP (ACME challenge)
      443   # HTTPS (Matrix)
      8448  # Matrix federation
      3478  # Coturn STUN/TURN
      5349  # Coturn STUNS/TURNS
      9100  # Prometheus metrics
    ];

    # Allow Coturn UDP port range
    allowedUDPPortRanges = [
      { from = 49152; to = 65535; } # Coturn ephemeral ports
    ];
  };

  # Container resource optimizations for Matrix
  systemd.services = {
    # Optimize PostgreSQL for container environment
    postgresql.serviceConfig = {
      # Limit memory usage in container
      MemoryMax = "1G";
      CPUQuota = "50%";
    };

    # Optimize Matrix Synapse for container
    matrix-synapse.serviceConfig = {
      MemoryMax = "1.5G";
      CPUQuota = "75%";
    };
  };

  # Container-optimized Matrix configuration
  services.matrix-synapse.settings = {
    # Reduce resource usage
    database = {
      # Use smaller connection pools in containers
      args.cp_max = 5;
      args.cp_min = 1;
    };

    # Optimize caching for containers
    caches = {
      global_factor = 0.5; # Reduce cache size for containers
    };

    # Container-friendly logging
    log_config = pkgs.writeText "log_config.yaml" ''
      version: 1
      formatters:
        precise:
          format: '%(asctime)s - %(name)s - %(lineno)d - %(levelname)s - %(message)s'
      handlers:
        console:
          class: logging.StreamHandler
          formatter: precise
          stream: ext://sys.stdout
      root:
        level: INFO
        handlers: [console]
    '';
  };

  # Prometheus monitoring specific to Matrix
  services.prometheus.exporters = {
    # Matrix Synapse metrics
    postgres = {
      enable = true;
      port = 9187;
      dataSourceName = "postgresql:///matrix-synapse?host=/run/postgresql&user=matrix-synapse";
    };
  };

  # Add Matrix monitoring ports
  networking.firewall.allowedTCPPorts = [ 9187 ]; # PostgreSQL exporter

  # Container health checks
  systemd.services.matrix-health-check = {
    description = "Matrix Container Health Check";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "matrix-health" ''
        #!/bin/bash
        # Check if Matrix API is responding
        curl -f -s http://localhost:8008/_matrix/client/versions >/dev/null || {
          echo "Matrix API not responding"
          exit 1
        }

        # Check PostgreSQL connection
        ${pkgs.postgresql}/bin/psql -h /run/postgresql -U matrix-synapse -d matrix-synapse -c "SELECT 1;" >/dev/null || {
          echo "PostgreSQL connection failed"
          exit 1
        }

        echo "Matrix container healthy"
      '';
      User = "matrix-synapse";
    };
    # Check every 2 minutes
    startAt = "*:0/2";
  };

  # Storage optimization for containers
  services.postgresql = {
    settings = {
      # Container-optimized PostgreSQL settings
      shared_buffers = "128MB";
      effective_cache_size = "512MB";
      maintenance_work_mem = "64MB";
      work_mem = "8MB";

      # Reduce checkpoint frequency for containers
      checkpoint_completion_target = "0.9";
      wal_buffers = "16MB";
    };
  };
}