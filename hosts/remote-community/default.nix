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

  # The authenticated AVD has been migrated and verified to boot, but the
  # emulator remains a manual-start lab service until final UI authentication
  # verification and resource observation are complete.
  services.remote-community-android-emulator = {
    enable = true;
    enableAtBoot = false;
  };

  sops.secrets.remote-community-policy = {
    key = "policy";
    mode = "0400";
  };

  # Stage 2 enables observe-only ingestion on loopback. A private TLS proxy is a
  # separate gate before phone access; never expose the plaintext port directly.
  services.remote-community = {
    enable = true;
    listenAddress = "127.0.0.1";
    policyCredentialFile = config.sops.secrets.remote-community-policy.path;
    openFirewall = false;
  };

  assertions = [
    {
      assertion =
        config.services.remote-community.enable
        && config.services.remote-community.listenAddress == "127.0.0.1"
        && !config.services.remote-community.openFirewall;
      message = "remote-community stage 2 must remain observe-only on loopback behind a future private TLS proxy.";
    }
    {
      assertion = !config.services.remote-community-android-emulator.enableAtBoot;
      message = "remote-community Android emulator must remain manual-start pending final UI authentication and resource verification.";
    }
    {
      assertion =
        config.networking.firewall.allowedTCPPorts == [ 22 ]
        && config.networking.firewall.allowedUDPPorts == [ ]
        && config.networking.firewall.allowedTCPPortRanges == [ ]
        && config.networking.firewall.allowedUDPPortRanges == [ ]
        && config.networking.firewall.trustedInterfaces == [ "lo" ];
      message = "remote-community stage 2 exposes only inherited SSH; Rust, ADB, and emulator listeners must remain loopback-only.";
    }
  ];
}
