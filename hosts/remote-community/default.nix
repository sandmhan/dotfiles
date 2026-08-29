# Remote Community VM Host Configuration
# Observe-only remote-community Android lab on Proxmox VM111.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  gaiaActuatorKnownHosts = pkgs.writeText "gaia-actuator-known-hosts" ''
    gaia-actuator ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIcLYq9fnYqD/7x0u6ULnlXWK0++ZIdTF80AAZe6Aqyo
  '';
  gaiaSshActuator = pkgs.writeShellScriptBin "remote-community-gaia-actuator" ''
    set -eu

    if [ "$#" -ne 1 ]; then
      exit 2
    fi
    case "$1" in
      'Back Gate Controller') token=back_gate ;;
      'Main Entrance') token=main_entrance ;;
      *) exit 2 ;;
    esac

    key="''${CREDENTIALS_DIRECTORY:?}/gaia-actuator-ssh-key"
    test -r "$key"

    exec ${pkgs.coreutils}/bin/timeout --kill-after=5s 85s \
      ${pkgs.openssh}/bin/ssh \
      -F /dev/null \
      -o BatchMode=yes \
      -o ConnectionAttempts=1 \
      -o ConnectTimeout=5 \
      -o ServerAliveInterval=5 \
      -o ServerAliveCountMax=1 \
      -o IdentitiesOnly=yes \
      -o IdentityAgent=none \
      -o PreferredAuthentications=publickey \
      -o PasswordAuthentication=no \
      -o KbdInteractiveAuthentication=no \
      -o GSSAPIAuthentication=no \
      -o StrictHostKeyChecking=yes \
      -o UserKnownHostsFile=${gaiaActuatorKnownHosts} \
      -o GlobalKnownHostsFile=/dev/null \
      -o HostKeyAlias=gaia-actuator \
      -o HostKeyAlgorithms=ssh-ed25519 \
      -o ControlMaster=no \
      -o ControlPersist=no \
      -o ClearAllForwardings=yes \
      -o ForwardAgent=no \
      -o ForwardX11=no \
      -o RequestTTY=no \
      -o PermitLocalCommand=no \
      -i "$key" \
      sandmhan@100.82.221.90 \
      "$token"
  '';
in
{
  imports = [
    ../server/default.nix
    ../server/hardware-configuration.nix
    ../../systemModules/sops.nix
  ];

  # System identification is also set by hosts/server/networking.nix through
  # systemSettings.hostname; keep it explicit for host-local readability.
  networking.hostName = "remote-community";

  # VM111 is provisioned with CPU type=host and nested KVM so the Android
  # emulator can use /dev/kvm. QEMU guest support is inherited from the shared
  # Proxmox VM base.
  boot.kernelModules = [ "kvm-intel" ];

  sops.secrets.remote-community-policy = {
    key = "policy";
    mode = "0400";
  };
  sops.secrets.gaia-actuator-ssh-key = {
    key = "gaia-actuator-ssh-key";
    mode = "0400";
  };

  # The supervised one-gate transport canary completed successfully. Keep the
  # constrained SSH adapter installed as the Rust trusted-command handoff.
  environment.systemPackages = [ gaiaSshActuator ];

  services = {
    # The authenticated AVD has been migrated and verified to boot, but the
    # emulator remains manual-start pending final UI and resource verification.
    remote-community-android-emulator = {
      enable = true;
      # The Dell node cannot keep API 35 system_server responsive while Matrix
      # retains its required headroom. Keep the lab installed but manual-start.
      enableAtBoot = false;
    };

    # Ingestion and the constrained trusted-command handoff stay on loopback.
    # Tailscale Serve is the only planned phone-facing proxy; never expose the
    # plaintext port directly.
    remote-community = {
      enable = true;
      listenAddress = "127.0.0.1";
      policyCredentialFile = config.sops.secrets.remote-community-policy.path;
      actuatorCommand = lib.mkForce "${gaiaSshActuator}/bin/remote-community-gaia-actuator";
      actuatorAdbSocket = null;
      actuatorAndroidSerial = null;
      actuatorSupplementaryGroups = [ ];
      openFirewall = false;
    };

    # This node is neither a subnet router nor an exit node; it exists only to
    # terminate end-to-end tailnet traffic.
    tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "client";
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 443 ];

  # The nested Android emulator runs inside a ballooned 4 GiB guest. A local
  # swap file prevents cold-boot package optimization from exhausting memory.
  swapDevices = [
    {
      device = "/swapfile";
      size = 4096;
    }
  ];

  systemd.services.remote-community.serviceConfig.LoadCredential = lib.mkAfter [
    "gaia-actuator-ssh-key:${config.sops.secrets.gaia-actuator-ssh-key.path}"
  ];

  systemd.services.remote-community-tailscale-serve = {
    description = "Publish remote-community through tailnet-only HTTPS";
    # Keep phone ingestion paused while the Gaia transport is installed and
    # negatively tested. Start this unit manually for the supervised MVP run.
    wantedBy = lib.mkForce [ ];
    after = [
      "network-online.target"
      "remote-community.service"
      "tailscaled.service"
    ];
    wants = [ "network-online.target" ];
    requires = [
      "remote-community.service"
      "tailscaled.service"
    ];

    script = ''
      for _ in $(${pkgs.coreutils}/bin/seq 1 60); do
        backend="$(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null \
          | ${pkgs.jq}/bin/jq -r .BackendState 2>/dev/null || true)"
        if [ "$backend" = Running ]; then
          ${pkgs.tailscale}/bin/tailscale serve reset
          exec ${pkgs.tailscale}/bin/tailscale serve --bg --yes --https=443 \
            http://127.0.0.1:${toString config.services.remote-community.port}
        fi
        ${pkgs.coreutils}/bin/sleep 2
      done
      echo "Tailscale did not reach Running state" >&2
      exit 1
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.tailscale}/bin/tailscale serve reset";
      Restart = "on-failure";
      RestartSec = "10s";
      TimeoutStartSec = "150s";
      UMask = "0077";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      RestrictAddressFamilies = [ "AF_UNIX" ];
      LockPersonality = true;
      SystemCallArchitectures = "native";
      CapabilityBoundingSet = "";
      AmbientCapabilities = "";
    };

    unitConfig = {
      StartLimitIntervalSec = 300;
      StartLimitBurst = 5;
    };
  };

  assertions = [
    {
      assertion =
        config.services.remote-community.enable
        && config.services.remote-community.listenAddress == "127.0.0.1"
        && !config.services.remote-community.openFirewall;
      message = "remote-community must remain observe-only on loopback behind Tailscale Serve.";
    }
    {
      assertion =
        config.services.remote-community-android-emulator.enable
        && !config.services.remote-community-android-emulator.enableAtBoot;
      message = "remote-community Android emulator must remain installed but manual-start on the constrained Dell node.";
    }
    {
      assertion =
        config.networking.firewall.allowedTCPPorts == [ 22 ]
        && config.networking.firewall.allowedUDPPorts == [ config.services.tailscale.port ]
        && config.networking.firewall.allowedTCPPortRanges == [ ]
        && config.networking.firewall.allowedUDPPortRanges == [ ]
        && config.networking.firewall.trustedInterfaces == [ "lo" ]
        && config.networking.firewall.interfaces.tailscale0.allowedTCPPorts == [ 443 ]
        && config.networking.firewall.interfaces.tailscale0.allowedUDPPorts == [ ];
      message = "remote-community may expose SSH and Tailscale transport only; Rust, ADB, and emulator listeners must remain loopback-only.";
    }
  ];
}
