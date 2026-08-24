{
  lib,
  pkgs,
  ...
}:
let
  glassLanRouteStart = pkgs.writeShellScript "glass-lan-route-start" ''
    set -eu

    ${pkgs.iproute2}/bin/ip rule del \
      priority 5260 \
      to 10.0.0.12/32 \
      table main 2>/dev/null || true

    ${pkgs.iproute2}/bin/ip rule add \
      priority 5260 \
      to 10.0.0.12/32 \
      table main
  '';

  glassLanRouteStop = pkgs.writeShellScript "glass-lan-route-stop" ''
    ${pkgs.iproute2}/bin/ip rule del \
      priority 5260 \
      to 10.0.0.12/32 \
      table main 2>/dev/null || true
  '';
in
{
  environment.systemPackages = with pkgs; [
    openssl
    wayvnc
  ];

  systemd.services.glass-lan-route = {
    description = "Prefer the physical LAN route for Google Glass";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "tailscaled.service"
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = glassLanRouteStart;
      ExecStop = glassLanRouteStop;
    };
  };

  networking.firewall = {
    # Prefer strict reverse-path filtering. Tailscale clients may lower this to
    # loose mode for policy routing; the /32 rule above still keeps Glass local.
    checkReversePath = lib.mkDefault true;

    # Drop Tailscale traffic in raw PREROUTING, before Tailscale's ts-input
    # chain can accept its trusted interface. Keep this idempotent on reload.
    extraCommands = lib.mkAfter ''
      iptables -t raw -D PREROUTING \
        -i tailscale0 \
        -p tcp \
        -d 10.0.0.3/32 \
        --dport 35900 \
        -j DROP 2>/dev/null || true

      iptables -t raw -I PREROUTING 1 \
        -i tailscale0 \
        -p tcp \
        -d 10.0.0.3/32 \
        --dport 35900 \
        -j DROP

      iptables -A nixos-fw \
        -i wlp192s0 \
        -p tcp \
        -s 10.0.0.12/32 \
        -d 10.0.0.3/32 \
        --dport 35900 \
        -m conntrack --ctstate NEW \
        -j nixos-fw-accept
    '';

    extraStopCommands = lib.mkAfter ''
      iptables -t raw -D PREROUTING \
        -i tailscale0 \
        -p tcp \
        -d 10.0.0.3/32 \
        --dport 35900 \
        -j DROP 2>/dev/null || true
    '';
  };
}
