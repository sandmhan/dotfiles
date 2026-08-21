# Remote Community VM Host Configuration
# Observe-only remote-community Android lab on Proxmox VM111.
{
  config,
  ...
}:
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

  services = {
    # The authenticated AVD has been migrated and verified to boot, but the
    # emulator remains manual-start pending final UI and resource verification.
    remote-community-android-emulator = {
      enable = true;
      enableAtBoot = false;
    };

    # Observe-only ingestion stays on loopback. Tailscale Serve is the only
    # planned phone-facing proxy; never expose the plaintext port directly.
    remote-community = {
      enable = true;
      listenAddress = "127.0.0.1";
      policyCredentialFile = config.sops.secrets.remote-community-policy.path;
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

  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  assertions = [
    {
      assertion =
        config.services.remote-community.enable
        && config.services.remote-community.listenAddress == "127.0.0.1"
        && !config.services.remote-community.openFirewall;
      message = "remote-community must remain observe-only on loopback behind Tailscale Serve.";
    }
    {
      assertion = !config.services.remote-community-android-emulator.enableAtBoot;
      message = "remote-community Android emulator must remain manual-start pending final UI authentication and resource verification.";
    }
    {
      assertion =
        config.networking.firewall.allowedTCPPorts == [ 22 ]
        && config.networking.firewall.allowedUDPPorts == [ config.services.tailscale.port ]
        && config.networking.firewall.allowedTCPPortRanges == [ ]
        && config.networking.firewall.allowedUDPPortRanges == [ ]
        &&
          config.networking.firewall.trustedInterfaces == [
            "tailscale0"
            "lo"
          ];
      message = "remote-community may expose SSH and Tailscale transport only; Rust, ADB, and emulator listeners must remain loopback-only.";
    }
  ];
}
