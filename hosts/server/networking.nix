{ config, systemSettings, ... }:
{
  networking = {
    hostName = systemSettings.hostname;
    # networkmanager is fine for desktops; for servers systemd-networkd
    # is more appropriate — deterministic, no GUI dependencies
    useNetworkd = true;
    # If you want a static IP, override this per-host in hosts/<name>/default.nix
    # rather than here so the common module stays flexible
  };

  # systemd-networkd waits for the network before proceeding but doesn't
  # block boot forever if a link is slow to come up
  systemd.network.wait-online.anyInterface = true;

  # DNS — use your router or a local resolver; fallback to Cloudflare
  networking.nameservers = [ "10.0.0.1" "1.1.1.1" ];
}
