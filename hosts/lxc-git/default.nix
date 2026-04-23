# Git Server (Forgejo) LXC Container Configuration
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
  ];

  # Container-specific hostname
  networking.hostName = "lxc-git";

  # Git server firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22    # SSH management
      80    # HTTP (redirects to HTTPS)
      443   # HTTPS (Forgejo web)
      3022  # Git SSH access
      9100  # Prometheus metrics
      9187  # PostgreSQL exporter
    ];
  };

  # PostgreSQL for Forgejo
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "forgejo" ];
    ensureUsers = [
      {
        name = "forgejo";
        ensureDBOwnership = true;
      }
    ];

    # Container-optimized settings
    settings = {
      shared_buffers = "64MB";
      effective_cache_size = "256MB";
      maintenance_work_mem = "32MB";
      work_mem = "4MB";
    };
  };

  # Forgejo git server
  services.forgejo = {
    enable = true;
    database = {
      type = "postgres";
      host = "/run/postgresql";
      name = "forgejo";
      user = "forgejo";
    };

    settings = {
      server = {
        DOMAIN = "git.homelab.local";
        ROOT_URL = "https://git.homelab.local/";
        HTTP_PORT = 3000;
        SSH_PORT = 3022;
        DISABLE_SSH = false;
        START_SSH_SERVER = true;
        LFS_START_SERVER = true;
      };

      service = {
        REGISTER_EMAIL_CONFIRM = false;
        ENABLE_NOTIFY_MAIL = false;
        DISABLE_REGISTRATION = true; # Homelab only
      };

      # Container optimizations
      cache = {
        ENABLED = true;
        ADAPTER = "memory";
      };

      session = {
        PROVIDER = "memory";
      };
    };
  };

  # Nginx reverse proxy for HTTPS
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    virtualHosts."git.homelab.local" = {
      forceSSL = false; # Use self-signed for homelab
      locations."/" = {
        proxyPass = "http://localhost:3000";
        proxyWebsockets = true;
      };
    };
  };

  # PostgreSQL metrics exporter
  services.prometheus.exporters.postgres = {
    enable = true;
    port = 9187;
    dataSourceName = "postgresql:///forgejo?host=/run/postgresql&user=forgejo";
  };

  # Container resource optimization
  systemd.services = {
    forgejo.serviceConfig = {
      MemoryMax = "512M";
      CPUQuota = "50%";
    };

    postgresql.serviceConfig = {
      MemoryMax = "256M";
      CPUQuota = "25%";
    };

    nginx.serviceConfig = {
      MemoryMax = "64M";
      CPUQuota = "10%";
    };
  };
}