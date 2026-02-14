{
  config,
  pkgs,
  lib,
  ...
}: let
  domain = "sandmhan.dev";
  matrixDomain = "matrix.${domain}";
  turnDomain = "turn.${domain}";

  # Shared secret for turn auth

  turnSecret = "759134cd691080e35d8ef879c387e09e8ad720cccd9e72706a1ff54fcc114423";

  clientConfig = {
    "m.homeserver".base_url = "https://${matrixDomain}";
    "m.identity_server" = {};
  };
  serverConfig = {
    "m.server" = "${matrixDomain}:443";
  };
  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
in {

  ## ACME Settings
  security.acme = {
    acceptTerms = true;
    defaults.email = "austinsanders0105@gmail.com";
  };

  services.coturn = {
    enable = true;
    realm = domain;

    use-auth-secret = true;
    static-auth-secret = turnSecret;

    no-tls = true;
    no-dtls = true;
    # TLS Certificate
    # cert = "/var/lib/acme/${turnDomain}/fullchain.pem";
    # pkey = "/var/lib/acme/${turnDomain}/key.pem";

    # Networking

    listening-ips = [ "0.0.0.0"];

    # Ports
    listening-port = 3478;
    # tls-listening-port = 5349;
    min-port = 49152;
    max-port = 65535;

    # Security
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


  # Matrix setup
  services.matrix-synapse = {
    enable = true;
    settings = {
      server_name = domain;
      public_baseurl = "https://${matrixDomain}";

      turn_uris = [
        "turn:${turnDomain}:3478?transport=udp"
        "turn:${turnDomain}:3478?transport=tcp"
        # "turns:${turnDomain}:5349?transport=udp"
        # "turns:${turnDomain}:5349?transport=tcp"
      ];

      turn_shared_secret = turnSecret;
      turn_user_lifetime = "1h";
      turn_allow_guests = true;

      listeners = [
        {
          port = 8008;
          bind_addresses = ["127.0.0.1"];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = ["client" "federation"];
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
      registration_shared_secret_path = "/var/lib/matrix-synapse/registration_secret";

      trusted_key_servers = [
        {
          server_name = "matrix.org";
        }
      ];
    };
  };

  # PostgreSQL setup
  services.postgresql = {
    enable = true;
    ensureDatabases = ["matrix-synapse"];
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
    allowedTCPPorts = [443 80 3478 5349];
    allowedUDPPorts = [3478 5349];
    allowedUDPPortRanges = [
      { from = 49152; to = 65535; }
    ];

  };
}
