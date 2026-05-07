# Manga Stack Monitoring Integration
# Provides node exporter, Prometheus scrape readiness, and journald log forwarding
# for Komga and Suwayomi containers.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.homelab.manga;
in
{
  config = mkIf (cfg.enable && cfg.monitoring.enable) {
    # Node exporter for system-level metrics
    services.prometheus.exporters.node = {
      enable = true;
      port = 9100;
      enabledCollectors =
        [
          "systemd"
          "processes"
        ]
        ++ optionals (cfg.deploymentType == "vm") [
          "interrupts"
          "logind"
          "tcpstat"
        ];
    };

    # Promtail for shipping container logs to Loki
    # Collects journald logs from podman-komga and podman-suwayomi units
    services.promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 9080;
          grpc_listen_port = 0;
        };

        positions = {
          filename = "/var/lib/promtail/positions.yaml";
        };

        clients = [
          {
            # Loki endpoint on the monitoring VM — update IP when deployed
            # TODO: Set to actual monitoring VM IP after deployment (lxc-monitor is 10.0.0.10)
            url = "http://10.0.0.10:3100/loki/api/v1/push";
          }
        ];

        scrape_configs = [
          {
            job_name = "manga-journal";
            journal = {
              json = false;
              max_age = "12h";
              labels = {
                job = "manga-systemd";
                host = config.networking.hostName;
              };
            };
            relabel_configs = [
              {
                source_labels = [ "__journal__systemd_unit" ];
                regex = "(podman-komga|podman-suwayomi|podman-flaresolverr|manga-network|manga-health-check)\\.service";
                action = "keep";
              }
              {
                source_labels = [ "__journal__systemd_unit" ];
                target_label = "unit";
              }
            ];
          }
        ];
      };
    };

    # Persistent directory for promtail positions
    systemd.tmpfiles.rules = [
      "d /var/lib/promtail 0755 promtail promtail -"
    ];

    # Firewall: node exporter + promtail
    networking.firewall.allowedTCPPorts = [
      9100 # node exporter
      9080 # promtail (for debugging/status only)
    ];
  };
}
