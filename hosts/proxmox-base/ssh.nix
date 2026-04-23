# Minimal SSH configuration for Proxmox VMs
{ config, lib, ... }:
{
  services.openssh = {
    enable = true;
    ports = [ 22 ];

    settings = {
      # Secure defaults for homelab
      PasswordAuthentication = false;
      PermitRootLogin = "no";

      # Allow public key authentication
      PubkeyAuthentication = true;

      # Modern key exchange
      KexAlgorithms = [
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group16-sha512"
        "diffie-hellman-group18-sha512"
      ];
    };
  };

  # Open SSH port in firewall (handled by main config)
  # networking.firewall.allowedTCPPorts = [ 22 ];
}