{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Domain is needed at evaluation time for nginx vhost attribute names,
  # so it cannot come from SOPS (which only resolves at activation time).
  domain = "sandmhan.dev";
  matrixDomain = "matrix.${domain}";
  turnDomain = "turn.${domain}";

  clientConfig = {
    "m.homeserver".base_url = "https://${matrixDomain}";
    "m.identity_server" = { };
  };
  serverConfig = {
    "m.server" = "${matrixDomain}:443";
  };
  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
in
{
  imports = [ ./sops.nix ];

  # Override default sops file to use matrix-specific secrets
  sops.defaultSopsFile = lib.mkForce ../secrets/matrix/secrets.yaml;

  sops.secrets = {
    turn_secret = {
      owner = "turnserver";
      group = "turnserver";
      mode = "0440";
    };

    acme_email = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    registration_shared_secret = {
      owner = "matrix-synapse";
      group = "matrix-synapse";
      mode = "0440";
    };
  };

  ## ACME Settings
  security.acme = {
    acceptTerms = true;
    # ACME email is not secret-critical; using a concrete value here since
    # security.acme.defaults.email is evaluated at build time.
    # The actual email can be overridden per-host if needed.
    defaults.email = "austinsanders0105@gmail.com";
  };

  services.coturn = {
    enable = true;
    realm = domain;

    use-auth-secret = true;
    static-auth-secret-file = config.sops.secrets.turn_secret.path;

    no-tls = true;
    no-dtls = true;

    listening-ips = [ "0.0.0.0" ];

    listening-port = 3478;
    min-port = 49152;
    max-port = 65535;

    no-cli = true;
    no-tcp-relay = true;
    extraConfig = ''
      user-quota=12
      total-quota=1200
      denied-peer-ip=0.0.0.0-0.255.255.255
      denied-peer-ip=10.0.0.0-10.255.255.255
      denied-peer-ip=100.64.0.0-100.127.255.255
      denied-peer-ip=127.0.0.0-127.255.255.255
      denied-peer-ip=169.254.0.0-169.254.255.255
      denied-peer-ip=172.16.0.0-172.31.255.255
      denied-peer-ip=192.0.0.0-192.0.0.255
      denied-peer-ip=192.0.2.0-192.0.2.255
      denied-peer-ip=192.88.99.0-192.88.99.255
      denied-peer-ip=192.168.0.0-192.168.255.255
      denied-peer-ip=198.18.0.0-198.19.255.255
      denied-peer-ip=198.51.100.0-198.51.100.255
      denied-peer-ip=203.0.113.0-203.0.113.255
      denied-peer-ip=240.0.0.0-255.255.255.255
      allowed-peer-ip=192.168.0.0-192.168.255.255
    '';
  };

  services.matrix-synapse = {
    enable = true;
    settings = {
      server_name = domain;
      public_baseurl = "https://${matrixDomain}";

      turn_uris = [
        "turn:${turnDomain}:3478?transport=udp"
        "turn:${turnDomain}:3478?transport=tcp"
      ];

      # TURN secret loaded from file at runtime
      turn_shared_secret_path = config.sops.secrets.turn_secret.path;
      turn_user_lifetime = "1h";
      turn_allow_guests = true;

      listeners = [
        {
          port = 8008;
          bind_addresses = [ "127.0.0.1" ];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = [
                "client"
                "federation"
              ];
              compress = true;
            }
          ];
        }
      ];

      database = {
        name = "psycopg2";
        allow_unsafe_locale = true;
        args = {
          user = "matrix-synapse";
          database = "matrix-synapse";
          host = "/run/postgresql";
        };
      };

      max_upload_size_mib = 100;
      url_preview_enabled = true;
      enable_registration = false;
      enable_metrics = false;
      registration_shared_secret_path = config.sops.secrets.registration_shared_secret.path;

      trusted_key_servers = [
        {
          server_name = "matrix.org";
        }
      ];
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "matrix-synapse" ];
    ensureUsers = [
      {
        name = "matrix-synapse";
        ensureDBOwnership = true;
      }
    ];
  };

  services.nginx.enable = true;

  services.nginx.virtualHosts.${turnDomain} = {
    enableACME = true;
    forceSSL = true;
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    locations."= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
    locations."= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
  };

  services.nginx.virtualHosts.${matrixDomain} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8008";
      extraConfig = ''
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;
        client_max_body_size 100M;
      '';
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      443
      80
      3478
      5349
    ];
    allowedUDPPorts = [
      3478
      5349
    ];
    allowedUDPPortRanges = [
      {
        from = 49152;
        to = 65535;
      }
    ];
  };

  systemd.services.matrix-synapse = {
    wants = [ "sops-nix.service" ];
    after = [ "sops-nix.service" ];
  };

  systemd.services.coturn = {
    wants = [ "sops-nix.service" ];
    after = [ "sops-nix.service" ];
  };
}
