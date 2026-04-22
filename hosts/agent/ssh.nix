# Agent VM SSH Configuration - Hardened for Secure Access
{ config, lib, pkgs, ... }:

{
  # SSH service configuration
  services.openssh = {
    enable = true;

    settings = {
      # Security hardening
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      PubkeyAuthentication = true;
      AuthenticationMethods = "publickey";

      # Rate limiting and timeouts
      MaxAuthTries = 3;
      LoginGraceTime = 30;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;

      # Protocol settings
      Protocol = 2;
      AllowUsers = [ "agent" ];

      # Disable unnecessary features
      PermitEmptyPasswords = false;
      PermitUserEnvironment = false;
      AllowAgentForwarding = true;  # Needed for git operations
      AllowTcpForwarding = false;
      X11Forwarding = false;
      PrintMotd = false;

      # Logging
      LogLevel = "VERBOSE";
    };

    # Automatically open firewall
    openFirewall = true;

    # Host keys - regenerate for security
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  # Agent user SSH configuration
  users.users.agent = {
    openssh.authorizedKeys.keys = [
      # TODO: Replace with actual SSH public key for agent access
      # This should be a dedicated key pair for the agent VM
      # Generate with: ssh-keygen -t ed25519 -C "agent-vm-access" -f ~/.ssh/agent_vm_ed25519
      # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... agent-vm-access"
    ];
  };

  # SSH client configuration for agent user
  environment.etc."ssh/ssh_config".text = ''
    # Global SSH client config for agent VM
    Host *
      ServerAliveInterval 60
      ServerAliveCountMax 3
      HashKnownHosts yes
      VerifyHostKeyDNS yes
      StrictHostKeyChecking ask
      UserKnownHostsFile ~/.ssh/known_hosts

    # GitHub configuration for git operations
    Host github.com
      HostName github.com
      User git
      Port 22
      PreferredAuthentications publickey
      IdentitiesOnly yes
      AddKeysToAgent yes
  '';

  # Fail2ban for SSH protection
  services.fail2ban = {
    enable = true;
    bantime = "10m";
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h";
    };

    jails = {
      sshd = {
        settings = {
          enabled = true;
          port = "ssh";
          filter = "sshd";
          logpath = "/var/log/auth.log";
          maxretry = 3;
          findtime = "10m";
        };
      };
    };
  };

  # SSH key management script
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "setup-agent-ssh-keys" ''
      #!/bin/bash
      # Script to set up SSH keys for agent VM access

      KEY_DIR="/home/agent/.ssh"
      PRIVATE_KEY="$KEY_DIR/agent_vm_ed25519"
      PUBLIC_KEY="$PRIVATE_KEY.pub"

      if [[ ! -d "$KEY_DIR" ]]; then
        mkdir -p "$KEY_DIR"
        chown agent:agent "$KEY_DIR"
        chmod 700 "$KEY_DIR"
      fi

      # Generate key if it doesn't exist
      if [[ ! -f "$PRIVATE_KEY" ]]; then
        echo "Generating SSH key pair for agent VM..."
        ssh-keygen -t ed25519 -C "agent-vm-internal" -f "$PRIVATE_KEY" -N ""
        chown agent:agent "$PRIVATE_KEY" "$PUBLIC_KEY"
        chmod 600 "$PRIVATE_KEY"
        chmod 644 "$PUBLIC_KEY"
        echo "SSH key generated: $PUBLIC_KEY"
        echo "Public key content:"
        cat "$PUBLIC_KEY"
      else
        echo "SSH key already exists: $PRIVATE_KEY"
      fi

      # Set up SSH config for agent user
      cat > "$KEY_DIR/config" << 'EOF'
      Host *
        AddKeysToAgent yes
        IdentitiesOnly yes

      Host github.com
        HostName github.com
        User git
        IdentityFile ~/.ssh/agent_vm_ed25519
        PreferredAuthentications publickey
      EOF

      chown agent:agent "$KEY_DIR/config"
      chmod 600 "$KEY_DIR/config"

      echo "SSH configuration complete!"
    '')
  ];

  # Security monitoring
  systemd.services.ssh-monitor = {
    description = "Monitor SSH access attempts";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = pkgs.writeShellScript "ssh-monitor" ''
        # Log SSH access attempts for monitoring
        journalctl -u sshd -f --since "1 minute ago" | while read line; do
          if echo "$line" | grep -q "Failed\|Invalid\|Accepted"; then
            echo "$(date): $line" >> /var/log/ssh-monitor.log
          fi
        done
      '';
    };
  };

  systemd.timers.ssh-monitor = {
    description = "Run SSH monitoring";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/1";  # Every minute
      Unit = "ssh-monitor.service";
    };
  };
}