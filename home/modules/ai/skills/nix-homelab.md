---
name: nix-homelab
description: "Use when working with Proxmox VMs, homelab services, OCI containers, or self-hosted infrastructure using NixOS"
---

# Nix Homelab

## Proxmox/VM Patterns

### Base Proxmox VM Configuration

```nix
# hosts/server/default.nix - Base Proxmox VM config
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./ssh.nix
  ];

  # QEMU guest agent for Proxmox integration
  services.qemuGuest.enable = true;

  # Disable unnecessary services for VM
  boot.loader.grub.device = "/dev/vda";

  system.stateVersion = "24.11";
}
```

### VMA Image Configuration

```nix
# hosts/server/image.nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-image.nix")
  ];

  proxmox = {
    qemuConf = {
      cores = 2;
      memory = 2048;
      bios = "ovmf";
      net0 = "virtio=00:00:00:00:00:00,bridge=vmbr0,firewall=1";
    };
  };
}
```

### Service Module Pattern

Template for creating homelab services with both OCI containers and native NixOS services:

```nix
# systemModules/myservice.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.myService;
in
{
  options.services.myService = {
    enable = lib.mkEnableOption "My homelab service";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port to listen on";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/myservice";
      description = "Data directory";
    };
  };

  config = lib.mkIf cfg.enable {
    # OCI container example
    virtualisation.oci-containers.containers.myservice = {
      image = "myservice:latest";
      ports = [ "${toString cfg.port}:8080" ];
      volumes = [ "${cfg.dataDir}:/data" ];
    };

    # Or native NixOS service
    systemd.services.myservice = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.myservice}/bin/myservice";
        StateDirectory = "myservice";
      };
    };

    # Firewall
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
```

## Deployment Workflow

### Building and Deploying VMs

1. **Build VMA image**:
   ```bash
   nixos-rebuild build-image --image-variant proxmox --flake .#initialProxmoxVMA
   ```

2. **Transfer to Proxmox host**:
   ```bash
   # Transfer .vma.zst file to /var/lib/vz/dump/ on Proxmox host
   ```

3. **Restore VM**:
   ```bash
   qmrestore /var/lib/vz/dump/<file>.vma.zst <VM_ID> --storage local-zfs --force
   ```

4. **Adjust resources**:
   ```bash
   qm set <vmid> --cores <n> --memory <mb>
   ```

5. **Deploy configuration**:
   ```bash
   nixos-rebuild switch --target-host sandmhan@<ip> --flake .#<config> --sudo
   ```

### Remote Deployment Commands

```bash
# Deploy to existing VM
nixos-rebuild switch --target-host user@host --flake .#<hostname> --use-remote-sudo

# Build without deploying (test)
nixos-rebuild build --flake .#<hostname>

# Test deployment (reverts on reboot)
nixos-rebuild test --target-host user@host --flake .#<hostname> --use-remote-sudo
```

## Service Patterns

### Container Services

Use OCI containers when native NixOS packages are unavailable:

```nix
virtualisation.oci-containers = {
  backend = "docker";  # or "podman"
  containers = {
    myapp = {
      image = "myapp:latest";
      ports = [ "8080:8080" ];
      volumes = [ "/var/lib/myapp:/data" ];
      environment = {
        ENV_VAR = "value";
      };
    };
  };
};
```

### Native NixOS Services

Prefer native NixOS services when available:

```nix
services.nginx = {
  enable = true;
  virtualHosts."example.com" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:8080";
    };
  };
};
```

## Networking and Security

### Firewall Configuration

```nix
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 22 80 443 ];
  allowedUDPPorts = [ ];

  # Allow specific interfaces
  interfaces.enp1s0.allowedTCPPorts = [ 8080 ];
};
```

### SSH Configuration

```nix
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "no";
  };
  openFirewall = true;
};

users.users.myuser = {
  openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3N... user@host"
  ];
};
```

## Monitoring and Maintenance

### Automatic Updates

```nix
# Automatic garbage collection
nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 30d";
  persistent = true;
};

# Automatic system updates (use with caution)
system.autoUpgrade = {
  enable = false;  # Enable only for stable setups
  flake = inputs.self.outPath;
  flags = [
    "--update-input" "nixpkgs"
    "--commit-lock-file"
  ];
  dates = "04:00";
  randomizedDelaySec = "45min";
};
```

### Health Checks

```nix
# Simple service monitoring
systemd.services.myservice-health = {
  description = "Health check for myservice";
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${pkgs.curl}/bin/curl -f http://localhost:8080/health";
  };
};

systemd.timers.myservice-health = {
  wantedBy = [ "timers.target" ];
  partOf = [ "myservice-health.service" ];
  timerConfig = {
    OnCalendar = "*:0/5";  # Every 5 minutes
    Unit = "myservice-health.service";
  };
};
```