{ config, ... }:
{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;   # keys only
      PermitRootLogin = "no";
      X11Forwarding = false;
      # Harden ciphers — modern clients handle these fine
      KexAlgorithms = [
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
      ];
    };
    # Keep the port standard unless you have a reason to change it;
    ports = [ 22 ];
  };

  # Open the firewall for SSH
  networking.firewall.allowedTCPPorts = [ 22 ];
}
